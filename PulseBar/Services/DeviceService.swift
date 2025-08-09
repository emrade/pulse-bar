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
    
    func updateMetrics() async {
        // TODO: Implement real device monitoring using IOKit or system_profiler
        // Placeholder implementation
        let devices = [
            ConnectedDevice(
                name: "External SSD",
                type: .storage,
                vendorID: "0x1234",
                productID: "0x5678",
                mountPoint: "/Volumes/ExternalSSD"
            ),
            ConnectedDevice(
                name: "USB Mouse",
                type: .usb,
                vendorID: "0xabcd",
                productID: "0xefgh",
                mountPoint: nil
            )
        ]
        
        let mockMetrics = DeviceMetrics(
            devices: devices,
            isLoading: false,
            error: nil
        )
        
        await MainActor.run {
            metricsSubject.send(mockMetrics)
        }
    }
}