//
//  BatteryService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

final class BatteryService: BatteryServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<BatteryMetrics?, Never>(nil)
    
    var metricsPublisher: AnyPublisher<BatteryMetrics?, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    func updateMetrics() async {
        // TODO: Implement real battery monitoring using IOKit
        // For now, simulate battery metrics (will be nil on desktop Macs)
        
        // Check if this is a laptop (simplified check)
        let mockMetrics = BatteryMetrics(
            percentage: 85,
            isCharging: false,
            timeRemaining: 4 * 3600, // 4 hours
            health: "Good",
            cycleCount: 42,
            isLoading: false,
            error: nil
        )
        
        await MainActor.run {
            // Only show battery on laptops - for now showing mock data
            metricsSubject.send(mockMetrics)
        }
    }
}