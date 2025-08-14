//
//  ThemeManager.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI
import Foundation
import Combine
import os

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    private let logger = PulseBarLogger.shared
    
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
        let fileName = url.lastPathComponent
        logger.logThemeInfo("Starting theme import from: \(fileName)")
        logger.logSecurityEvent(.themeImportAttempt, details: ["fileName": fileName, "url": url.path])
        
        guard url.startAccessingSecurityScopedResource() else {
            logger.logThemeError("Failed to access security scoped resource: \(fileName)")
            throw ThemeError.fileNotFound(fileName)
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Get file attributes for security validation
        let fileAttributes: [FileAttributeKey: Any]
        do {
            fileAttributes = try fileManager.attributesOfItem(atPath: url.path)
        } catch {
            logger.logThemeError("Failed to read file attributes for: \(fileName)", error: error)
            throw ThemeError.fileNotFound(fileName)
        }
        
        // Validate file size (max 1MB for theme files)
        guard let fileSize = fileAttributes[.size] as? Int64 else {
            logger.logSecurityError("Could not determine file size for: \(fileName)")
            throw ThemeError.invalidThemeStructure("Unable to determine file size")
        }
        
        let maxFileSize: Int64 = 1_048_576 // 1MB
        guard fileSize <= maxFileSize else {
            logger.logSecurityEvent(.invalidFileSize, details: ["fileName": fileName, "size": fileSize, "maxSize": maxFileSize])
            throw ThemeError.invalidThemeStructure("Theme file too large (\(fileSize) bytes, max \(maxFileSize) bytes)")
        }
        
        // Validate file extension
        guard url.pathExtension.lowercased() == "json" else {
            logger.logSecurityEvent(.invalidFileFormat, details: ["fileName": fileName, "extension": url.pathExtension])
            throw ThemeError.invalidThemeStructure("Only JSON files are supported")
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            // Additional validation: ensure data size matches file size for consistency
            guard Int64(data.count) == fileSize else {
                logger.logSecurityError("Data size mismatch for file: \(fileName). Expected: \(fileSize), Got: \(data.count)")
                throw ThemeError.invalidThemeStructure("File integrity check failed")
            }
            
            // Validate JSON structure before theme parsing
            do {
                _ = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                logger.logSecurityEvent(.invalidFileFormat, details: ["fileName": fileName, "error": "Invalid JSON"])
                throw ThemeError.invalidJSON("Invalid JSON format: \(error.localizedDescription)")
            }
            
            let theme = try JSONDecoder().decode(Theme.self, from: data)
            
            // Enhanced theme validation
            var validationErrors: [String] = []
            do {
                try validateThemeSecurely(theme)
            } catch let validationError {
                validationErrors.append(validationError.localizedDescription)
            }
            
            if !validationErrors.isEmpty {
                logger.logThemeFileOperation(operation: "import", fileName: fileName, fileSize: fileSize, success: false, validationErrors: validationErrors)
                throw ThemeError.themeValidationFailed(validationErrors.joined(separator: "; "))
            }
            
            // Save to custom themes directory
            try await saveCustomTheme(theme, from: data)
            
            logger.logThemeFileOperation(operation: "import", fileName: fileName, fileSize: fileSize, success: true)
            logger.logThemeInfo("Successfully imported theme: \(theme.name) (\(theme.id))")
            
            // Reload themes
            await loadThemes()
            
        } catch let error as DecodingError {
            logger.logThemeError("JSON decoding failed for: \(fileName)", error: error)
            throw ThemeError.invalidJSON(error.localizedDescription)
        } catch let error as ThemeError {
            throw error
        } catch {
            logger.logThemeError("Theme import failed for: \(fileName)", error: error)
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
        try validateThemeSecurely(theme)
    }
    
    /// Enhanced secure theme validation with comprehensive security checks
    private func validateThemeSecurely(_ theme: Theme) throws {
        logger.logThemeInfo("Starting theme validation for: \(theme.name) (\(theme.id))")
        
        // Validate required fields with enhanced security checks
        var missingFields: [String] = []
        var securityIssues: [String] = []
        
        if theme.id.isEmpty { 
            missingFields.append("id") 
        } else {
            // Validate theme ID for security (prevent path traversal, etc.)
            if !self.isValidThemeIdentifier(theme.id) {
                securityIssues.append("Theme ID contains invalid characters: \(theme.id)")
            }
        }
        
        if theme.name.isEmpty { 
            missingFields.append("name") 
        } else {
            // Validate theme name length and content
            if theme.name.count > 100 || self.containsSuspiciousContent(theme.name) {
                securityIssues.append("Theme name is invalid or too long: \(theme.name)")
            }
        }
        
        if theme.version.isEmpty { 
            missingFields.append("version") 
        } else {
            // Validate version format
            if !self.isValidVersionString(theme.version) {
                securityIssues.append("Invalid version format: \(theme.version)")
            }
        }
        
        if !missingFields.isEmpty {
            let error = "Missing required fields: \(missingFields.joined(separator: ", "))"
            logger.logSecurityWarning(error)
            throw ThemeError.missingRequiredFields(missingFields)
        }
        
        if !securityIssues.isEmpty {
            let error = "Security validation failed: \(securityIssues.joined(separator: "; "))"
            logger.logSecurityError(error)
            throw ThemeError.themeValidationFailed(error)
        }
        
        // Validate colors with enhanced security
        let colorFields = [
            ("background", theme.colors.background),
            ("primaryText", theme.colors.primaryText),
            ("accent", theme.colors.accent),
            ("secondaryText", theme.colors.secondaryText),
            ("cardBackground", theme.colors.cardBackground)
        ]
        
        for (name, color) in colorFields {
            try validateColorSecurely(color, name: name)
        }
        
        // Validate popover dimensions with stricter bounds
        guard theme.popover.width >= 200 && theme.popover.width <= 600 else {
            let error = "Popover width out of bounds: \(theme.popover.width) (must be 200-600)"
            logger.logSecurityWarning(error)
            throw ThemeError.themeValidationFailed(error)
        }
        
        guard theme.popover.height >= 400 && theme.popover.height <= 800 else {
            let error = "Popover height out of bounds: \(theme.popover.height) (must be 400-800)"
            logger.logSecurityWarning(error)
            throw ThemeError.themeValidationFailed(error)
        }
        
        // Validate grid columns
        guard theme.layout.gridColumns >= 1 && theme.layout.gridColumns <= 3 else {
            let error = "Grid columns out of bounds: \(theme.layout.gridColumns) (must be 1-3)"
            logger.logSecurityWarning(error)
            throw ThemeError.themeValidationFailed(error)
        }
        
        // Validate font configurations
        try self.validateFontConfiguration(theme.fonts)
        
        // Validate numeric properties for reasonable bounds
        try self.validateNumericProperties(theme)
        
        logger.logThemeInfo("Theme validation completed successfully for: \(theme.name)")
    }
    
    private func validateColor(_ colorString: String, name: String) throws {
        try validateColorSecurely(colorString, name: name)
    }
    
    /// Enhanced secure color validation
    private func validateColorSecurely(_ colorString: String, name: String) throws {
        // Input sanitization - check for suspicious content
        guard !self.containsSuspiciousContent(colorString) else {
            let error = "Color \(name) contains suspicious content: \(colorString)"
            logger.logSecurityError(error)
            throw ThemeError.invalidColorFormat(error)
        }
        
        // Length validation to prevent buffer overflow attempts
        guard colorString.count <= 50 else {
            let error = "Color \(name) string too long: \(colorString.count) characters"
            logger.logSecurityError(error)
            throw ThemeError.invalidColorFormat(error)
        }
        
        // Allow system colors with strict validation
        if colorString.hasPrefix("system.") {
            let validSystemColors = [
                "system.windowBackground",
                "system.controlBackground", 
                "system.labelColor",
                "system.secondaryLabel",
                "system.separatorColor",
                "system.controlAccentColor"
            ]
            guard validSystemColors.contains(colorString) else {
                let error = "\(name): Invalid system color \(colorString)"
                logger.logSecurityWarning(error)
                throw ThemeError.invalidColorFormat(error)
            }
            return
        }
        
        // Enhanced hex color validation with strict regex
        let hexRegex = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3}|[A-Fa-f0-9]{8})$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", hexRegex)
        
        guard predicate.evaluate(with: colorString) else {
            let error = "\(name): Invalid color format \(colorString)"
            logger.logSecurityWarning(error)
            throw ThemeError.invalidColorFormat(error)
        }
        
        logger.logThemeInfo("Color validation passed for \(name): \(colorString)")
    }
    
    // MARK: - Security Validation Methods
    
    /// Validates theme identifier for security (prevents path traversal and injection)
    private func isValidThemeIdentifier(_ identifier: String) -> Bool {
        // Theme IDs should be reasonable length and contain only safe characters
        guard identifier.count <= 50,
              identifier.count >= 1,
              identifier.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == ".") }) else {
            return false
        }
        
        // Reject identifiers that could be used for path traversal or injection
        let dangerousPatterns = ["..", "/", "\\\\", ";", "&", "|", "`", "$", "(", ")", "<", ">", "'", "\"", "*", "?", "[", "]"]
        for pattern in dangerousPatterns {
            if identifier.contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    /// Validates version string format
    private func isValidVersionString(_ version: String) -> Bool {
        // Version should follow semantic versioning or simple numeric format
        let versionRegex = "^[0-9]+\\.[0-9]+\\.[0-9]+([\\-+][A-Za-z0-9\\-\\.]+)?$|^[0-9]+\\.[0-9]+$|^[0-9]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", versionRegex)
        return predicate.evaluate(with: version) && version.count <= 20
    }
    
    /// Checks for suspicious content that might indicate injection attempts
    private func containsSuspiciousContent(_ text: String) -> Bool {
        let suspiciousPatterns = [
            "<script", "</script>", "javascript:", "data:", "file:",
            "\\x", "%", "\\u", "\\n", "\\r", "\\t",
            "${", "#{", "{{"  // Template injection patterns
        ]
        
        let lowercaseText = text.lowercased()
        for pattern in suspiciousPatterns {
            if lowercaseText.contains(pattern.lowercased()) {
                return true
            }
        }
        
        return false
    }
    
    /// Validates font configuration for security
    private func validateFontConfiguration(_ fonts: FontConfiguration) throws {
        let fontConfigs = [fonts.headline, fonts.subheadline, fonts.title, fonts.body, fonts.caption, fonts.footnote]
        var fontNames: [String] = fontConfigs.map { $0.family }
        
        if let monospaceFont = fonts.monospace {
            fontNames.append(monospaceFont.family)
        }
        
        for fontName in fontNames {
            guard fontName.count <= 100,
                  !self.containsSuspiciousContent(fontName),
                  fontName.allSatisfy({ $0.isASCII || $0.isLetter || $0.isNumber || $0.isWhitespace || $0 == "-" || $0 == "_" }) else {
                let error = "Invalid font name: \(fontName)"
                logger.logSecurityWarning(error)
                throw ThemeError.themeValidationFailed(error)
            }
        }
    }
    
    /// Validates numeric properties to prevent unrealistic values
    private func validateNumericProperties(_ theme: Theme) throws {
        // Validate font sizes
        let fontSizes = [theme.fonts.headline.size, theme.fonts.subheadline.size, theme.fonts.title.size, 
                        theme.fonts.body.size, theme.fonts.caption.size, theme.fonts.footnote.size]
        
        for fontSize in fontSizes {
            guard fontSize >= 8.0 && fontSize <= 72.0 else {
                let error = "Font size out of bounds: \(fontSize) (must be 8-72)"
                logger.logSecurityWarning(error)
                throw ThemeError.themeValidationFailed(error)
            }
        }
        
        // Validate corner radius from cards configuration
        let cornerRadius = theme.components.cards.cornerRadius
        guard cornerRadius >= 0.0 && cornerRadius <= 50.0 else {
            let error = "Corner radius out of bounds: \(cornerRadius) (must be 0-50)"
            logger.logSecurityWarning(error)
            throw ThemeError.themeValidationFailed(error)
        }
        
        // Validate spacing values
        let paddingHorizontal = theme.layout.padding.horizontal
        let paddingVertical = theme.layout.padding.vertical
        
        guard paddingHorizontal >= 0.0 && paddingHorizontal <= 100.0 else {
            let error = "Horizontal padding out of bounds: \(paddingHorizontal) (must be 0-100)"
            logger.logSecurityWarning(error)
            throw ThemeError.themeValidationFailed(error)
        }
        
        guard paddingVertical >= 0.0 && paddingVertical <= 100.0 else {
            let error = "Vertical padding out of bounds: \(paddingVertical) (must be 0-100)"
            logger.logSecurityWarning(error)
            throw ThemeError.themeValidationFailed(error)
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
              let _ = cgColor.colorSpace,
              let _ = cgColor.components else {
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