//
//  DeviceService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

final class DeviceService: DeviceServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<DeviceMetrics, Never>(DeviceMetrics())
    
    var metricsPublisher: AnyPublisher<DeviceMetrics, Never> {
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
            let deviceMetrics = try await fetchDeviceMetrics()
            await MainActor.run {
                metricsSubject.send(deviceMetrics)
            }
        } catch {
            print("Device Service Error: \(error)")
            let errorMetrics = DeviceMetrics(
                devices: [],
                isLoading: false,
                error: error.localizedDescription
            )
            await MainActor.run {
                metricsSubject.send(errorMetrics)
            }
        }
    }
    
    private func fetchDeviceMetrics() async throws -> DeviceMetrics {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let metrics = try self.getConnectedDevices()
                    continuation.resume(returning: metrics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getConnectedDevices() throws -> DeviceMetrics {
        // Use system_profiler to get USB device information
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPUSBDataType", "-json"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Suppress error output
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let usbData = jsonObject["SPUSBDataType"] as? [[String: Any]] else {
            throw DeviceServiceError.parsingError("Failed to parse USB data")
        }
        
        var devices: [ConnectedDevice] = []
        
        // Parse USB devices recursively
        for usbBus in usbData {
            parseUSBDevice(usbBus, devices: &devices)
        }
        
        // Also get mounted volumes (external drives)
        let volumeDevices = getMountedVolumeDevices()
        devices.append(contentsOf: volumeDevices)
        
        // Remove duplicates and filter out uninteresting devices
        devices = devices.filter { device in
            !device.name.contains("Hub") &&
            !device.name.contains("Controller") &&
            !device.name.contains("Bus") &&
            !device.name.isEmpty
        }
        
        return DeviceMetrics(
            devices: Array(Set(devices)),
            isLoading: false,
            error: nil
        )
    }
    
    private func parseUSBDevice(_ deviceData: [String: Any], devices: inout [ConnectedDevice]) {
        // Extract device information
        if let name = deviceData["_name"] as? String {
            let vendorID = deviceData["vendor_id"] as? String
            let productID = deviceData["product_id"] as? String
            
            // Determine device type
            let deviceType: ConnectedDevice.DeviceType
            if name.lowercased().contains("storage") || name.lowercased().contains("disk") {
                deviceType = .storage
            } else if name.lowercased().contains("mouse") || name.lowercased().contains("keyboard") {
                deviceType = .usb
            } else if name.lowercased().contains("display") || name.lowercased().contains("monitor") {
                deviceType = .display
            } else if name.lowercased().contains("thunderbolt") {
                deviceType = .thunderbolt
            } else {
                deviceType = .other(name)
            }
            
            let device = ConnectedDevice(
                name: name,
                type: deviceType,
                vendorID: vendorID,
                productID: productID,
                mountPoint: nil
            )
            
            devices.append(device)
        }
        
        // Recursively parse child devices
        if let items = deviceData["_items"] as? [[String: Any]] {
            for item in items {
                parseUSBDevice(item, devices: &devices)
            }
        }
    }
    
    private func getMountedVolumeDevices() -> [ConnectedDevice] {
        var devices: [ConnectedDevice] = []
        
        let fileManager = FileManager.default
        guard let mountedVolumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeNameKey, .volumeIsEjectableKey],
            options: .skipHiddenVolumes
        ) else {
            return devices
        }
        
        for volumeURL in mountedVolumes {
            do {
                let resourceValues = try volumeURL.resourceValues(forKeys: [
                    .volumeNameKey,
                    .volumeIsEjectableKey
                ])
                
                if let name = resourceValues.volumeName,
                   let isEjectable = resourceValues.volumeIsEjectable,
                   isEjectable && volumeURL.path != "/" {
                    
                    let device = ConnectedDevice(
                        name: name,
                        type: .storage,
                        vendorID: nil,
                        productID: nil,
                        mountPoint: volumeURL.path
                    )
                    
                    devices.append(device)
                }
            } catch {
                continue
            }
        }
        
        return devices
    }
}

// Make ConnectedDevice conform to Hashable for Set operations
extension ConnectedDevice: Hashable {
    static func == (lhs: ConnectedDevice, rhs: ConnectedDevice) -> Bool {
        return lhs.name == rhs.name && 
               lhs.vendorID == rhs.vendorID && 
               lhs.productID == rhs.productID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(vendorID)
        hasher.combine(productID)
    }
}

enum DeviceServiceError: Error, LocalizedError {
    case systemProfilerFailed
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .systemProfilerFailed:
            return "Failed to run system_profiler"
        case .parsingError(let message):
            return "Device parsing error: \(message)"
        }
    }
}