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
        
        // Try to get SMART data using IOKit
        return fetchSMARTDataForInternalDrive(volume)
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
        
        // For the boot volume, we typically want to access the main internal drive
        // This is a simplified approach - in practice, you might need to enumerate
        // all storage devices and match them to volumes
        return "disk0" // Main internal drive on most Macs
    }
    
    private func getIOMedia(for bsdName: String) -> io_object_t? {
        let matching = IOBSDNameMatching(kIOMainPortDefault, 0, bsdName)
        guard matching != nil else { return nil }
        
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard result == KERN_SUCCESS else { return nil }
        
        defer { IOObjectRelease(iterator) }
        
        var media: io_object_t = 0
        while true {
            let next = IOIteratorNext(iterator)
            if next == 0 { break }
            
            // Check if this is an IOMedia object
            var classStr = [CChar](repeating: 0, count: 128)
            let kr = IOObjectGetClass(next, &classStr)
            if kr == KERN_SUCCESS, String(cString: classStr) == "IOMedia" {
                media = next
                break
            }
            
            IOObjectRelease(next)
        }
        
        return media != 0 ? media : nil
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
            
            // Check if this is an IOBlockStorageDriver object
            var classStr = [CChar](repeating: 0, count: 128)
            let kr = IOObjectGetClass(next, &classStr)
            if kr == KERN_SUCCESS, String(cString: classStr) == "IOBlockStorageDriver" {
                driver = next
                break
            }
            
            IOObjectRelease(next)
        }
        
        return driver != 0 ? driver : nil
    }
    
    private func getSMARTDictionary(from driver: io_object_t) -> [String: Any]? {
        // Try to get SMART data from the device
        // This is a simplified implementation
        var smartData: [String: Any] = [:]
        
        // Try to get SMART properties
        if let properties = getRegistryProperties(from: driver, withKey: "SMART Capabilities") {
            smartData["Capabilities"] = properties
        }
        
        if let properties = getRegistryProperties(from: driver, withKey: "SMART Data") {
            smartData["Data"] = properties
        }
        
        if let properties = getRegistryProperties(from: driver, withKey: "SMART Error Log") {
            smartData["ErrorLog"] = properties
        }
        
        return smartData.isEmpty ? nil : smartData
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
        // This is a simplified implementation
        if let capabilities = smartData["Capabilities"] as? [String: Any],
           let healthStatus = capabilities["Health Status"] as? String {
            return healthStatus
        }
        
        // Default to "Unknown" if we can't determine health status
        return "Unknown"
    }
    
    private func getTemperature(from smartData: [String: Any]) -> Double? {
        // Try to extract temperature from SMART data
        // This is a simplified implementation
        if let data = smartData["Data"] as? [String: Any],
           let temperature = data["Temperature"] as? Double {
            return temperature
        }
        
        // Default to nil if we can't get temperature
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