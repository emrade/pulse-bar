//
//  BatteryService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine
import IOKit.ps

final class BatteryService: BatteryServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<BatteryMetrics?, Never>(nil)
    
    var metricsPublisher: AnyPublisher<BatteryMetrics?, Never> {
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
            let batteryMetrics = try await fetchBatteryMetrics()
            await MainActor.run {
                metricsSubject.send(batteryMetrics)
            }
        } catch {
            print("Battery Service Error: \(error)")
            // On desktop Macs or if battery reading fails, return nil (no battery display)
            await MainActor.run {
                metricsSubject.send(nil)
            }
        }
    }
    
    private func fetchBatteryMetrics() async throws -> BatteryMetrics? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    if let metrics = try self.getBatteryInfo() {
                        continuation.resume(returning: metrics)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getBatteryInfo() throws -> BatteryMetrics? {
        // Simple check first - just try to detect if we have any power sources
        let powerSourceInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerSourcesList = IOPSCopyPowerSourcesList(powerSourceInfo).takeRetainedValue() as CFArray
        let powerSources = powerSourcesList as NSArray
        
        // If no power sources, return nil (desktop Mac)
        guard powerSources.count > 0 else {
            return nil
        }
        
        // Look for internal battery
        for i in 0..<powerSources.count {
            let powerSource = powerSources[i] as CFTypeRef
            let description = IOPSGetPowerSourceDescription(powerSourceInfo, powerSource).takeRetainedValue()
            let batteryDict = description as! [String: Any]
            
            // Check if this is an internal battery
            guard let type = batteryDict[kIOPSTypeKey] as? String,
                  type == kIOPSInternalBatteryType else {
                continue
            }
            
            // Extract battery information
            let percentage = batteryDict[kIOPSCurrentCapacityKey] as? Int ?? 0
            let isCharging = (batteryDict[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            let timeRemaining = batteryDict[kIOPSTimeToEmptyKey] as? Int
            
            // Get health information if available
            var health: String? = nil
            if let healthStr = batteryDict[kIOPSBatteryHealthKey] as? String {
                health = healthStr
            }
            
            // Convert time remaining from minutes to seconds
            var timeRemainingSeconds: TimeInterval? = nil
            if let timeMin = timeRemaining, timeMin > 0 && timeMin != Int(kIOPSTimeRemainingUnlimited) {
                timeRemainingSeconds = TimeInterval(timeMin * 60)
            }
            
            // Get cycle count if available (from the debug output, we see "DesignCycleCount")
            let cycleCount = batteryDict["DesignCycleCount"] as? Int
            
            return BatteryMetrics(
                percentage: percentage,
                isCharging: isCharging,
                timeRemaining: timeRemainingSeconds,
                health: health,
                cycleCount: cycleCount,
                isLoading: false,
                error: nil
            )
        }
        
        return nil // No internal battery found
    }
}

enum BatteryServiceError: Error, LocalizedError {
    case noBatteryFound
    case ioError(String)
    
    var errorDescription: String? {
        switch self {
        case .noBatteryFound:
            return "No battery found"
        case .ioError(let message):
            return "Battery monitoring error: \(message)"
        }
    }
}