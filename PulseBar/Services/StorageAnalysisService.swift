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
        print("StorageAnalysisService: Starting simplified storage analysis")
        var categories: [StorageCategoryInfo] = []
        
        // Get home directory
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        
        // Only analyze accessible directories without permission issues
        let categoriesToAnalyze: [(name: String, paths: [String], color: String, description: String)] = [
            ("Applications", ["/Applications"], "green", "Applications and utilities"),
            ("Documents", [homeDir.appendingPathComponent("Documents").path], "blue", "Your documents and files")
        ]
        
        var totalAnalyzedSize: UInt64 = 0
        
        for category in categoriesToAnalyze {
            print("StorageAnalysisService: Analyzing category: \(category.name)")
            
            var totalSize: UInt64 = 0
            for path in category.paths {
                let size = calculateDirectorySize(at: path)
                totalSize += size
                print("StorageAnalysisService: \(path) = \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .binary))")
            }
            
            if totalSize > 0 {
                categories.append(StorageCategoryInfo(
                    name: category.name,
                    sizeBytes: totalSize,
                    color: category.color,
                    description: category.description
                ))
                totalAnalyzedSize += totalSize
                print("StorageAnalysisService: \(category.name) total = \(ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .binary))")
            }
        }
        
        // Calculate "Other" as the remaining used space
        if totalUsedBytes > totalAnalyzedSize {
            let otherSize = totalUsedBytes - totalAnalyzedSize
            categories.append(StorageCategoryInfo(
                name: "Other",
                sizeBytes: otherSize,
                color: "gray",
                description: "System files and other data"
            ))
            print("StorageAnalysisService: Other calculated = \(ByteCountFormatter.string(fromByteCount: Int64(otherSize), countStyle: .binary))")
        }
        
        // Sort by size (largest first)
        categories.sort { $0.sizeBytes > $1.sizeBytes }
        
        print("StorageAnalysisService: Analysis complete with \(categories.count) categories")
        print("StorageAnalysisService: Total analyzed: \(ByteCountFormatter.string(fromByteCount: Int64(totalAnalyzedSize), countStyle: .binary))")
        print("StorageAnalysisService: Total used: \(ByteCountFormatter.string(fromByteCount: Int64(totalUsedBytes), countStyle: .binary))")
        
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
            print("StorageAnalysisService: Path does not exist: \(path)")
            return 0
        }
        
        // Use file enumeration with timeout and size limits
        let startTime = Date()
        let maxDuration: TimeInterval = 5.0 // 5 seconds max per directory (faster for simple analysis)
        let maxItemsToProcess = 5000 // Prevent runaway enumeration
        var itemsProcessed = 0
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            print("StorageAnalysisService: Could not create enumerator for: \(path)")
            return 0
        }
        
        while let item = enumerator.nextObject() as? String {
            // Check timeout and item limits
            itemsProcessed += 1
            if Date().timeIntervalSince(startTime) > maxDuration {
                print("StorageAnalysisService: Timeout reached for \(path) after \(itemsProcessed) items")
                break
            }
            
            if itemsProcessed > maxItemsToProcess {
                print("StorageAnalysisService: Item limit reached for \(path)")
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