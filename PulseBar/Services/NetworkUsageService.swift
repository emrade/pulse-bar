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
import os

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
    private let logger = PulseBarLogger.shared
    
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
            logger.logNetworkInfo("New day detected. Last update: \(lastUpdateDate), Today: \(today)")
            logger.logNetworkInfo("Resetting daily usage from \(dailyDownloaded) bytes down, \(dailyUploaded) bytes up")
            
            dailyDownloaded = 0
            dailyUploaded = 0
            userDefaults.set(today, forKey: lastUpdateDateKey)
            userDefaults.set(dailyDownloaded, forKey: dailyDownloadedKey)
            userDefaults.set(dailyUploaded, forKey: dailyUploadedKey)
            
            // Reset system baseline to current values to prevent carrying over yesterday's data
            userDefaults.set(currentSystemUsage.bytesIn, forKey: lastSystemBytesInKey)
            userDefaults.set(currentSystemUsage.bytesOut, forKey: lastSystemBytesOutKey)
            
            logger.logNetworkInfo("Daily usage reset completed")
            
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
        logger.logNetworkInfo("Starting network interface enumeration, primary interface: \(primaryInterface ?? "none")")

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        
        guard getifaddrs(&ifaddr) == 0 else {
            logger.logNetworkError("Failed to enumerate network interfaces - getifaddrs returned error")
            logger.logNetworkInterfaceAccess(interfaceName: nil, success: false, bytesIn: nil, bytesOut: nil)
            return (0, 0)
        }
        
        defer {
            freeifaddrs(ifaddr)
        }
        
        var processedInterfaces: Set<String> = []
        var ptr = ifaddr
        
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee,
                  let interfaceName = interface.ifa_name else {
                logger.logNetworkWarning("Encountered null interface during enumeration")
                continue
            }
            
            let name = String(cString: interfaceName)
            
            // Validate interface name to prevent buffer overflow attacks
            guard isValidInterfaceName(name) else {
                logger.logSecurityWarning("Invalid interface name detected: \(name)")
                continue
            }
            
            // Prevent processing duplicate interfaces
            guard !processedInterfaces.contains(name) else {
                continue
            }
            processedInterfaces.insert(name)
            
            guard let addr = interface.ifa_addr?.pointee else {
                continue
            }
            
            if addr.sa_family == UInt8(AF_LINK) {
                if primaryInterface == nil || name == primaryInterface {
                    if let data = interface.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self)
                        let interfaceBytesIn = UInt64(networkData.pointee.ifi_ibytes)
                        let interfaceBytesOut = UInt64(networkData.pointee.ifi_obytes)
                        
                        // Bounds checking to prevent integer overflow
                        guard validateNetworkBytes(interfaceBytesIn, interfaceBytesOut) else {
                            logger.logSecurityWarning("Network bytes validation failed for interface \(name): in=\(interfaceBytesIn), out=\(interfaceBytesOut)")
                            continue
                        }
                        
                        // Safe addition with overflow protection
                        let (newBytesIn, inOverflow) = bytesIn.addingReportingOverflow(interfaceBytesIn)
                        let (newBytesOut, outOverflow) = bytesOut.addingReportingOverflow(interfaceBytesOut)
                        
                        if inOverflow || outOverflow {
                            logger.logSecurityError("Integer overflow detected when adding network bytes for interface \(name)")
                            continue
                        }
                        
                        bytesIn = newBytesIn
                        bytesOut = newBytesOut
                        
                        logger.logNetworkInfo("Processed interface \(name): +\(interfaceBytesIn) bytes in, +\(interfaceBytesOut) bytes out")
                    }
                }
            }
        }
        
        logger.logNetworkInterfaceAccess(interfaceName: primaryInterface, success: true, bytesIn: bytesIn, bytesOut: bytesOut)
        logger.logNetworkInfo("Network enumeration completed. Total: \(bytesIn) bytes in, \(bytesOut) bytes out")
        
        return (bytesIn, bytesOut)
    }

    private func getPrimaryNetworkInterface() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "getPrimaryInterface" as CFString, nil, nil) else {
            logger.logNetworkError("Failed to create SCDynamicStore for primary interface detection")
            return nil
        }

        guard let globalState = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any] else {
            logger.logNetworkWarning("Failed to retrieve network global state - no primary interface available")
            return nil
        }

        guard let primaryInterface = globalState["PrimaryInterface"] as? String else {
            logger.logNetworkWarning("Primary interface not found in global state")
            return nil
        }
        
        // Validate the primary interface name
        guard isValidInterfaceName(primaryInterface) else {
            logger.logSecurityError("Invalid primary interface name: \(primaryInterface)")
            return nil
        }
        
        logger.logNetworkInfo("Primary network interface detected: \(primaryInterface)")
        return primaryInterface
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
            logger.logNetworkError("Failed to decode hourly usage history", error: error)
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
            logger.logNetworkError("Failed to encode hourly usage history", error: error)
        }
    }
    
    // MARK: - Automatic Midnight Reset
    private func setupMidnightResetTimer() {
        // Calculate time until next midnight
        let calendar = Calendar.current
        let now = Date()
        
        // Get next midnight
        guard let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) else {
            logger.logNetworkError("Failed to calculate next midnight for auto-reset timer")
            return
        }
        
        let timeUntilMidnight = nextMidnight.timeIntervalSince(now)
        
        logger.logNetworkInfo("Next automatic reset in \(Int(timeUntilMidnight)) seconds (\(nextMidnight))")
        
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
        logger.logNetworkInfo("Performing automatic midnight reset")
        
        // Check if auto-reset is enabled in settings
        if SettingsAccessor.getCurrentSettings().autoResetDailyData {
            // Reset the daily usage
            await resetDailyUsage()
        } else {
            logger.logNetworkInfo("Auto-reset disabled in settings")
        }
        
        // Schedule the next midnight reset (24 hours from now)
        setupMidnightResetTimer()
    }
    
    // MARK: - Security Validation Methods
    
    /// Validates network interface names to prevent injection attacks
    private func isValidInterfaceName(_ name: String) -> Bool {
        // Interface names should be reasonable length and contain only safe characters
        guard name.count <= 16,  // Standard max interface name length
              !name.isEmpty,
              name.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }) else {
            return false
        }
        
        // Reject interface names that could be used for path traversal or injection
        let dangerousPatterns = ["..", "/", "\\", ";", "&", "|", "`", "$", "(", ")"]
        for pattern in dangerousPatterns {
            if name.contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    /// Validates network byte values to prevent integer overflow and unrealistic values
    private func validateNetworkBytes(_ bytesIn: UInt64, _ bytesOut: UInt64) -> Bool {
        // Check for unrealistic byte counts that might indicate corrupted data or attack
        let maxReasonableBytes: UInt64 = 1_000_000_000_000_000 // 1 PB - extremely generous upper bound
        
        guard bytesIn <= maxReasonableBytes,
              bytesOut <= maxReasonableBytes else {
            logger.logSecurityError("Network bytes exceed reasonable bounds: in=\(bytesIn), out=\(bytesOut)")
            return false
        }
        
        return true
    }
}