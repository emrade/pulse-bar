//
//  FontLoader.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import Foundation
import CoreText
import SwiftUI

/// Utility class for loading bundled fonts at runtime
class FontLoader {
    static let shared = FontLoader()
    
    private var loadedFonts: Set<String> = []
    private var fontFamilyNames: [String: String] = [:]
    
    private init() {
        loadBundledFonts()
    }
    
    /// Load all bundled fonts from the app bundle
    private func loadBundledFonts() {
        let fontNames = [
            "Rajdhani-Regular.ttf",
            "Rajdhani-Medium.ttf", 
            "Orbitron-Variable.ttf",
            "NunitoSans-Variable.ttf",
            "Baloo2-Variable.ttf",
            "Lato-Regular.ttf",
            "MerriweatherSans-Variable.ttf"
        ]
        
        for fontName in fontNames {
            loadFont(named: fontName)
        }
        
    }
    
    /// Load a specific font file from the app bundle
    private func loadFont(named fontFileName: String) {
        // First, try to find the font in the bundle
        let fontName = fontFileName.replacingOccurrences(of: ".ttf", with: "")
        
        // Try multiple possible locations for the font file
        var fontURL: URL?
        
        // Try direct resource lookup
        if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
            fontURL = url
        }
        // Try in Resources subfolder
        else if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf", subdirectory: "Resources") {
            fontURL = url
        }
        // Try in Fonts subfolder
        else if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf", subdirectory: "Fonts") {
            fontURL = url
        }
        
        guard let url = fontURL else {
            return
        }
        
        // Try to register the font using the appropriate API
        if #available(macOS 13.0, *) {
            // Use newer API
            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if !success {
                return
            }
        } else {
            // Fallback for older macOS versions
            guard let fontDataProvider = CGDataProvider(url: url as CFURL),
                  let font = CGFont(fontDataProvider) else {
                return
            }
            
            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterGraphicsFont(font, &error)
            
            if !success {
                return
            }
        }
        
        loadedFonts.insert(fontFileName)
        
        // Get font info for family name mapping
        if let fontDataProvider = CGDataProvider(url: url as CFURL),
           let font = CGFont(fontDataProvider),
           let familyName = font.fullName as String? {
            fontFamilyNames[fontFileName] = familyName
        }
    }
    
    /// Check if a font family is available
    func isFontAvailable(_ familyName: String) -> Bool {
        let availableFamilies = NSFontManager.shared.availableFontFamilies
        return availableFamilies.contains(familyName) || fontFamilyNames.values.contains(familyName)
    }
    
    /// Get the actual font family name for a requested font
    func getFontFamilyName(for requestedName: String) -> String {
        // Handle variable fonts
        switch requestedName.lowercased() {
        case "rajdhani":
            return isFontAvailable("Rajdhani") ? "Rajdhani" : "SF Pro Display"
        case "orbitron":
            return isFontAvailable("Orbitron") ? "Orbitron" : "SF Pro Display"
        case "nunito sans":
            return isFontAvailable("Nunito Sans") ? "Nunito Sans" : "SF Pro Display"
        case "baloo 2":
            return isFontAvailable("Baloo 2") ? "Baloo 2" : "SF Pro Display"
        case "lato":
            return isFontAvailable("Lato") ? "Lato" : "SF Pro Display"
        case "merriweather sans":
            return isFontAvailable("Merriweather Sans") ? "Merriweather Sans" : "SF Pro Display"
        default:
            return requestedName
        }
    }
    
    /// Get all loaded bundled fonts
    var loadedBundledFonts: Set<String> {
        return loadedFonts
    }
    
    /// Get all available font families (system + bundled)
    var availableFontFamilies: [String] {
        let systemFonts = NSFontManager.shared.availableFontFamilies
        let bundledFonts = Array(fontFamilyNames.values)
        return Array(Set(systemFonts + bundledFonts)).sorted()
    }
}

// MARK: - Font Extension for Bundle Loading

extension Font {
    /// Create a font using the FontLoader to ensure bundled fonts are available
    static func bundledFont(family: String, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let actualFamily = FontLoader.shared.getFontFamilyName(for: family)
        return .custom(actualFamily, size: size).weight(weight)
    }
}