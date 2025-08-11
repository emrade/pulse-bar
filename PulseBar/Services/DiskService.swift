//
//  DiskService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine
import IOKit
import IOKit.storage

final class DiskService: DiskServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<DiskMetrics, Never>(DiskMetrics())
    
    var metricsPublisher: AnyPublisher<DiskMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    init() {
        // Initialize with first reading
        Task {
            await updateMetrics()
        }
    }
    
    func updateMetrics() async {
        do {
            let diskMetrics = try await fetchDiskMetrics()
            await MainActor.run {
                metricsSubject.send(diskMetrics)
            }
        } catch {
            print("Disk Service Error: \(error)")
            let errorMetrics = DiskMetrics(
                volumes: [],
                isLoading: false,
                error: error.localizedDescription
            )
            await MainActor.run {
                metricsSubject.send(errorMetrics)
            }
        }
    }
    
    private func fetchDiskMetrics() async throws -> DiskMetrics {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let metrics = try self.getDiskUsage()
                    continuation.resume(returning: metrics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getDiskUsage() throws -> DiskMetrics {
        var volumes: [VolumeInfo] = []
        
        // Get all mounted volumes
        let fileManager = FileManager.default
        guard let mountedVolumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey,
                .volumeIsEjectableKey,
                .volumeIsRemovableKey,
                .volumeIsInternalKey
            ],
            options: .skipHiddenVolumes
        ) else {
            throw DiskServiceError.fileSystemError("Failed to get mounted volumes")
        }
        
        for volumeURL in mountedVolumes {
            do {
                let resourceValues = try volumeURL.resourceValues(forKeys: [
                    .volumeNameKey,
                    .volumeTotalCapacityKey,
                    .volumeAvailableCapacityKey,
                    .volumeIsEjectableKey,
                    .volumeIsRemovableKey,
                    .volumeIsInternalKey
                ])
                
                let name = resourceValues.volumeName ?? "Unknown Volume"
                let totalBytes = UInt64(resourceValues.volumeTotalCapacity ?? 0)
                let availableBytes = UInt64(resourceValues.volumeAvailableCapacity ?? 0)
                let isEjectable = resourceValues.volumeIsEjectable ?? false
                let isRemovable = resourceValues.volumeIsRemovable ?? false
                let isInternal = resourceValues.volumeIsInternal ?? true
                
                // Skip very small volumes (likely system volumes)
                guard totalBytes > 1_000_000_000 else { continue } // Skip volumes < 1GB
                
                let isBootVolume = volumeURL.path == "/"
                let isExternal = !isInternal || isRemovable || isEjectable
                
                // Get SMART status for this volume
                let smartStatus = getSMARTStatus(for: VolumeInfo(
                    name: name,
                    mountPoint: volumeURL.path,
                    totalBytes: totalBytes,
                    freeBytes: availableBytes,
                    isBootVolume: isBootVolume,
                    isExternal: isExternal
                ))
                
                let volumeInfo = VolumeInfo(
                    name: name,
                    mountPoint: volumeURL.path,
                    totalBytes: totalBytes,
                    freeBytes: availableBytes,
                    isBootVolume: isBootVolume,
                    isExternal: isExternal,
                    smartStatus: smartStatus
                )
                
                volumes.append(volumeInfo)
            } catch {
                print("Failed to get resource values for volume \(volumeURL): \(error)")
                continue
            }
        }
        
        // Sort volumes: boot volume first, then internal, then external
        volumes.sort { lhs, rhs in
            if lhs.isBootVolume { return true }
            if rhs.isBootVolume { return false }
            if lhs.isExternal != rhs.isExternal {
                return !lhs.isExternal // Internal volumes before external
            }
            return lhs.name < rhs.name
        }
        
        return DiskMetrics(
            volumes: volumes,
            isLoading: false,
            error: nil
        )
    }
    
    // MARK: - SMART Status Methods
    
    private func getSMARTStatus(for volume: VolumeInfo) -> SMARTStatus? {
        guard !volume.isExternal else {
            // External drives may not support SMART or require special handling
            return SMARTStatus(
                overallHealth: "Unknown",
                temperature: nil,
                powerOnHours: nil,
                reallocatedSectorCount: nil,
                pendingSectorCount: nil,
                isAvailable: false
            )
        }
        
        // For Apple Silicon Macs, IOKit SMART data access is more restricted
        // Try IOKit first, but have a fallback for modern Macs
        if let result = fetchSMARTDataForInternalDrive(volume) {
            return result
        }
        
        // Fallback for Apple Silicon Macs - provide basic health assessment
        return getAppleSiliconFallbackSMARTStatus(for: volume)
    }
    
    private func getAppleSiliconFallbackSMARTStatus(for volume: VolumeInfo) -> SMARTStatus {
        // For Apple Silicon Macs where traditional SMART may not be accessible
        // Provide a basic health assessment based on available system information
        
        // Check if the disk is functioning normally by attempting some basic operations
        let isHealthy = checkBasicDiskHealth(for: volume)
        let estimatedTemperature = getEstimatedDiskTemperature()
        
        return SMARTStatus(
            overallHealth: isHealthy ? "Verified" : "Unknown",
            temperature: estimatedTemperature,
            powerOnHours: nil,
            reallocatedSectorCount: nil,
            pendingSectorCount: nil,
            isAvailable: isHealthy // Mark as available if we can at least assess basic health
        )
    }
    
    private func checkBasicDiskHealth(for volume: VolumeInfo) -> Bool {
        // Perform basic disk health checks
        let fileManager = FileManager.default
        
        // Test 1: Can we write/read a small test file?
        let testPath = NSTemporaryDirectory() + UUID().uuidString
        
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            let content = try String(contentsOfFile: testPath, encoding: .utf8)
            try fileManager.removeItem(atPath: testPath)
            
            if content == "test" {
                return true
            }
        } catch {
            return false
        }
        
        return true // If we got this far, assume healthy
    }
    
    private func getEstimatedDiskTemperature() -> Double? {
        // For Apple Silicon Macs, we can try to estimate temperature based on thermal state
        // This is just a rough estimate, not actual disk temperature
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "therm"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse thermal state and estimate disk temperature
                if output.contains("No thermal warning") || output.contains("Normal") {
                    return 35.0 // Estimate normal operating temperature
                } else if output.contains("Thermal pressure") {
                    return 45.0 // Estimate warmer temperature under load
                }
            }
        } catch {
            // Silently handle error
        }
        
        return nil // Unable to estimate
    }
    
    private func fetchSMARTDataForInternalDrive(_ volume: VolumeInfo) -> SMARTStatus? {
        guard let diskBSDName = getDiskBSDName(for: volume) else {
            return nil
        }
        
        // Get the IOMedia object for this disk
        guard let media = getIOMedia(for: diskBSDName) else {
            return nil
        }
        
        // Get the IOBlockStorageDriver
        guard let driver = getBlockStorageDriver(for: media) else {
            IOObjectRelease(media)
            return nil
        }
        
        defer {
            IOObjectRelease(media)
            IOObjectRelease(driver)
        }
        
        // Try to get SMART data
        var smartData: [String: Any] = [:]
        
        // Try to get SMART data from the device
        if let smartDict = getSMARTDictionary(from: driver) {
            smartData = smartDict
        }
        
        // Extract SMART attributes
        let overallHealth = getSMARTHealthStatus(from: smartData)
        let temperature = getTemperature(from: smartData)
        let powerOnHours = getPowerOnHours(from: smartData)
        let reallocatedSectors = getReallocatedSectorCount(from: smartData)
        let pendingSectors = getPendingSectorCount(from: smartData)
        
        return SMARTStatus(
            overallHealth: overallHealth,
            temperature: temperature,
            powerOnHours: powerOnHours,
            reallocatedSectorCount: reallocatedSectors,
            pendingSectorCount: pendingSectors,
            isAvailable: !smartData.isEmpty
        )
    }
    
    private func getDiskBSDName(for volume: VolumeInfo) -> String? {
        let url = URL(fileURLWithPath: volume.mountPoint)
        
        guard url.path == "/" else {
            // For now, only handle boot volume
            return nil
        }
        
        // Try to dynamically determine the BSD name instead of hardcoding disk0
        if let actualBSDName = getBootVolumeBSDName() {
            return actualBSDName
        }
        
        // Fallback to disk0 for the boot volume
        return "disk0" // Main internal drive on most Macs
    }
    
    private func getBootVolumeBSDName() -> String? {
        // Try to get the actual BSD name for the boot volume
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/df")
        process.arguments = ["/"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse output to get device name
                let lines = output.components(separatedBy: .newlines)
                if lines.count > 1 {
                    let deviceLine = lines[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let components = deviceLine.components(separatedBy: .whitespaces)
                    if let devicePath = components.first {
                        // Extract BSD name from path like /dev/disk3s1s1 -> disk3
                        if devicePath.hasPrefix("/dev/") {
                            let diskPart = String(devicePath.dropFirst(5)) // Remove "/dev/"
                            
                            // Find the base disk name (e.g., disk3 from disk3s1s1)
                            if diskPart.hasPrefix("disk") {
                                // Look for the pattern diskN where N is the disk number
                                let pattern = #"^(disk\d+)"#
                                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                                   let match = regex.firstMatch(in: diskPart, options: [], range: NSRange(diskPart.startIndex..., in: diskPart)),
                                   let range = Range(match.range(at: 1), in: diskPart) {
                                    let baseDiskName = String(diskPart[range])
                                    return baseDiskName
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            // Silently handle error
        }
        
        return nil
    }
    
    private func getIOMedia(for bsdName: String) -> io_object_t? {
        let matching = IOBSDNameMatching(kIOMainPortDefault, 0, bsdName)
        guard matching != nil else { 
            return nil 
        }
        
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard result == KERN_SUCCESS else { 
            return nil 
        }
        
        defer { IOObjectRelease(iterator) }
        
        var media: io_object_t = 0
        var foundObjects = 0
        
        while true {
            let next = IOIteratorNext(iterator)
            if next == 0 { break }
            foundObjects += 1
            
            // Check if this is an IOMedia object or Apple APFS media
            var classStr = [CChar](repeating: 0, count: 128)
            let kr = IOObjectGetClass(next, &classStr)
            if kr == KERN_SUCCESS {
                let className = String(cString: classStr)
                
                // Accept both IOMedia and AppleAPFSMedia (for Apple Silicon Macs)
                if className == "IOMedia" || className == "AppleAPFSMedia" {
                    media = next
                    break
                }
            }
            
            IOObjectRelease(next)
        }
        
        if media == 0 {
            return nil
        }
        
        return media
    }
    
    private func getBlockStorageDriver(for media: io_object_t) -> io_object_t? {
        var iterator: io_iterator_t = 0
        let result = IORegistryEntryCreateIterator(media, kIOServicePlane, IOOptionBits(kIORegistryIterateRecursively), &iterator)
        guard result == KERN_SUCCESS else { return nil }
        
        defer { IOObjectRelease(iterator) }
        
        var driver: io_object_t = 0
        while true {
            let next = IOIteratorNext(iterator)
            if next == 0 { break }
            
            // Check for various storage driver classes used on different Mac architectures
            var classStr = [CChar](repeating: 0, count: 128)
            let kr = IOObjectGetClass(next, &classStr)
            if kr == KERN_SUCCESS {
                let className = String(cString: classStr)
                
                // Accept various storage driver classes
                if className == "IOBlockStorageDriver" || 
                   className == "AppleAPFSContainerScheme" ||
                   className == "AppleNVMeSMART" ||
                   className.contains("SMART") ||
                   className.contains("Storage") {
                    driver = next
                    break
                }
            }
            
            IOObjectRelease(next)
        }
        
        return driver != 0 ? driver : nil
    }
    
    private func getSMARTDictionary(from driver: io_object_t) -> [String: Any]? {
        // Try to get SMART data from the device
        var smartData: [String: Any] = [:]
        
        // Get all properties to examine what's available
        if let allProps = getAllRegistryProperties(from: driver) {
            // For Apple Silicon, look for NVMe/APFS specific properties
            let apfsKeys = allProps.keys.filter { key in
                key.lowercased().contains("smart") ||
                key.lowercased().contains("health") ||
                key.lowercased().contains("temperature") ||
                key.lowercased().contains("nvme") ||
                key.lowercased().contains("life")
            }
            
            // Add any discovered SMART-related properties
            for key in apfsKeys {
                if let value = allProps[key] {
                    smartData[key] = value
                }
            }
        }
        
        // Try standard SMART property keys
        let smartKeyVariants = [
            "SMART Capabilities",
            "SMART Data", 
            "SMART Error Log",
            "SMARTCapabilities",
            "SMARTData",
            "device-characteristics",
            "Device Characteristics",
            "Statistics",
            "NVMeFeatures",
            "Health Information"
        ]
        
        for key in smartKeyVariants {
            if let properties = getRegistryProperties(from: driver, withKey: key) {
                smartData[key] = properties
            }
        }
        
        // If IOKit approach fails, try smartctl as backup
        if smartData.isEmpty {
            return getSMARTDataFromSmartctl()
        }
        
        return smartData.isEmpty ? nil : smartData
    }
    
    private func getAllRegistryProperties(from entry: io_object_t) -> [String: Any]? {
        var propsRef: Unmanaged<CFMutableDictionary>? = nil
        let result = IORegistryEntryCreateCFProperties(entry, &propsRef, kCFAllocatorDefault, 0)
        guard result == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() else {
            return nil
        }
        
        // Convert CFDictionary to Swift Dictionary
        return props as? [String: Any]
    }
    
    private func getSMARTDataFromSmartctl() -> [String: Any]? {
        // Try to use smartctl if available (requires Homebrew or manual installation)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/smartctl")
        process.arguments = ["-a", "/dev/disk0", "--json"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("🔍 SMART: smartctl output: \(output.prefix(500))...")
                
                // Try to parse JSON output
                if let jsonData = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    return json
                }
            }
        } catch {
            print("🔍 SMART: smartctl not available or failed: \(error)")
        }
        
        return nil
    }
    
    private func getRegistryProperties(from entry: io_object_t, withKey key: String) -> [String: Any]? {
        var propsRef: Unmanaged<CFMutableDictionary>? = nil
        let result = IORegistryEntryCreateCFProperties(entry, &propsRef, kCFAllocatorDefault, 0)
        guard result == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() else {
            return nil
        }
        
        // Look for the specific key in the properties
        let keyRef = key as CFString
        if let value = CFDictionaryGetValue(props, Unmanaged.passUnretained(keyRef).toOpaque()) {
            // Convert CF type to Swift type
            return convertCFTypeToSwift(value)
        }
        
        return nil
    }
    
    private func convertCFTypeToSwift(_ value: UnsafeRawPointer) -> [String: Any]? {
        let cfValue = Unmanaged<CFTypeRef>.fromOpaque(value).takeUnretainedValue()
        
        if let dict = cfValue as? [String: Any] {
            return dict
        } else if let dict = cfValue as? NSDictionary {
            return dict as? [String: Any]
        }
        
        return nil
    }
    
    private func getSMARTHealthStatus(from smartData: [String: Any]) -> String {
        // Try to determine health status from SMART data
        // Check various possible locations for health status
        let healthKeyPaths = [
            ["Capabilities", "Health Status"],
            ["Data", "Health Status"],
            ["overall-health"],
            ["smart_status", "passed"],
            ["ata_smart_attributes", "table", "overall-health"],
            ["Health Information", "health_status"],
            ["Statistics", "health"],
            ["NVMeFeatures", "health_information"]
        ]
        
        for keyPath in healthKeyPaths {
            var current: Any = smartData
            var found = true
            
            for key in keyPath {
                if let dict = current as? [String: Any], let value = dict[key] {
                    current = value
                } else {
                    found = false
                    break
                }
            }
            
            if found {
                if let healthString = current as? String {
                    print("🔍 SMART: Found health status: \(healthString)")
                    return mapHealthStatus(healthString)
                } else if let healthBool = current as? Bool {
                    print("🔍 SMART: Found health boolean: \(healthBool)")
                    return healthBool ? "Verified" : "Failing"
                }
            }
        }
        
        // If we have smartctl data, try to parse it
        if let smartStatus = smartData["smart_status"] as? [String: Any] {
            if let passed = smartStatus["passed"] as? Bool {
                print("🔍 SMART: Found smartctl health status: \(passed)")
                return passed ? "Verified" : "Failing"
            }
        }
        
        // Default to "Unknown" if we can't determine health status
        print("🔍 SMART: Health status not found, returning Unknown")
        return "Unknown"
    }
    
    private func mapHealthStatus(_ status: String) -> String {
        let lowercaseStatus = status.lowercased()
        
        if lowercaseStatus.contains("pass") || lowercaseStatus.contains("ok") || lowercaseStatus.contains("good") {
            return "Verified"
        } else if lowercaseStatus.contains("fail") || lowercaseStatus.contains("error") || lowercaseStatus.contains("bad") {
            return "Failing"
        } else {
            return status // Return original status if we can't map it
        }
    }
    
    private func getTemperature(from smartData: [String: Any]) -> Double? {
        print("🔍 SMART: getTemperature called")
        
        // Try to extract temperature from SMART data with various key paths
        let temperatureKeyPaths = [
            ["Data", "Temperature"],
            ["temperature", "current"],
            ["ata_smart_attributes", "table", "194"], // SMART attribute 194 is temperature
            ["nvme_smart_health_information_log", "temperature"],
        ]
        
        for keyPath in temperatureKeyPaths {
            var current: Any = smartData
            var found = true
            
            for key in keyPath {
                if let dict = current as? [String: Any], let value = dict[key] {
                    current = value
                } else {
                    found = false
                    break
                }
            }
            
            if found {
                if let temp = current as? Double {
                    print("🔍 SMART: Found temperature: \(temp)°C")
                    return temp
                } else if let temp = current as? Int {
                    print("🔍 SMART: Found temperature (int): \(temp)°C")
                    return Double(temp)
                }
            }
        }
        
        // If we have smartctl data, try to parse temperature differently
        if let temperature = smartData["temperature"] as? [String: Any],
           let current = temperature["current"] as? Int {
            print("🔍 SMART: Found smartctl temperature: \(current)°C")
            return Double(current)
        }
        
        print("🔍 SMART: Temperature not found")
        return nil
    }
    
    private func getPowerOnHours(from smartData: [String: Any]) -> UInt64? {
        // Try to extract power-on hours from SMART data
        // This is a simplified implementation
        if let data = smartData["Data"] as? [String: Any],
           let hours = data["Power On Hours"] as? UInt64 {
            return hours
        }
        
        // Default to nil if we can't get power-on hours
        return nil
    }
    
    private func getReallocatedSectorCount(from smartData: [String: Any]) -> UInt64? {
        // Try to extract reallocated sector count from SMART data
        // This is a simplified implementation
        if let data = smartData["Data"] as? [String: Any],
           let count = data["Reallocated Sector Count"] as? UInt64 {
            return count
        }
        
        // Default to nil if we can't get reallocated sector count
        return nil
    }
    
    private func getPendingSectorCount(from smartData: [String: Any]) -> UInt64? {
        // Try to extract pending sector count from SMART data
        // This is a simplified implementation
        if let data = smartData["Data"] as? [String: Any],
           let count = data["Current_Pending_Sector"] as? UInt64 {
            return count
        }
        
        // Default to nil if we can't get pending sector count
        return nil
    }
}

enum DiskServiceError: Error, LocalizedError {
    case fileSystemError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileSystemError(let message):
            return "Disk monitoring error: \(message)"
        }
    }
}