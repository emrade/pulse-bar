//
//  MemoryService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

final class MemoryService: MemoryServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<MemoryMetrics, Never>(MemoryMetrics())
    let processService: ProcessServiceProtocol
    
    var metricsPublisher: AnyPublisher<MemoryMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    init(processService: ProcessServiceProtocol = ProcessService()) {
        self.processService = processService
        // Initialize with first reading
        Task {
            await updateMetrics()
        }
    }
    
    func updateMetrics() async {
        do {
            let memoryMetrics = try await fetchMemoryMetrics()
            await MainActor.run {
                metricsSubject.send(memoryMetrics)
            }
        } catch {
            print("Memory Service Error: \(error)")
            let errorMetrics = MemoryMetrics(
                totalBytes: 0,
                usedBytes: 0,
                cachedBytes: 0,
                freeBytes: 0,
                isLoading: false,
                error: error.localizedDescription
            )
            await MainActor.run {
                metricsSubject.send(errorMetrics)
            }
        }
    }
    
    private func fetchMemoryMetrics() async throws -> MemoryMetrics {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let metrics = try self.getMemoryUsage()
                    continuation.resume(returning: metrics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getMemoryUsage() throws -> MemoryMetrics {
        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            throw MemoryServiceError.kernelError("Failed to get memory statistics: \(result)")
        }
        
        // Get physical memory size
        var physicalMemory: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        let sysctlResult = sysctlbyname("hw.memsize", &physicalMemory, &size, nil, 0)
        
        guard sysctlResult == 0 else {
            throw MemoryServiceError.kernelError("Failed to get physical memory size: \(sysctlResult)")
        }
        
        // Calculate memory usage
        let pageSize = UInt64(vm_kernel_page_size)
        
        let freeBytes = UInt64(vmStats.free_count) * pageSize
        let activeBytes = UInt64(vmStats.active_count) * pageSize
        let inactiveBytes = UInt64(vmStats.inactive_count) * pageSize
        let wiredBytes = UInt64(vmStats.wire_count) * pageSize
        let compressedBytes = UInt64(vmStats.compressor_page_count) * pageSize
        
        // Used memory = active + wired + compressed
        let usedBytes = activeBytes + wiredBytes + compressedBytes
        
        // Cached memory = inactive (can be reclaimed)
        let cachedBytes = inactiveBytes
        
        return MemoryMetrics(
            totalBytes: physicalMemory,
            usedBytes: usedBytes,
            cachedBytes: cachedBytes,
            freeBytes: freeBytes,
            isLoading: false,
            error: nil
        )
    }
}

enum MemoryServiceError: Error, LocalizedError {
    case kernelError(String)
    
    var errorDescription: String? {
        switch self {
        case .kernelError(let message):
            return "Memory monitoring error: \(message)"
        }
    }
}