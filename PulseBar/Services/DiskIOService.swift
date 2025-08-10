//
//  DiskIOService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation

struct DiskIOMetrics: Equatable {
    let readSpeed: Double // MB/s
    let writeSpeed: Double // MB/s
    let readOperations: Double // operations per second
    let writeOperations: Double // operations per second
    let diskName: String
    let timestamp: Date
    
    var formattedReadSpeed: String {
        return String(format: "%.1f MB/s", readSpeed)
    }
    
    var formattedWriteSpeed: String {
        return String(format: "%.1f MB/s", writeSpeed)
    }
    
    var formattedReadOps: String {
        return String(format: "%.0f ops/s", readOperations)
    }
    
    var formattedWriteOps: String {
        return String(format: "%.0f ops/s", writeOperations)
    }
}

protocol DiskIOServiceProtocol {
    func getCurrentDiskIOMetrics() async -> [DiskIOMetrics]
}

final class DiskIOService: DiskIOServiceProtocol, @unchecked Sendable {
    
    func getCurrentDiskIOMetrics() async -> [DiskIOMetrics] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let metrics = self.fetchDiskIOMetrics()
                continuation.resume(returning: metrics)
            }
        }
    }
    
    private func fetchDiskIOMetrics() -> [DiskIOMetrics] {
        var metrics: [DiskIOMetrics] = []
        
        print("DiskIOService: Starting fetchDiskIOMetrics")
        
        // Use iostat to get disk I/O statistics
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/iostat")
        task.arguments = ["-d", "1", "1"] // Get data for 1 second, 1 iteration
        
        print("DiskIOService: Configured iostat command: \(task.executableURL?.path ?? "nil") \(task.arguments?.joined(separator: " ") ?? "nil")")
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            print("DiskIOService: Executing iostat command...")
            try task.run()
            
            // Add a timeout mechanism
            let startTime = Date()
            let timeout: TimeInterval = 10.0 // 10 seconds timeout
            
            while task.isRunning && Date().timeIntervalSince(startTime) < timeout {
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            if task.isRunning {
                print("DiskIOService: Command timed out, terminating...")
                task.terminate()
                task.waitUntilExit()
                print("DiskIOService: Command terminated due to timeout")
                return metrics
            }
            
            print("DiskIOService: iostat completed with exit code: \(task.terminationStatus)")
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            print("DiskIOService: Read \(data.count) bytes of output")
            
            if let output = String(data: data, encoding: .utf8) {
                print("DiskIOService: Successfully decoded output (\(output.count) characters)")
                print("DiskIOService: Raw output:\n\(output)")
                metrics = parseIOStatOutput(output)
                print("DiskIOService: parseIOStatOutput returned \(metrics.count) metrics")
            } else {
                print("DiskIOService: Failed to decode output as UTF-8")
            }
        } catch {
            print("DiskIOService: Failed to run iostat command: \(error)")
        }
        
        print("DiskIOService: fetchDiskIOMetrics returning \(metrics.count) metrics")
        return metrics
    }
    
    private func parseIOStatOutput(_ output: String) -> [DiskIOMetrics] {
        let lines = output.components(separatedBy: .newlines)
        print("DiskIOService: parseIOStatOutput - processing \(lines.count) lines")
        
        // Find the last set of data (iostat shows historical data then current)
        // Look for lines with numeric data after the headers
        var diskNames: [String] = []
        
        // First pass: find disk names from the header
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            print("DiskIOService: Line \(index): '\(trimmedLine)'")
            if trimmedLine.contains("disk") && !trimmedLine.contains("KB/t") {
                diskNames = extractDiskNames(from: trimmedLine)
                print("DiskIOService: Found disk names: \(diskNames)")
                break
            }
        }
        
        guard !diskNames.isEmpty else { 
            print("DiskIOService: No disk names found, returning empty")
            return [] 
        }
        
        // Second pass: find the last data line (most recent stats)
        print("DiskIOService: Searching for data lines (working backwards)...")
        for (index, line) in lines.reversed().enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            print("DiskIOService: Checking line \(lines.count - 1 - index): '\(trimmedLine)'")
            
            // Skip empty lines and header lines
            if trimmedLine.isEmpty || trimmedLine.contains("disk") || trimmedLine.contains("KB/t") {
                print("DiskIOService: Skipping header/empty line")
                continue
            }
            
            // Try to parse this line as data
            let components = trimmedLine.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            
            print("DiskIOService: Found \(components.count) components: \(components)")
            print("DiskIOService: Expected \(diskNames.count * 3) components for \(diskNames.count) disks")
            
            // Should have 3 values per disk: KB/t, tps, MB/s
            if components.count >= diskNames.count * 3 {
                print("DiskIOService: Attempting to parse data line...")
                if let parsedMetrics = parseDataLine(trimmedLine, diskNames: diskNames) {
                    print("DiskIOService: Successfully parsed \(parsedMetrics.count) metrics")
                    return parsedMetrics
                } else {
                    print("DiskIOService: Failed to parse data line")
                }
            } else {
                print("DiskIOService: Insufficient components for data line")
            }
        }
        
        print("DiskIOService: No valid data lines found, returning empty")
        return []
    }
    
    private func extractDiskNames(from line: String) -> [String] {
        // Extract disk names from a line like "              disk0               disk4               disk6"
        let components = line.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.hasPrefix("disk") }
        return components
    }
    
    private func parseDataLine(_ line: String, diskNames: [String]) -> [DiskIOMetrics]? {
        let components = line.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        print("DiskIOService: parseDataLine - components: \(components)")
        print("DiskIOService: parseDataLine - diskNames: \(diskNames)")
        
        // Each disk has 3 values: KB/t, tps, MB/s
        let valuesPerDisk = 3
        let expectedComponents = diskNames.count * valuesPerDisk
        
        print("DiskIOService: parseDataLine - expected: \(expectedComponents), got: \(components.count)")
        
        guard components.count >= expectedComponents else { 
            print("DiskIOService: parseDataLine - insufficient components")
            return nil 
        }
        
        var metrics: [DiskIOMetrics] = []
        
        for (index, diskName) in diskNames.enumerated() {
            let baseIndex = index * valuesPerDisk
            guard baseIndex + 2 < components.count else { 
                print("DiskIOService: parseDataLine - insufficient data for disk \(diskName)")
                continue 
            }
            
            let kbValue = components[baseIndex]
            let tpsValue = components[baseIndex + 1]
            let mbpsValue = components[baseIndex + 2]
            
            print("DiskIOService: parseDataLine - \(diskName): KB/t='\(kbValue)', tps='\(tpsValue)', MB/s='\(mbpsValue)'")
            
            // iostat format: KB/t, tps, MB/s
            if let _ = Double(kbValue),
               let tps = Double(tpsValue), // transactions per second
               let mbps = Double(mbpsValue) { // MB/s throughput
                
                print("DiskIOService: parseDataLine - \(diskName): parsed tps=\(tps), mbps=\(mbps)")
                
                // Estimate read/write split (iostat doesn't separate them easily)
                // Use transactions per second and throughput to estimate activity
                let readOps = tps * 0.6 // Assume 60% reads
                let writeOps = tps * 0.4 // Assume 40% writes
                let readSpeed = mbps * 0.6
                let writeSpeed = mbps * 0.4
                
                let metric = DiskIOMetrics(
                    readSpeed: readSpeed,
                    writeSpeed: writeSpeed,
                    readOperations: readOps,
                    writeOperations: writeOps,
                    diskName: diskName,
                    timestamp: Date()
                )
                
                // Always include the main disk, only filter out external disks if idle
                if diskName == "disk0" || tps > 0.01 || mbps > 0.001 {
                    metrics.append(metric)
                    print("DiskIOService: parseDataLine - added metric for \(diskName)")
                } else {
                    print("DiskIOService: parseDataLine - filtered out idle disk \(diskName)")
                }
            } else {
                print("DiskIOService: parseDataLine - failed to parse numeric values for \(diskName)")
            }
        }
        
        print("DiskIOService: parseDataLine - returning \(metrics.count) metrics")
        return metrics.isEmpty ? nil : metrics
    }
}