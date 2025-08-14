//
//  ProcessService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation
import os

struct ProcessMemoryInfo {
    let name: String
    let pid: Int32
    let memoryUsage: UInt64 // in bytes
}

protocol ProcessServiceProtocol {
    func getTopMemoryProcesses(limit: Int) async -> [ProcessMemoryInfo]
}

final class ProcessService: ProcessServiceProtocol, @unchecked Sendable {
    private let logger = PulseBarLogger.shared
    
    func getTopMemoryProcesses(limit: Int = 5) async -> [ProcessMemoryInfo] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let processes = self.fetchTopProcesses(limit: limit)
                continuation.resume(returning: processes)
            }
        }
    }
    
    private func fetchTopProcesses(limit: Int) -> [ProcessMemoryInfo] {
        // Input validation
        guard limit > 0 && limit <= 100 else {
            logger.logSystemError("Invalid limit parameter: \(limit)")
            return []
        }
        
        var processes: [ProcessMemoryInfo] = []
        
        // Create secure process configuration
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        
        // Validate and sanitize arguments
        let sanitizedArguments = sanitizeProcessArguments(["-ax", "-o", "pid,rss,comm", "-r"])
        task.arguments = sanitizedArguments
        
        // Set up secure environment
        task.environment = createSecureEnvironment()
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Capture errors
        
        do {
            try task.run()
            
            // Implement timeout mechanism
            let timeoutResult = try waitForProcessWithTimeout(task: task, pipe: pipe, timeout: 10.0)
            
            if timeoutResult.success && task.terminationStatus == 0 {
                if let output = String(data: timeoutResult.data, encoding: .utf8) {
                    processes = parseProcessOutput(output, limit: limit)
                }
            } else if !timeoutResult.success {
                logger.logSystemWarning("Process timed out after 10 seconds")
                task.terminate()
            } else {
                logger.logSystemError("Process failed with exit code: \(task.terminationStatus)")
            }
        } catch {
            logger.logSystemError("Failed to run ps command", error: error)
            // Ensure process is cleaned up on error
            if task.isRunning {
                task.terminate()
            }
        }
        
        return processes
    }

    
    private func parseProcessOutput(_ output: String, limit: Int) -> [ProcessMemoryInfo] {
        let lines = output.components(separatedBy: .newlines)
        var processes: [ProcessMemoryInfo] = []
        
        logger.logSystemInfo("parseProcessOutput - processing \(lines.count) lines")
        
        // Skip the header line
        for (index, line) in lines.dropFirst().enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty {
                continue
            }
            
            let components = trimmedLine
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            
            if index < 5 { // Debug first few lines
                logger.logSystemInfo("Line \(index): '\(trimmedLine)' -> \(components.count) components: \(components)")
            }
            
            if components.count >= 3 {
                if let pid = Int32(components[0]),
                   let rss = UInt64(components[1]) {
                    
                    // RSS is in KB, convert to bytes
                    let memoryBytes = rss * 1024
                    
                    // Get the process name (everything after the first two components)
                    let processName = components.dropFirst(2).joined(separator: " ")
                    let cleanName = cleanProcessName(processName)
                    
                    if index < 5 { // Debug first few processes
                        logger.logSystemInfo("Parsed - pid: \(pid), rss: \(rss)KB (\(memoryBytes) bytes), name: '\(cleanName)'")
                    }
                    
                    // Filter out very low memory processes
                    if memoryBytes > 1 * 1024 * 1024 { // > 1MB
                        processes.append(ProcessMemoryInfo(
                            name: cleanName,
                            pid: pid,
                            memoryUsage: memoryBytes
                        ))
                        
                        if processes.count <= 5 { // Debug first few added
                            logger.logSystemInfo("Added process #\(processes.count): \(cleanName) (\(memoryBytes) bytes)")
                        }
                    } else {
                        if index < 5 {
                            logger.logSystemInfo("Filtered out low memory process: \(cleanName) (\(memoryBytes) bytes)")
                        }
                    }
                } else {
                    if index < 5 {
                        logger.logSystemWarning("Failed to parse pid/rss from: \(components)")
                    }
                }
            } else {
                if index < 5 {
                    logger.logSystemWarning("Insufficient components (\(components.count)) in line: \(components)")
                }
            }
            
            if processes.count >= limit {
                logger.logSystemInfo("Reached limit of \(limit) processes")
                break
            }
        }
        
        logger.logSystemInfo("parseProcessOutput - returning \(processes.count) processes")
        return processes
    }
    
    private func cleanProcessName(_ name: String) -> String {
        // Remove path prefixes
        let basename = (name as NSString).lastPathComponent
        
        // Handle common app bundle names
        if basename.hasSuffix(".app") {
            return String(basename.dropLast(4))
        }
        
        // Remove common system prefixes
        let prefixesToRemove = ["/System/Library/", "/usr/bin/", "/usr/sbin/", "/Applications/"]
        var cleanName = name
        
        for prefix in prefixesToRemove {
            if cleanName.hasPrefix(prefix) {
                cleanName = String(cleanName.dropFirst(prefix.count))
                break
            }
        }
        
        return cleanName.isEmpty ? name : cleanName
    }
    
    private func isSystemProcess(_ name: String) -> Bool {
        let systemProcesses = [
            "kernel_task", "launchd", "kextd", "mds", "mdworker", "spotlight",
            "com.apple.", "loginwindow", "SystemUIServer", "cfprefsd",
            "distnoted", "UserEventAgent", "coreservicesd", "finder"
        ]
        
        let lowercaseName = name.lowercased()
        return systemProcesses.contains { lowercaseName.contains($0.lowercased()) }
    }
    
    // MARK: - Security Helper Methods
    
    private func sanitizeProcessArguments(_ arguments: [String]) -> [String] {
        return arguments.compactMap { arg in
            // Remove any potentially dangerous characters
            let sanitized = arg.replacingOccurrences(of: ";", with: "")
                              .replacingOccurrences(of: "|", with: "")
                              .replacingOccurrences(of: "&", with: "")
                              .replacingOccurrences(of: "$", with: "")
                              .replacingOccurrences(of: "`", with: "")
                              .replacingOccurrences(of: ">", with: "")
                              .replacingOccurrences(of: "<", with: "")
            
            // Validate argument format for ps command
            if sanitized.hasPrefix("-") {
                let validOptions = ["-ax", "-o", "-r", "-e", "-f"]
                guard validOptions.contains(sanitized) else {
                    logger.logSecurityWarning("Invalid ps option: \(sanitized)")
                    return nil
                }
            } else if sanitized.contains(",") {
                // Validate format specifiers
                let validFormats = ["pid", "rss", "comm", "command", "cpu", "time"]
                let formats = sanitized.components(separatedBy: ",")
                for format in formats {
                    guard validFormats.contains(format.trimmingCharacters(in: .whitespaces)) else {
                        logger.logSecurityWarning("Invalid ps format: \(format)")
                        return nil
                    }
                }
            }
            
            return sanitized.isEmpty ? nil : sanitized
        }
    }
    
    private func createSecureEnvironment() -> [String: String] {
        // Create minimal, secure environment
        var secureEnv: [String: String] = [:]
        
        // Only include essential environment variables
        let allowedKeys = ["PATH", "HOME", "USER", "LANG", "LC_ALL"]
        
        for key in allowedKeys {
            if let value = ProcessInfo.processInfo.environment[key] {
                // Sanitize environment values
                let sanitizedValue = value.replacingOccurrences(of: ";", with: "")
                                         .replacingOccurrences(of: "|", with: "")
                                         .replacingOccurrences(of: "&", with: "")
                                         .replacingOccurrences(of: "$", with: "")
                                         .replacingOccurrences(of: "`", with: "")
                
                secureEnv[key] = sanitizedValue
            }
        }
        
        // Override PATH to only include system directories
        secureEnv["PATH"] = "/bin:/usr/bin:/sbin:/usr/sbin"
        
        return secureEnv
    }
    
    private func waitForProcessWithTimeout(task: Process, pipe: Pipe, timeout: TimeInterval) throws -> (success: Bool, data: Data) {
        let semaphore = DispatchSemaphore(value: 0)
        var processData = Data()
        var processCompleted = false
        
        // Read data asynchronously
        DispatchQueue.global().async {
            processData = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            processCompleted = true
            semaphore.signal()
        }
        
        // Wait with timeout
        let timeoutTime = DispatchTime.now() + timeout
        let result = semaphore.wait(timeout: timeoutTime)
        
        switch result {
        case .success:
            return (success: processCompleted, data: processData)
        case .timedOut:
            // Force terminate the process
            if task.isRunning {
                task.terminate()
                // Give it a moment to clean up
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    if task.isRunning {
                        task.interrupt()
                    }
                }
            }
            return (success: false, data: Data())
        }
    }
}