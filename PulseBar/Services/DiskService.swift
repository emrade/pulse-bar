//
//  DiskService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

final class DiskService: DiskServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<DiskMetrics, Never>(DiskMetrics())
    
    var metricsPublisher: AnyPublisher<DiskMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    func updateMetrics() async {
        // TODO: Implement real disk monitoring
        // Placeholder implementation
        let bootVolume = VolumeInfo(
            name: "Macintosh HD",
            mountPoint: "/",
            totalBytes: 512 * 1024 * 1024 * 1024, // 512GB
            freeBytes: 200 * 1024 * 1024 * 1024,  // 200GB free
            isBootVolume: true,
            isExternal: false
        )
        
        let mockMetrics = DiskMetrics(
            volumes: [bootVolume],
            isLoading: false,
            error: nil
        )
        
        await MainActor.run {
            metricsSubject.send(mockMetrics)
        }
    }
}