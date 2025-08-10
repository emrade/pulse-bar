//
//  StorageAnalysisService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation

struct StorageCategoryInfo {
    let name: String
    let sizeBytes: UInt64
    let color: String // For UI color coding
    let description: String
    
    var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .binary)
    }
}

protocol StorageAnalysisServiceProtocol {
    func analyzeStorageBreakdown(totalUsedBytes: UInt64) async -> [StorageCategoryInfo]
}

final class StorageAnalysisService: StorageAnalysisServiceProtocol, @unchecked Sendable {
    
    func analyzeStorageBreakdown(totalUsedBytes: UInt64) async -> [StorageCategoryInfo] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let categories = self.performStorageAnalysis(totalUsedBytes: totalUsedBytes)
                continuation.resume(returning: categories)
            }
        }
    }
    
    func performStorageAnalysis(totalUsedBytes: UInt64) -> [StorageCategoryInfo] {
        var categories: [StorageCategoryInfo] = []
        
        // Only analyze accessible directories without permission issues
        let categoriesToAnalyze: [(name: String, paths: [String], color: String, description: String)] = [
            ("Applications", ["/Applications"], "green", "Applications and utilities")
        ]
        
        var totalAnalyzedSize: UInt64 = 0
        
        for category in categoriesToAnalyze {
            var totalSize: UInt64 = 0
            for path in category.paths {
                let size = calculateDirectorySize(at: path)
                totalSize += size
            }
            
            // Always include Applications category, even if size is 0 or scan failed
            categories.append(StorageCategoryInfo(
                name: category.name,
                sizeBytes: totalSize,
                color: category.color,
                description: category.description
            ))
            totalAnalyzedSize += totalSize
        }
        
        // Calculate "Other" as the remaining used space
        if totalUsedBytes > totalAnalyzedSize {
            let otherSize = totalUsedBytes - totalAnalyzedSize
            categories.append(StorageCategoryInfo(
                name: "Other",
                sizeBytes: otherSize,
                color: "gray",
                description: "Documents, system files, and other data"
            ))
        }
        
        // Sort by size (largest first)
        categories.sort { $0.sizeBytes > $1.sizeBytes }
        
        return categories
    }
    
    private func performStorageAnalysis() -> [StorageCategoryInfo] {
        // This method is kept for compatibility but shouldn't be used directly
        return []
    }
    
    private func calculateDirectorySize(at path: String) -> UInt64 {
        let fileManager = FileManager.default
        var totalSize: UInt64 = 0
        
        guard fileManager.fileExists(atPath: path) else {
            return 0
        }
        
        // Use file enumeration with timeout and size limits
        let startTime = Date()
        let maxDuration: TimeInterval = 5.0 // 5 seconds max per directory (faster for simple analysis)
        let maxItemsToProcess = 5000 // Prevent runaway enumeration
        var itemsProcessed = 0
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return 0
        }
        
        while let item = enumerator.nextObject() as? String {
            // Check timeout and item limits
            itemsProcessed += 1
            if Date().timeIntervalSince(startTime) > maxDuration {
                break
            }
            
            if itemsProcessed > maxItemsToProcess {
                break
            }
            
            let itemPath = (path as NSString).appendingPathComponent(item)
            
            do {
                let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                if let fileSize = attributes[.size] as? UInt64 {
                    totalSize += fileSize
                }
            } catch {
                // Skip files we can't access (permissions, etc.)
                continue
            }
        }
        
        return totalSize
    }
}