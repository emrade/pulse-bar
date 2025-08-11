//
//  TemperatureService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation

struct TemperatureMetrics {
    let thermalState: ProcessInfo.ThermalState
    let thermalStateDescription: String
    let thermalStateColor: String // For UI color coding
    let estimatedCPUTemperature: Double? // Estimated based on thermal state
    let timestamp: Date
    
    var formattedThermalState: String {
        return thermalStateDescription
    }
    
    var formattedTemperature: String {
        if let temp = estimatedCPUTemperature {
            return "~" + FormatterUtility.shared.formatTemperature(temp)
        }
        return "Unknown"
    }
}

protocol TemperatureServiceProtocol {
    func getCurrentTemperatureMetrics() async -> TemperatureMetrics
}

final class TemperatureService: TemperatureServiceProtocol, @unchecked Sendable {
    
    func getCurrentTemperatureMetrics() async -> TemperatureMetrics {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let metrics = self.fetchTemperatureMetrics()
                continuation.resume(returning: metrics)
            }
        }
    }
    
    private func fetchTemperatureMetrics() -> TemperatureMetrics {
        let thermalState = ProcessInfo.processInfo.thermalState
        let (description, color, estimatedTemp) = interpretThermalState(thermalState)
        
        return TemperatureMetrics(
            thermalState: thermalState,
            thermalStateDescription: description,
            thermalStateColor: color,
            estimatedCPUTemperature: estimatedTemp,
            timestamp: Date()
        )
    }
    
    private func interpretThermalState(_ state: ProcessInfo.ThermalState) -> (description: String, color: String, estimatedTemp: Double?) {
        switch state {
        case .nominal:
            return ("Normal", "green", 45.0) // Typical idle temp
        case .fair:
            return ("Warm", "yellow", 65.0) // Light load temp
        case .serious:
            return ("Hot", "orange", 80.0) // High load temp
        case .critical:
            return ("Critical", "red", 95.0) // Thermal throttling temp
        @unknown default:
            return ("Unknown", "gray", nil)
        }
    }
}