//
//  CPUService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine
import os

final class CPUService: CPUServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<CPUMetrics, Never>(CPUMetrics())
    private let logger = PulseBarLogger.shared
    
    var metricsPublisher: AnyPublisher<CPUMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    // Previous CPU tick counters for delta calculation
    private let lock = NSLock()
    private var _previousCPUInfo: [processor_cpu_load_info] = []
    private var _previousTimestamp: Date = Date()
    
    private var previousCPUInfo: [processor_cpu_load_info] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _previousCPUInfo
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _previousCPUInfo = newValue
        }
    }
    
    private var previousTimestamp: Date {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _previousTimestamp
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _previousTimestamp = newValue
        }
    }
    
    init() {
        // Initialize with first reading
        Task {
            await updateMetrics()
        }
    }
    
    func updateMetrics() async {
        do {
            let cpuMetrics = try await fetchCPUMetrics()
            await MainActor.run {
                metricsSubject.send(cpuMetrics)
            }
        } catch {
            logger.logSystemError("CPU Service Error", error: error)
            let errorMetrics = CPUMetrics(
                overallUsage: 0.0,
                perCoreUsage: [],
                isLoading: false,
                error: error.localizedDescription
            )
            await MainActor.run {
                metricsSubject.send(errorMetrics)
            }
        }
    }
    
    private func fetchCPUMetrics() async throws -> CPUMetrics {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let metrics = try self.getCPUUsage()
                    continuation.resume(returning: metrics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getCPUUsage() throws -> CPUMetrics {
        var processorCount: natural_t = 0
        var cpuInfoArray: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        
        // Get processor count
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfoArray,
            &numCpuInfo
        )
        
        guard result == KERN_SUCCESS else {
            throw CPUServiceError.kernelError("Failed to get processor info: \(result)")
        }
        
        guard let cpuInfo = cpuInfoArray else {
            throw CPUServiceError.kernelError("CPU info array is null")
        }
        
        defer {
            // Clean up allocated memory
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(numCpuInfo))
        }
        
        // Convert to processor_cpu_load_info array
        let cpuLoadInfoPtr = UnsafeRawPointer(cpuInfo).bindMemory(to: processor_cpu_load_info.self, capacity: Int(processorCount))
        let currentCPUInfo = Array(UnsafeBufferPointer(start: cpuLoadInfoPtr, count: Int(processorCount)))
        let currentTimestamp = Date()
        
        // Calculate usage percentages
        var perCoreUsage: [Double] = []
        var totalUser: UInt32 = 0
        var totalSystem: UInt32 = 0
        var totalIdle: UInt32 = 0
        var totalNice: UInt32 = 0
        
        for i in 0..<Int(processorCount) {
            let current = currentCPUInfo[i]
            
            if i < previousCPUInfo.count {
                let previous = previousCPUInfo[i]
                
                // Calculate deltas
                let userDelta = current.cpu_ticks.0 - previous.cpu_ticks.0
                let systemDelta = current.cpu_ticks.1 - previous.cpu_ticks.1
                let idleDelta = current.cpu_ticks.2 - previous.cpu_ticks.2
                let niceDelta = current.cpu_ticks.3 - previous.cpu_ticks.3
                
                let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
                
                if totalDelta > 0 {
                    let activeDelta = userDelta + systemDelta + niceDelta
                    let usage = Double(activeDelta) / Double(totalDelta)
                    perCoreUsage.append(max(0.0, min(1.0, usage)))
                } else {
                    perCoreUsage.append(0.0)
                }
            } else {
                // First reading, no previous data
                perCoreUsage.append(0.0)
            }
            
            // Accumulate totals for overall usage
            totalUser += current.cpu_ticks.0
            totalSystem += current.cpu_ticks.1
            totalIdle += current.cpu_ticks.2
            totalNice += current.cpu_ticks.3
        }
        
        // Calculate overall usage
        var overallUsage: Double = 0.0
        if !previousCPUInfo.isEmpty && previousCPUInfo.count == currentCPUInfo.count {
            var totalUserDelta: UInt32 = 0
            var totalSystemDelta: UInt32 = 0
            var totalIdleDelta: UInt32 = 0
            var totalNiceDelta: UInt32 = 0
            
            for i in 0..<currentCPUInfo.count {
                totalUserDelta += currentCPUInfo[i].cpu_ticks.0 - previousCPUInfo[i].cpu_ticks.0
                totalSystemDelta += currentCPUInfo[i].cpu_ticks.1 - previousCPUInfo[i].cpu_ticks.1
                totalIdleDelta += currentCPUInfo[i].cpu_ticks.2 - previousCPUInfo[i].cpu_ticks.2
                totalNiceDelta += currentCPUInfo[i].cpu_ticks.3 - previousCPUInfo[i].cpu_ticks.3
            }
            
            let totalDelta = totalUserDelta + totalSystemDelta + totalIdleDelta + totalNiceDelta
            if totalDelta > 0 {
                let activeDelta = totalUserDelta + totalSystemDelta + totalNiceDelta
                overallUsage = Double(activeDelta) / Double(totalDelta)
                overallUsage = max(0.0, min(1.0, overallUsage))
            }
        }
        
        // Store current readings for next calculation
        previousCPUInfo = currentCPUInfo
        previousTimestamp = currentTimestamp
        
        return CPUMetrics(
            overallUsage: overallUsage,
            perCoreUsage: perCoreUsage,
            isLoading: false,
            error: nil
        )
    }
}

enum CPUServiceError: Error, LocalizedError {
    case kernelError(String)
    
    var errorDescription: String? {
        switch self {
        case .kernelError(let message):
            return "CPU monitoring error: \(message)"
        }
    }
}