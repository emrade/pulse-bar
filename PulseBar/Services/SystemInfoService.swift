//
//  SystemInfoService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import Foundation

final class SystemInfoService {
    static let shared = SystemInfoService()
    
    private init() {}
    
    var computerName: String {
        Host.current().localizedName ?? "Mac"
    }
    
    var deviceModel: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        let model = String(cString: machine)
        
        // Convert technical model to friendly names
        return friendlyDeviceName(from: model)
    }
    
    var chipName: String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var brandString = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &brandString, &size, nil, 0)
        let brand = String(cString: brandString)
        
        if brand.contains("Apple") {
            // For Apple Silicon, get the specific chip name
            return getAppleChipName()
        } else {
            return brand.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    var totalMemory: String {
        var size = MemoryLayout<UInt64>.size
        var memSize: UInt64 = 0
        sysctlbyname("hw.memsize", &memSize, &size, nil, 0)
        return ByteCountFormatter.string(fromByteCount: Int64(memSize), countStyle: .memory)
    }
    
    var macOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        
        // Add macOS names based on version
        switch version.majorVersion {
        case 15:
            return "macOS Sequoia \(versionString)"
        case 14:
            return "macOS Sonoma \(versionString)"
        case 13:
            return "macOS Ventura \(versionString)"
        case 12:
            return "macOS Monterey \(versionString)"
        case 11:
            return "macOS Big Sur \(versionString)"
        default:
            return "macOS \(versionString)"
        }
    }
    
    var systemArchitecture: String {
        var size = 0
        sysctlbyname("hw.targettype", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.targettype", &machine, &size, nil, 0)
        let targetType = String(cString: machine)
        return targetType.isEmpty ? "Apple Silicon" : targetType
    }
    
    // MARK: - Private Helpers
    
    private func friendlyDeviceName(from model: String) -> String {
        // Convert technical model names to user-friendly names
        let modelMappings: [String: String] = [
            // MacBook Air
            "Mac14,2": "MacBook Air M2",
            "Mac14,15": "MacBook Air M2", 
            "Mac15,3": "MacBook Air M3",
            "Mac15,4": "MacBook Air M3",
            
            // MacBook Pro M2
            "Mac14,7": "MacBook Pro M2",
            "Mac14,5": "MacBook Pro M2 Pro", 
            "Mac14,6": "MacBook Pro M2 Max",
            "Mac14,9": "MacBook Pro M2 Pro",
            "Mac14,10": "MacBook Pro M2 Max",
            
            // MacBook Pro M3
            "Mac15,6": "MacBook Pro M3",
            "Mac15,7": "MacBook Pro M3",
            "Mac15,8": "MacBook Pro M3 Pro",
            "Mac15,9": "MacBook Pro M3 Pro",
            "Mac15,10": "MacBook Pro M3 Max",
            "Mac15,11": "MacBook Pro M3 Max",
            
            // MacBook Pro M4 (2024)
            "Mac16,1": "MacBook Pro M4",
            "Mac16,5": "MacBook Pro M4 Max",
            "Mac16,6": "MacBook Pro M4 Pro",
            "Mac16,7": "MacBook Pro M4 Pro",
            "Mac16,8": "MacBook Pro M4 Pro",
            
            // Mac Studio
            "Mac14,13": "Mac Studio M2 Max",
            "Mac14,14": "Mac Studio M2 Ultra",
            "Mac13,1": "Mac Studio M1 Max",
            "Mac13,2": "Mac Studio M1 Ultra",
            
            // Mac mini
            "Mac14,12": "Mac mini M2",
            "Mac14,3": "Mac mini M2 Pro"
        ]
        
        return modelMappings[model] ?? model
    }
    
    private func getAppleChipName() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        let model = String(cString: machine)
        
        // Direct mapping based on exact model identifiers
        let chipMappings: [String: String] = [
            // M4 Models (Mac16)
            "Mac16,1": "Apple M4",
            "Mac16,5": "Apple M4 Max",
            "Mac16,6": "Apple M4 Pro",
            "Mac16,7": "Apple M4 Pro",
            "Mac16,8": "Apple M4 Pro",
            
            // M3 Models (Mac15)
            "Mac15,3": "Apple M3",
            "Mac15,4": "Apple M3",
            "Mac15,6": "Apple M3",
            "Mac15,7": "Apple M3",
            "Mac15,8": "Apple M3 Pro",
            "Mac15,9": "Apple M3 Pro",
            "Mac15,10": "Apple M3 Max",
            "Mac15,11": "Apple M3 Max",
            
            // M2 Models (Mac14)
            "Mac14,2": "Apple M2",
            "Mac14,3": "Apple M2 Pro",
            "Mac14,5": "Apple M2 Pro",
            "Mac14,6": "Apple M2 Max",
            "Mac14,7": "Apple M2",
            "Mac14,9": "Apple M2 Pro",
            "Mac14,10": "Apple M2 Max",
            "Mac14,12": "Apple M2",
            "Mac14,13": "Apple M2 Max",
            "Mac14,14": "Apple M2 Ultra",
            "Mac14,15": "Apple M2",
            
            // M1 Models (Mac13, Mac12)
            "Mac13,1": "Apple M1 Max",
            "Mac13,2": "Apple M1 Ultra",
            "Mac12,1": "Apple M1 Pro",
            "Mac12,2": "Apple M1 Pro"
        ]
        
        // Return exact mapping if available, otherwise use fallback logic
        if let chipName = chipMappings[model] {
            return chipName
        }
        
        // Fallback logic for unknown models
        if model.contains("Mac16") {
            return "Apple M4"
        } else if model.contains("Mac15") {
            return "Apple M3"
        } else if model.contains("Mac14") {
            return "Apple M2"
        } else if model.contains("Mac13") || model.contains("Mac12") {
            return "Apple M1"
        } else {
            return "Apple Silicon"
        }
    }
}