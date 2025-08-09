//
//  DiskService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

final class DiskService: DiskServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<DiskMetrics, Never>(DiskMetrics())
    
    var metricsPublisher: AnyPublisher<DiskMetrics, Never> {
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
            let diskMetrics = try await fetchDiskMetrics()
            await MainActor.run {
                metricsSubject.send(diskMetrics)
            }
        } catch {
            print("Disk Service Error: \(error)")
            let errorMetrics = DiskMetrics(
                volumes: [],
                isLoading: false,
                error: error.localizedDescription
            )
            await MainActor.run {
                metricsSubject.send(errorMetrics)
            }
        }
    }
    
    private func fetchDiskMetrics() async throws -> DiskMetrics {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let metrics = try self.getDiskUsage()
                    continuation.resume(returning: metrics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getDiskUsage() throws -> DiskMetrics {
        var volumes: [VolumeInfo] = []
        
        // Get all mounted volumes
        let fileManager = FileManager.default
        guard let mountedVolumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey,
                .volumeIsEjectableKey,
                .volumeIsRemovableKey,
                .volumeIsInternalKey
            ],
            options: .skipHiddenVolumes
        ) else {
            throw DiskServiceError.fileSystemError("Failed to get mounted volumes")
        }
        
        for volumeURL in mountedVolumes {
            do {
                let resourceValues = try volumeURL.resourceValues(forKeys: [
                    .volumeNameKey,
                    .volumeTotalCapacityKey,
                    .volumeAvailableCapacityKey,
                    .volumeIsEjectableKey,
                    .volumeIsRemovableKey,
                    .volumeIsInternalKey
                ])
                
                let name = resourceValues.volumeName ?? "Unknown Volume"
                let totalBytes = UInt64(resourceValues.volumeTotalCapacity ?? 0)
                let availableBytes = UInt64(resourceValues.volumeAvailableCapacity ?? 0)
                let isEjectable = resourceValues.volumeIsEjectable ?? false
                let isRemovable = resourceValues.volumeIsRemovable ?? false
                let isInternal = resourceValues.volumeIsInternal ?? true
                
                // Skip very small volumes (likely system volumes)
                guard totalBytes > 1_000_000_000 else { continue } // Skip volumes < 1GB
                
                let isBootVolume = volumeURL.path == "/"
                let isExternal = !isInternal || isRemovable || isEjectable
                
                let volumeInfo = VolumeInfo(
                    name: name,
                    mountPoint: volumeURL.path,
                    totalBytes: totalBytes,
                    freeBytes: availableBytes,
                    isBootVolume: isBootVolume,
                    isExternal: isExternal
                )
                
                volumes.append(volumeInfo)
            } catch {
                print("Failed to get resource values for volume \(volumeURL): \(error)")
                continue
            }
        }
        
        // Sort volumes: boot volume first, then internal, then external
        volumes.sort { lhs, rhs in
            if lhs.isBootVolume { return true }
            if rhs.isBootVolume { return false }
            if lhs.isExternal != rhs.isExternal {
                return !lhs.isExternal // Internal volumes before external
            }
            return lhs.name < rhs.name
        }
        
        return DiskMetrics(
            volumes: volumes,
            isLoading: false,
            error: nil
        )
    }
}

enum DiskServiceError: Error, LocalizedError {
    case fileSystemError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileSystemError(let message):
            return "Disk monitoring error: \(message)"
        }
    }
}