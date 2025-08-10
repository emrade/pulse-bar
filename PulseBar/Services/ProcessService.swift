//
//  ProcessService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation

struct ProcessMemoryInfo {
    let name: String
    let pid: Int32
    let memoryUsage: UInt64 // in bytes
}

protocol ProcessServiceProtocol {
    func getTopMemoryProcesses(limit: Int) async -> [ProcessMemoryInfo]
}

final class ProcessService: ProcessServiceProtocol, @unchecked Sendable {
    
    func getTopMemoryProcesses(limit: Int = 5) async -> [ProcessMemoryInfo] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let processes = self.fetchTopProcesses(limit: limit)
                continuation.resume(returning: processes)
            }
        }
    }
    
    private func fetchTopProcesses(limit: Int) -> [ProcessMemoryInfo] {
        var processes: [ProcessMemoryInfo] = []
        
        // Use the ps command to get process information
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-ax", "-o", "pid,rss,comm", "-r"] // Sort by RSS (memory)
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                processes = parseProcessOutput(output, limit: limit)
            }
        } catch {
            print("Failed to run ps command: \(error)")
        }
        
        return processes
    }
    
    private func parseProcessOutput(_ output: String, limit: Int) -> [ProcessMemoryInfo] {
        let lines = output.components(separatedBy: .newlines)
        var processes: [ProcessMemoryInfo] = []
        
        // Skip the header line
        for line in lines.dropFirst() {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            
            let components = line.trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            
            if components.count >= 3 {
                if let pid = Int32(components[0]),
                   let rss = UInt64(components[1]) {
                    
                    // RSS is in KB, convert to bytes
                    let memoryBytes = rss * 1024
                    
                    // Get the process name (everything after the first two components)
                    let processName = components.dropFirst(2).joined(separator: " ")
                    let cleanName = cleanProcessName(processName)
                    
                    // Filter out system processes and very low memory processes
                    if memoryBytes > 10 * 1024 * 1024 && !isSystemProcess(cleanName) { // > 10MB
                        processes.append(ProcessMemoryInfo(
                            name: cleanName,
                            pid: pid,
                            memoryUsage: memoryBytes
                        ))
                    }
                }
            }
            
            if processes.count >= limit {
                break
            }
        }
        
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
}