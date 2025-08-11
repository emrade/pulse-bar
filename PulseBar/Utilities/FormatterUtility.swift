//
//  FormatterUtility.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import Foundation

// MARK: - Centralized Formatting Utility
final class FormatterUtility {
    static let shared = FormatterUtility()
    
    private init() {}
    
    // MARK: - Settings Access
    private var settings: AppSettings {
        return SettingsAccessor.getCurrentSettings()
    }
    
    // MARK: - Memory Formatting
    func formatBytes(_ bytes: UInt64, style: ByteCountFormatter.CountStyle = .memory) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        
        // Use user's preferred memory unit setting
        switch settings.memoryUnit {
        case .binary:
            formatter.countStyle = .binary  // 1024-based (1 KB = 1024 bytes)
        case .decimal:
            formatter.countStyle = .decimal  // 1000-based (1 KB = 1000 bytes)
        }
        
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func formatBytes(_ bytes: Int64, style: ByteCountFormatter.CountStyle = .memory) -> String {
        return formatBytes(UInt64(max(0, bytes)), style: style)
    }
    
    func formatBytes(_ bytes: Double, style: ByteCountFormatter.CountStyle = .memory) -> String {
        return formatBytes(UInt64(max(0, bytes)), style: style)
    }
    
    // MARK: - Temperature Formatting
    func formatTemperature(_ celsius: Double) -> String {
        switch settings.temperatureUnit {
        case .celsius:
            return String(format: "%.0f°C", celsius)
        case .fahrenheit:
            let fahrenheit = celsius * 9.0 / 5.0 + 32.0
            return String(format: "%.0f°F", fahrenheit)
        }
    }
    
    func formatTemperature(_ celsius: Double?) -> String {
        guard let temp = celsius else { return "Unknown" }
        return formatTemperature(temp)
    }
    
    // MARK: - Temperature Conversion Utilities
    func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return celsius * 9.0 / 5.0 + 32.0
    }
    
    func fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        return (fahrenheit - 32.0) * 5.0 / 9.0
    }
    
    // MARK: - Memory Unit Information
    var memoryUnitSuffix: String {
        switch settings.memoryUnit {
        case .binary: return " (1024-based)"
        case .decimal: return " (1000-based)"
        }
    }
    
    var temperatureUnitSuffix: String {
        switch settings.temperatureUnit {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
    
    // MARK: - Specialized Formatters
    
    /// Format bytes specifically for file sizes (usually decimal)
    func formatFileSize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        formatter.countStyle = settings.memoryUnit == .binary ? .binary : .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Format bytes specifically for memory usage (respects user setting)
    func formatMemorySize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        formatter.countStyle = settings.memoryUnit == .binary ? .memory : .decimal
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Format bytes for network usage (typically decimal)
    func formatNetworkSize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        // Network is usually measured in decimal, but respect user preference
        formatter.countStyle = settings.memoryUnit == .binary ? .binary : .decimal
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Convenience Extensions
extension UInt64 {
    var formattedBytes: String {
        return FormatterUtility.shared.formatBytes(self)
    }
    
    var formattedFileSize: String {
        return FormatterUtility.shared.formatFileSize(self)
    }
    
    var formattedMemorySize: String {
        return FormatterUtility.shared.formatMemorySize(self)
    }
    
    var formattedNetworkSize: String {
        return FormatterUtility.shared.formatNetworkSize(self)
    }
}

extension Double {
    var formattedTemperature: String {
        return FormatterUtility.shared.formatTemperature(self)
    }
    
    var formattedBytes: String {
        return FormatterUtility.shared.formatBytes(self)
    }
}

extension Int64 {
    var formattedBytes: String {
        return FormatterUtility.shared.formatBytes(self)
    }
}