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

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/ps")
    task.arguments = ["-ax", "-o", "pid,rss,comm", "-r"]

    let pipe = Pipe()
    task.standardOutput = pipe

    do {
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            if let output = String(data: data, encoding: .utf8) {
                processes = parseProcessOutput(output, limit: limit)
            }
        }
    } catch {
        print("ProcessService: Failed to run ps command: \(error)")
    }

    return processes
}

    
    private func parseProcessOutput(_ output: String, limit: Int) -> [ProcessMemoryInfo] {
        let lines = output.components(separatedBy: .newlines)
        var processes: [ProcessMemoryInfo] = []
        
        print("ProcessService: parseProcessOutput - processing \(lines.count) lines")
        
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
                print("ProcessService: Line \(index): '\(trimmedLine)' -> \(components.count) components: \(components)")
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
                        print("ProcessService: Parsed - pid: \(pid), rss: \(rss)KB (\(memoryBytes) bytes), name: '\(cleanName)'")
                    }
                    
                    // Filter out very low memory processes
                    if memoryBytes > 1 * 1024 * 1024 { // > 1MB
                        processes.append(ProcessMemoryInfo(
                            name: cleanName,
                            pid: pid,
                            memoryUsage: memoryBytes
                        ))
                        
                        if processes.count <= 5 { // Debug first few added
                            print("ProcessService: Added process #\(processes.count): \(cleanName) (\(memoryBytes) bytes)")
                        }
                    } else {
                        if index < 5 {
                            print("ProcessService: Filtered out low memory process: \(cleanName) (\(memoryBytes) bytes)")
                        }
                    }
                } else {
                    if index < 5 {
                        print("ProcessService: Failed to parse pid/rss from: \(components)")
                    }
                }
            } else {
                if index < 5 {
                    print("ProcessService: Insufficient components (\(components.count)) in line: \(components)")
                }
            }
            
            if processes.count >= limit {
                print("ProcessService: Reached limit of \(limit) processes")
                break
            }
        }
        
        print("ProcessService: parseProcessOutput - returning \(processes.count) processes")
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