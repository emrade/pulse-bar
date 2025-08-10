//
//  NetworkUsageService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation
import Combine
import Darwin

protocol NetworkUsageServiceProtocol {
    var metricsPublisher: AnyPublisher<NetworkUsageMetrics, Never> { get }
    func updateMetrics() async
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
        
        let metrics = NetworkUsageMetrics(downloaded: dailyDownloaded, uploaded: dailyUploaded, isLoading: false, error: nil)
        await MainActor.run {
            metricsSubject.send(metrics)
        }
    }
    
    private func getNetworkUsage() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        
        guard getifaddrs(&ifaddr) == 0 else {
            return (0, 0)
        }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let addr = ptr?.pointee.ifa_addr.pointee
            
            if addr?.sa_family == UInt8(AF_LINK) {
                if let data = ptr?.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    bytesIn += UInt64(networkData.pointee.ifi_ibytes)
                    bytesOut += UInt64(networkData.pointee.ifi_obytes)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return (bytesIn, bytesOut)
    }
}