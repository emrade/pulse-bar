//
//  ThemeManager.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI
import Foundation
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var currentTheme: Theme
    @Published private(set) var availableThemes: [Theme] = []
    @Published private(set) var builtInThemes: [Theme] = []
    @Published private(set) var customThemes: [Theme] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: ThemeError?
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let currentThemeKey = "selectedThemeId"
    
    // MARK: - Paths
    
    private var builtInThemesPath: URL? {
        // Try multiple possible paths
        if let resourcePath = Bundle.main.resourceURL?.appendingPathComponent("Themes"),
           FileManager.default.fileExists(atPath: resourcePath.path) {
            return resourcePath
        }
        
        // Try finding individual theme files
        if Bundle.main.url(forResource: "basic", withExtension: "json") != nil {
            return Bundle.main.resourceURL
        }
        
        return nil
    }
    
    private var userThemesPath: URL? {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, 
                                              in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent("PulseBar/Themes")
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with default theme
        self.currentTheme = Theme.defaultTheme
        
        // Load themes asynchronously
        Task {
            await loadThemes()
            await restoreSavedTheme()
        }
    }
    
    // MARK: - Public Methods
    
    func loadThemes() async {
        isLoading = true
        lastError = nil
        
        do {
            // Load built-in themes
            let builtIn = try await loadBuiltInThemes()
            
            // Load custom themes
            let custom = try await loadCustomThemes()
            
            await MainActor.run {
                self.builtInThemes = builtIn
                self.customThemes = custom
                self.availableThemes = builtIn + custom
                self.isLoading = false
            }
            
        } catch let error as ThemeError {
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.lastError = ThemeError.invalidThemeStructure(error.localizedDescription)
                self.isLoading = false
            }
        }
    }
    
    func applyTheme(_ theme: Theme) {
        do {
            try validateTheme(theme)
            currentTheme = theme
            saveCurrentTheme()
            
            // Update window size if needed
            updateWindowSize()
            
        } catch let error as ThemeError {
            lastError = error
        } catch {
            lastError = ThemeError.themeValidationFailed(error.localizedDescription)
        }
    }
    
    func saveCurrentTheme() {
        userDefaults.set(currentTheme.id, forKey: currentThemeKey)
    }
    
    func resetToDefault() {
        applyTheme(Theme.defaultTheme)
    }
    
    func importCustomTheme(from url: URL) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw ThemeError.fileNotFound(url.lastPathComponent)
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let data = try Data(contentsOf: url)
            let theme = try JSONDecoder().decode(Theme.self, from: data)
            
            try validateTheme(theme)
            
            // Save to custom themes directory
            try await saveCustomTheme(theme, from: data)
            
            // Reload themes
            await loadThemes()
            
        } catch let error as DecodingError {
            throw ThemeError.invalidJSON(error.localizedDescription)
        } catch let error as ThemeError {
            throw error
        } catch {
            throw ThemeError.invalidThemeStructure(error.localizedDescription)
        }
    }
    
    func deleteCustomTheme(_ theme: Theme) async throws {
        guard let userPath = userThemesPath else {
            throw ThemeError.customThemeDirectoryCreationFailed
        }
        
        let themeFile = userPath.appendingPathComponent("\(theme.id).json")
        
        if fileManager.fileExists(atPath: themeFile.path) {
            try fileManager.removeItem(at: themeFile)
            await loadThemes()
        }
    }
    
    func exportTheme(_ theme: Theme, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(theme)
        try data.write(to: url)
    }
    
    // MARK: - Convenience Properties
    
    var colors: ColorConfiguration {
        currentTheme.colors
    }
    
    var fonts: FontConfiguration {
        currentTheme.fonts
    }
    
    var layout: LayoutConfiguration {
        currentTheme.layout
    }
    
    var icons: IconConfiguration {
        currentTheme.icons
    }
    
    var effects: EffectConfiguration {
        currentTheme.effects
    }
    
    var components: ComponentConfiguration {
        currentTheme.components
    }
    
    var popover: PopoverConfiguration {
        currentTheme.popover
    }
    
    // MARK: - Private Methods
    
    private func loadBuiltInThemes() async throws -> [Theme] {
        guard let themesPath = builtInThemesPath else {
            // Try to load individual theme files directly
            return try await loadThemesFromIndividualFiles()
        }
        
        do {
            let themeFiles = try fileManager.contentsOfDirectory(at: themesPath, 
                                                                includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            
            var themes: [Theme] = []
            
            for file in themeFiles {
                do {
                    let data = try Data(contentsOf: file)
                    let theme = try JSONDecoder().decode(Theme.self, from: data)
                    do {
                        try validateTheme(theme)
                        themes.append(theme)
                    } catch {
                        themes.append(theme) // Still add it
                    }
                } catch {
                    // Skip invalid theme files
                    continue
                }
            }
            
            // Always include default theme if not already present
            if !themes.contains(where: { $0.id == Theme.defaultTheme.id }) {
                themes.append(Theme.defaultTheme)
            }
            
            return themes.sorted { $0.name < $1.name }
            
        } catch {
            return [Theme.defaultTheme]
        }
    }
    
    private func loadCustomThemes() async throws -> [Theme] {
        guard let userPath = userThemesPath else {
            return []
        }
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: userPath.path) {
            try fileManager.createDirectory(at: userPath, 
                                          withIntermediateDirectories: true)
        }
        
        do {
            let themeFiles = try fileManager.contentsOfDirectory(at: userPath,
                                                                includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            
            var themes: [Theme] = []
            
            for file in themeFiles {
                do {
                    let data = try Data(contentsOf: file)
                    let theme = try JSONDecoder().decode(Theme.self, from: data)
                    try validateTheme(theme)
                    themes.append(theme)
                } catch {
                    // Skip invalid theme files
                }
            }
            
            return themes.sorted { $0.name < $1.name }
            
        } catch {
            // Failed to access custom themes directory
            return []
        }
    }
    
    private func loadThemesFromIndividualFiles() async throws -> [Theme] {
        let themeNames = ["basic", "light", "colorful", "futuristic", "nature-glow"]
        var themes: [Theme] = []
        
        for themeName in themeNames {
            if let themeURL = Bundle.main.url(forResource: themeName, withExtension: "json") {
                do {
                    let data = try Data(contentsOf: themeURL)
                    let theme = try JSONDecoder().decode(Theme.self, from: data)
                    do {
                        try validateTheme(theme)
                        themes.append(theme)
                    } catch {
                        // Still add theme but with validation warning
                        themes.append(theme)
                    }
                } catch {
                    // Skip invalid theme files
                    continue
                }
            }
        }
        
        // Always include default theme as fallback
        if themes.isEmpty {
            themes.append(Theme.defaultTheme)
        }
        
        return themes
    }
    
    private func saveCustomTheme(_ theme: Theme, from data: Data) async throws {
        guard let userPath = userThemesPath else {
            throw ThemeError.customThemeDirectoryCreationFailed
        }
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: userPath.path) {
            try fileManager.createDirectory(at: userPath,
                                          withIntermediateDirectories: true)
        }
        
        let themeFile = userPath.appendingPathComponent("\(theme.id).json")
        try data.write(to: themeFile)
    }
    
    private func restoreSavedTheme() async {
        let savedThemeId = userDefaults.string(forKey: currentThemeKey)
        
        if let themeId = savedThemeId,
           let savedTheme = availableThemes.first(where: { $0.id == themeId }) {
            await MainActor.run {
                self.currentTheme = savedTheme
            }
        }
    }
    
    private func updateWindowSize() {
        // Post notification for window size change
        NotificationCenter.default.post(
            name: .themeDidChange,
            object: self,
            userInfo: [
                "theme": currentTheme,
                "windowSize": NSValue(size: NSSize(
                    width: currentTheme.popover.width,
                    height: currentTheme.popover.height
                ))
            ]
        )
    }
    
    private func validateTheme(_ theme: Theme) throws {
        // Validate required fields
        var missingFields: [String] = []
        
        if theme.id.isEmpty { missingFields.append("id") }
        if theme.name.isEmpty { missingFields.append("name") }
        if theme.version.isEmpty { missingFields.append("version") }
        
        if !missingFields.isEmpty {
            throw ThemeError.missingRequiredFields(missingFields)
        }
        
        // Validate colors
        try validateColor(theme.colors.background, name: "background")
        try validateColor(theme.colors.primaryText, name: "primaryText")
        try validateColor(theme.colors.accent, name: "accent")
        
        // Validate popover dimensions
        if theme.popover.width < 200 || theme.popover.width > 600 {
            throw ThemeError.themeValidationFailed("Popover width must be between 200 and 600 pixels")
        }
        
        if theme.popover.height < 400 || theme.popover.height > 800 {
            throw ThemeError.themeValidationFailed("Popover height must be between 400 and 800 pixels")
        }
        
        // Validate grid columns
        if theme.layout.gridColumns < 1 || theme.layout.gridColumns > 3 {
            throw ThemeError.themeValidationFailed("Grid columns must be between 1 and 3")
        }
    }
    
    private func validateColor(_ colorString: String, name: String) throws {
        // Allow system colors
        if colorString.hasPrefix("system.") {
            let validSystemColors = [
                "system.windowBackground",
                "system.controlBackground", 
                "system.labelColor",
                "system.secondaryLabel",
                "system.separatorColor",
                "system.controlAccentColor"
            ]
            if !validSystemColors.contains(colorString) {
                throw ThemeError.invalidColorFormat("\(name): Invalid system color \(colorString)")
            }
            return
        }
        
        // Basic hex color validation
        let hexRegex = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", hexRegex)
        
        if !predicate.evaluate(with: colorString) {
            throw ThemeError.invalidColorFormat("\(name): \(colorString)")
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChange")
}

// MARK: - Color Helper Extension

extension Color {
    init(hex: String) {
        // Handle system colors first
        if hex.hasPrefix("system.") {
            switch hex {
            case "system.windowBackground":
                self.init(NSColor.windowBackgroundColor)
            case "system.controlBackground":
                self.init(NSColor.controlBackgroundColor)
            case "system.labelColor":
                self.init(NSColor.labelColor)
            case "system.secondaryLabel":
                self.init(NSColor.secondaryLabelColor)
            case "system.separatorColor":
                self.init(NSColor.separatorColor)
            case "system.controlAccentColor":
                self.init(NSColor.controlAccentColor)
            default:
                // Fallback to a neutral color if system color not recognized
                self.init(NSColor.windowBackgroundColor)
            }
            return
        }
        
        // Handle hex colors
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Luminance Calculation for Contrast Detection
    
    var luminance: Double {
        guard let cgColor = self.cgColor,
              let colorSpace = cgColor.colorSpace,
              let components = cgColor.components else {
            return 0.0
        }
        
        // Convert to sRGB if needed
        let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let sRGBColor = cgColor.converted(to: sRGBColorSpace, intent: .defaultIntent, options: nil),
              let sRGBComponents = sRGBColor.components else {
            return 0.0
        }
        
        let red = sRGBComponents[0]
        let green = sRGBComponents[1] 
        let blue = sRGBComponents[2]
        
        // Convert to linear RGB
        func sRGBToLinear(_ component: CGFloat) -> CGFloat {
            if component <= 0.03928 {
                return component / 12.92
            } else {
                return pow((component + 0.055) / 1.055, 2.4)
            }
        }
        
        let linearRed = sRGBToLinear(red)
        let linearGreen = sRGBToLinear(green)
        let linearBlue = sRGBToLinear(blue)
        
        // Calculate relative luminance using ITU-R BT.709 coefficients
        return 0.2126 * linearRed + 0.7152 * linearGreen + 0.0722 * linearBlue
    }
}