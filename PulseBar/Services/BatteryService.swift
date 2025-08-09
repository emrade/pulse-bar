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
            return parsePMSetOutput(output)
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
    
    private func parsePMSetOutput(_ output: String) -> BatteryMetrics? {
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
                        
                        return BatteryMetrics(
                            percentage: percentage,
                            isCharging: isCharging,
                            timeRemaining: timeRemaining,
                            health: "Good",
                            cycleCount: nil,
                            isLoading: false,
                            error: nil
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
}