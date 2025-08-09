//
//  MemoryService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

final class MemoryService: MemoryServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<MemoryMetrics, Never>(MemoryMetrics())
    
    var metricsPublisher: AnyPublisher<MemoryMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    func updateMetrics() async {
        // TODO: Implement real memory monitoring
        // Placeholder implementation
        let mockMetrics = MemoryMetrics(
            totalBytes: 16 * 1024 * 1024 * 1024, // 16GB
            usedBytes: 8 * 1024 * 1024 * 1024,   // 8GB
            cachedBytes: 2 * 1024 * 1024 * 1024, // 2GB
            freeBytes: 6 * 1024 * 1024 * 1024,   // 6GB
            isLoading: false,
            error: nil
        )
        
        await MainActor.run {
            metricsSubject.send(mockMetrics)
        }
    }
}