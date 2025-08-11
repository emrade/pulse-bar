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
    
    // Timer for automatic midnight reset
    private var midnightResetTimer: Timer?
    
    init() {
        Task {
            await updateMetrics()
        }
        setupMidnightResetTimer()
    }
    
    deinit {
        midnightResetTimer?.invalidate()
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
            // New day detected, reset daily counters and system baseline
            print("NetworkUsageService: New day detected. Last update: \(lastUpdateDate), Today: \(today)")
            print("NetworkUsageService: Resetting daily usage from \(dailyDownloaded) bytes down, \(dailyUploaded) bytes up")
            
            dailyDownloaded = 0
            dailyUploaded = 0
            userDefaults.set(today, forKey: lastUpdateDateKey)
            userDefaults.set(dailyDownloaded, forKey: dailyDownloadedKey)
            userDefaults.set(dailyUploaded, forKey: dailyUploadedKey)
            
            // Reset system baseline to current values to prevent carrying over yesterday's data
            userDefaults.set(currentSystemUsage.bytesIn, forKey: lastSystemBytesInKey)
            userDefaults.set(currentSystemUsage.bytesOut, forKey: lastSystemBytesOutKey)
            
            print("NetworkUsageService: Daily usage reset completed")
            
            // Update the local variables to reflect the reset baseline
            let resetMetrics = NetworkUsageMetrics(downloaded: 0, uploaded: 0, isLoading: false, error: nil)
            await MainActor.run {
                metricsSubject.send(resetMetrics)
            }
            return
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
    
    // MARK: - Automatic Midnight Reset
    private func setupMidnightResetTimer() {
        // Calculate time until next midnight
        let calendar = Calendar.current
        let now = Date()
        
        // Get next midnight
        guard let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) else {
            print("Failed to calculate next midnight")
            return
        }
        
        let timeUntilMidnight = nextMidnight.timeIntervalSince(now)
        
        print("NetworkUsageService: Next automatic reset in \(Int(timeUntilMidnight)) seconds (\(nextMidnight))")
        
        // Set up timer to fire at midnight
        DispatchQueue.main.async { [weak self] in
            self?.midnightResetTimer = Timer.scheduledTimer(withTimeInterval: timeUntilMidnight, repeats: false) { _ in
                Task { [weak self] in
                    await self?.performAutomaticMidnightReset()
                }
            }
        }
    }
    
    @MainActor
    private func performAutomaticMidnightReset() async {
        print("NetworkUsageService: Performing automatic midnight reset")
        
        // Check if auto-reset is enabled in settings
        let settingsManager = SettingsManager()
        if settingsManager.settings.autoResetDailyData {
            // Reset the daily usage
            await resetDailyUsage()
        } else {
            print("NetworkUsageService: Auto-reset disabled in settings")
        }
        
        // Schedule the next midnight reset (24 hours from now)
        setupMidnightResetTimer()
    }
}