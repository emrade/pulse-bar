//
//  NetworkUsageService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation
import Combine
import Darwin
import SystemConfiguration

struct NetworkUsagePoint: Codable {
    let timestamp: Date
    let downloaded: Double
    let uploaded: Double
}

protocol NetworkUsageServiceProtocol {
    var metricsPublisher: AnyPublisher<NetworkUsageMetrics, Never> { get }
    func updateMetrics() async
    func resetDailyUsage() async
    func getHourlyUsageHistory() -> [NetworkUsagePoint]
}

final class NetworkUsageService: NetworkUsageServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<NetworkUsageMetrics, Never>(NetworkUsageMetrics())
    
    var metricsPublisher: AnyPublisher<NetworkUsageMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    private let userDefaults = UserDefaults.standard
    private let lastUpdateDateKey = "lastUpdateDate"
    private let lastSystemBytesInKey = "lastSystemBytesIn"
    private let lastSystemBytesOutKey = "lastSystemBytesOut"
    private let dailyDownloadedKey = "dailyDownloaded"
    private let dailyUploadedKey = "dailyUploaded"
    private let hourlyUsageKey = "hourlyUsageHistory"
    
    init() {
        Task {
            await updateMetrics()
        }
    }
    
    func updateMetrics() async {
        let currentSystemUsage = getNetworkUsage()
        let today = Calendar.current.startOfDay(for: Date())
        
        let lastUpdateDate = userDefaults.object(forKey: lastUpdateDateKey) as? Date ?? today
        let lastSystemBytesIn = userDefaults.object(forKey: lastSystemBytesInKey) as? UInt64 ?? 0
        let lastSystemBytesOut = userDefaults.object(forKey: lastSystemBytesOutKey) as? UInt64 ?? 0
        
        var dailyDownloaded = userDefaults.object(forKey: dailyDownloadedKey) as? UInt64 ?? 0
        var dailyUploaded = userDefaults.object(forKey: dailyUploadedKey) as? UInt64 ?? 0
        
        if !Calendar.current.isDate(today, inSameDayAs: lastUpdateDate) {
            // New day, reset daily counters
            dailyDownloaded = 0
            dailyUploaded = 0
            userDefaults.set(today, forKey: lastUpdateDateKey)
        }
        
        if currentSystemUsage.bytesIn >= lastSystemBytesIn {
            dailyDownloaded += currentSystemUsage.bytesIn - lastSystemBytesIn
        }
        
        if currentSystemUsage.bytesOut >= lastSystemBytesOut {
            dailyUploaded += currentSystemUsage.bytesOut - lastSystemBytesOut
        }
        
        userDefaults.set(currentSystemUsage.bytesIn, forKey: lastSystemBytesInKey)
        userDefaults.set(currentSystemUsage.bytesOut, forKey: lastSystemBytesOutKey)
        userDefaults.set(dailyDownloaded, forKey: dailyDownloadedKey)
        userDefaults.set(dailyUploaded, forKey: dailyUploadedKey)
        
        // Update hourly tracking
        updateHourlyUsageHistory(downloaded: dailyDownloaded, uploaded: dailyUploaded)
        
        let metrics = NetworkUsageMetrics(downloaded: dailyDownloaded, uploaded: dailyUploaded, isLoading: false, error: nil)
        await MainActor.run {
            metricsSubject.send(metrics)
        }
    }
    
    func resetDailyUsage() async {
        // Reset daily counters to 0
        userDefaults.set(UInt64(0), forKey: dailyDownloadedKey)
        userDefaults.set(UInt64(0), forKey: dailyUploadedKey)
        
        // Update the last system bytes to current values to prevent double counting
        let currentSystemUsage = getNetworkUsage()
        userDefaults.set(currentSystemUsage.bytesIn, forKey: lastSystemBytesInKey)
        userDefaults.set(currentSystemUsage.bytesOut, forKey: lastSystemBytesOutKey)
        
        // Update the last update date to today
        let today = Calendar.current.startOfDay(for: Date())
        userDefaults.set(today, forKey: lastUpdateDateKey)
        
        // Send updated metrics immediately
        let resetMetrics = NetworkUsageMetrics(downloaded: 0, uploaded: 0, isLoading: false, error: nil)
        await MainActor.run {
            metricsSubject.send(resetMetrics)
        }
    }
    
    private func getNetworkUsage() -> (bytesIn: UInt64, bytesOut: UInt64) {
        let primaryInterface = getPrimaryNetworkInterface()

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        
        guard getifaddrs(&ifaddr) == 0 else {
            return (0, 0)
        }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            let addr = interface?.ifa_addr.pointee
            let name = String(cString: (interface?.ifa_name)!)
            
            if addr?.sa_family == UInt8(AF_LINK) {
                if primaryInterface == nil || name == primaryInterface { // If primary interface is nil, count all interfaces
                    if let data = interface?.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self)
                        bytesIn += UInt64(networkData.pointee.ifi_ibytes)
                        bytesOut += UInt64(networkData.pointee.ifi_obytes)
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return (bytesIn, bytesOut)
    }

    private func getPrimaryNetworkInterface() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "getPrimaryInterface" as CFString, nil, nil) else {
            return nil
        }

        guard let globalState = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any] else {
            return nil
        }

        return globalState["PrimaryInterface"] as? String
    }
    
    func getHourlyUsageHistory() -> [NetworkUsagePoint] {
        guard let data = userDefaults.data(forKey: hourlyUsageKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let hourlyData = try decoder.decode([NetworkUsagePoint].self, from: data)
            
            // Filter to only today's data
            let today = Calendar.current.startOfDay(for: Date())
            return hourlyData.filter { point in
                Calendar.current.isDate(point.timestamp, inSameDayAs: today)
            }
        } catch {
            print("Failed to decode hourly usage history: \(error)")
            return []
        }
    }
    
    private func updateHourlyUsageHistory(downloaded: UInt64, uploaded: UInt64) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let hourStart = calendar.date(bySettingHour: currentHour, minute: 0, second: 0, of: now) ?? now
        
        var hourlyHistory = getHourlyUsageHistory()
        
        // Check if we already have an entry for this hour
        if let existingIndex = hourlyHistory.firstIndex(where: { point in
            calendar.component(.hour, from: point.timestamp) == currentHour &&
            calendar.isDate(point.timestamp, inSameDayAs: now)
        }) {
            // Update existing entry
            hourlyHistory[existingIndex] = NetworkUsagePoint(
                timestamp: hourStart,
                downloaded: Double(downloaded),
                uploaded: Double(uploaded)
            )
        } else {
            // Add new entry
            hourlyHistory.append(NetworkUsagePoint(
                timestamp: hourStart,
                downloaded: Double(downloaded),
                uploaded: Double(uploaded)
            ))
        }
        
        // Keep only today's data and sort by timestamp
        let today = calendar.startOfDay(for: now)
        hourlyHistory = hourlyHistory.filter { point in
            calendar.isDate(point.timestamp, inSameDayAs: today)
        }.sorted { $0.timestamp < $1.timestamp }
        
        // Save updated history
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(hourlyHistory)
            userDefaults.set(data, forKey: hourlyUsageKey)
        } catch {
            print("Failed to encode hourly usage history: \(error)")
        }
    }
}