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
        // Use a simpler, safer approach that doesn't crash
        let batteryMetrics = await getBatteryInfoSafe()
        await MainActor.run {
            metricsSubject.send(batteryMetrics)
        }
    }
    
    private func getBatteryInfoSafe() async -> BatteryMetrics? {
        // Use pmset command to get battery info safely
        let pmsetOutput = try? await runPMSetCommand()
        
        // If we can get pmset output and it contains battery info, parse it
        if let output = pmsetOutput, (output.contains("InternalBattery") || output.contains("Battery Power")) {
            return await parsePMSetOutput(output)
        }
        
        return nil // No battery or desktop Mac
    }
    
    private func runPMSetCommand() async throws -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "batt"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
    
    private func parsePMSetOutput(_ output: String) async -> BatteryMetrics? {
        // Parse pmset output for basic battery info
        // Example output formats:
        // "Now drawing from 'AC Power'"
        // "Now drawing from 'Battery Power'"
        // "InternalBattery-0 (id=1234567)  85%; charging; 4:23 remaining present: true"
        // "InternalBattery-0 (id=1234567)  85%; discharging; 4:23 remaining present: true"
        
        let lines = output.components(separatedBy: .newlines)
        var isOnACPower = false
        
        // First check what power source we're using
        for line in lines {
            if line.contains("Now drawing from") {
                isOnACPower = line.contains("'AC Power'")
                break
            }
        }
        
        // Then find battery info
        for line in lines {
            if line.contains("InternalBattery") {
                // Extract percentage
                if let percentMatch = line.range(of: #"\d+%"#, options: .regularExpression) {
                    let percentString = String(line[percentMatch]).replacingOccurrences(of: "%", with: "")
                    if let percentage = Int(percentString) {
                        // Charging logic: must be on AC power AND either explicitly "charging" or at high %
                        let isCharging = isOnACPower && (line.contains("charging") || !line.contains("discharging"))
                        
                        // Try to extract time remaining
                        var timeRemaining: TimeInterval? = nil
                        if let timeMatch = line.range(of: #"\d+:\d+ remaining"#, options: .regularExpression) {
                            let timeString = String(line[timeMatch]).replacingOccurrences(of: " remaining", with: "")
                            let components = timeString.components(separatedBy: ":")
                            if components.count == 2, let hours = Int(components[0]), let minutes = Int(components[1]) {
                                timeRemaining = TimeInterval(hours * 3600 + minutes * 60)
                            }
                        }
                        
                        // Try to get additional battery info from system_profiler
                        let additionalInfo = await getDetailedBatteryInfo()
                        
                        return BatteryMetrics(
                            percentage: percentage,
                            isCharging: isCharging,
                            timeRemaining: timeRemaining,
                            health: additionalInfo.health,
                            cycleCount: additionalInfo.cycleCount,
                            temperature: additionalInfo.temperature,
                            maxCapacity: additionalInfo.maxCapacity,
                            isLoading: false,
                            error: nil
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
    private func getDetailedBatteryInfo() async -> (health: String, cycleCount: Int?, temperature: Double?, maxCapacity: Double?) {
        // Try to get detailed battery info from system_profiler
        do {
            let output = try await runSystemProfilerCommand()
            return parseBatteryProfilerOutput(output)
        } catch {
            // Fallback to reasonable defaults if system_profiler fails
            return ("Normal", nil, nil, nil)
        }
    }
    
    private func runSystemProfilerCommand() async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPPowerDataType"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func parseBatteryProfilerOutput(_ output: String) -> (health: String, cycleCount: Int?, temperature: Double?, maxCapacity: Double?) {
        let lines = output.components(separatedBy: .newlines)
        var health = "Normal"
        var cycleCount: Int? = nil
        let temperature: Double? = getThermalStateTemperature()
        var maxCapacity: Double? = nil
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for cycle count
            if trimmedLine.contains("Cycle Count:") {
                let components = trimmedLine.components(separatedBy: ":")
                if components.count > 1 {
                    let countString = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    cycleCount = Int(countString)
                }
            }
            
            // Look for condition/health
            if trimmedLine.contains("Condition:") {
                let components = trimmedLine.components(separatedBy: ":")
                if components.count > 1 {
                    health = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Look for maximum capacity
            if trimmedLine.contains("Maximum Capacity:") {
                let components = trimmedLine.components(separatedBy: ":")
                if components.count > 1 {
                    let capacityString = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    // Extract percentage from strings like "98%" or "4500 mAh"
                    if let percentMatch = capacityString.range(of: "\\d+", options: .regularExpression) {
                        if let capacity = Double(String(capacityString[percentMatch])) {
                            if capacityString.contains("%") {
                                maxCapacity = capacity
                            }
                        }
                    }
                }
            }
            
            // Alternative health indicators
            if trimmedLine.contains("Health Information:") {
                // Parse health info if available
                continue
            }
        }
        
        // If we got a cycle count, infer health based on typical MacBook battery life
        if let count = cycleCount {
            if count > 1000 {
                health = "Service Battery"
            } else if count > 800 {
                health = "Replace Soon"
            } else if count > 500 {
                health = "Fair"
            } else if count > 200 {
                health = "Good"
            } else {
                health = "Excellent"
            }
        }
        
        return (health, cycleCount, temperature, maxCapacity)
    }
    
    private func getThermalStateTemperature() -> Double? {
        let thermalState = ProcessInfo.processInfo.thermalState
        
        switch thermalState {
        case .nominal:
            return 35.0 // Normal operating temperature
        case .fair:
            return 45.0 // Slightly elevated
        case .serious:
            return 55.0 // Getting warm
        case .critical:
            return 65.0 // Very hot
        @unknown default:
            return nil
        }
    }
}