//
//  AppSettings.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import Foundation
import SwiftUI

// MARK: - Settings Model
struct AppSettings: Codable {
    var refreshInterval: RefreshInterval = .twoSeconds
    var temperatureUnit: TemperatureUnit = .celsius
    var memoryUnit: MemoryUnit = .binary
    var launchAtLogin: Bool = false
    var showDockIcon: Bool = false
    var defaultView: DefaultView = .dashboard
    var speedTestRegion: SpeedTestRegion = .auto
    var autoResetDailyData: Bool = true
    var enableNotifications: Bool = false
    var cpuWarningThreshold: Double = 0.80
    var memoryWarningThreshold: Double = 0.85
    var temperatureWarningThreshold: Double = 80.0
}

// MARK: - Settings Enums
enum RefreshInterval: String, CaseIterable, Codable {
    case oneSecond = "1s"
    case twoSeconds = "2s"
    case fiveSeconds = "5s"
    case tenSeconds = "10s"
    
    var displayName: String {
        switch self {
        case .oneSecond: return "1 second"
        case .twoSeconds: return "2 seconds"
        case .fiveSeconds: return "5 seconds"
        case .tenSeconds: return "10 seconds"
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .oneSecond: return 1.0
        case .twoSeconds: return 2.0
        case .fiveSeconds: return 5.0
        case .tenSeconds: return 10.0
        }
    }
}

enum TemperatureUnit: String, CaseIterable, Codable {
    case celsius = "C"
    case fahrenheit = "F"
    
    var displayName: String {
        switch self {
        case .celsius: return "Celsius (°C)"
        case .fahrenheit: return "Fahrenheit (°F)"
        }
    }
}

enum MemoryUnit: String, CaseIterable, Codable {
    case binary = "binary"
    case decimal = "decimal"
    
    var displayName: String {
        switch self {
        case .binary: return "Binary (1024 bytes = 1 KB)"
        case .decimal: return "Decimal (1000 bytes = 1 KB)"
        }
    }
}

enum DefaultView: String, CaseIterable, Codable {
    case dashboard = "dashboard"
    
    var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        }
    }
}

enum SpeedTestRegion: String, CaseIterable, Codable {
    case auto = "auto"
    case northAmerica = "na"
    case europe = "eu"
    case asia = "asia"
    
    var displayName: String {
        switch self {
        case .auto: return "Auto (Recommended)"
        case .northAmerica: return "North America"
        case .europe: return "Europe"
        case .asia: return "Asia"
        }
    }
}

// MARK: - Thread-Safe Settings Access
struct SettingsAccessor {
    private static let settingsKey = "PulseBarSettings"
    
    static func getCurrentSettings() -> AppSettings {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decodedSettings
        }
        return AppSettings()
    }
}

// MARK: - Settings Manager
@MainActor
class SettingsManager: ObservableObject {
    @Published var settings = AppSettings()
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "PulseBarSettings"
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decodedSettings
        }
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
    
    func resetToDefaults() {
        settings = AppSettings()
        saveSettings()
    }
    
    // MARK: - Launch at Login
    func toggleLaunchAtLogin() {
        settings.launchAtLogin.toggle()
        setLaunchAtLogin(settings.launchAtLogin)
        saveSettings()
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        // Implementation would go here for macOS launch services
        // This is a simplified version
        if Bundle.main.bundleIdentifier != nil {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            
            if enabled {
                task.arguments = [
                    "-e",
                    "tell application \"System Events\" to make login item at end with properties {path:\"\(Bundle.main.bundlePath)\", hidden:false}"
                ]
            } else {
                task.arguments = [
                    "-e",
                    "tell application \"System Events\" to delete login items whose name is \"PulseBar\""
                ]
            }
            
            do {
                try task.run()
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }
    
    // MARK: - Export Settings
    func exportSettings() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if let data = try? encoder.encode(settings),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        
        return "Failed to export settings"
    }
    
    func importSettings(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8),
              let importedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return false
        }
        
        settings = importedSettings
        saveSettings()
        return true
    }
}