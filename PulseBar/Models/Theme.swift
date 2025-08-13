//
//  Theme.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI
import Foundation

// MARK: - Main Theme Structure

struct Theme: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let version: String
    let author: String?
    
    let popover: PopoverConfiguration
    let layout: LayoutConfiguration
    let colors: ColorConfiguration
    let fonts: FontConfiguration
    let icons: IconConfiguration
    let effects: EffectConfiguration
    let components: ComponentConfiguration
    
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        return lhs.id == rhs.id && lhs.version == rhs.version
    }
}

// MARK: - Configuration Structures

struct PopoverConfiguration: Codable {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let shadow: ShadowConfiguration?
    
    enum CodingKeys: String, CodingKey {
        case width, height, cornerRadius, shadow
    }
}

struct ShadowConfiguration: Codable {
    let enabled: Bool
    let color: String
    let opacity: Double
    let radius: CGFloat
    let offset: OffsetConfiguration
}

struct OffsetConfiguration: Codable {
    let x: CGFloat
    let y: CGFloat
}

struct LayoutConfiguration: Codable {
    let gridColumns: Int
    let cardSpacing: CGFloat
    let sectionSpacing: CGFloat
    let padding: PaddingConfiguration
}

struct PaddingConfiguration: Codable {
    let horizontal: CGFloat
    let vertical: CGFloat
}

struct ColorConfiguration: Codable {
    let background: String
    let secondaryBackground: String
    let cardBackground: String
    let primaryText: String
    let secondaryText: String
    let accent: String
    let accentSecondary: String?
    let success: String?
    let warning: String?
    let error: String?
    let divider: String
    let gradient: GradientConfiguration?
    
    // NEW: Semantic colors for better light theme support
    let surface: String?           // Card/tile backgrounds
    let onSurface: String?         // Text on surface
    let outline: String?           // Border/divider colors
    let surfaceVariant: String?    // Secondary surfaces
    let onSurfaceVariant: String?  // Text on surface variants
    
    // NEW: Smart contrast detection
    let preferredContrast: String? // "high", "medium", "low" - for text visibility
    let adaptiveText: Bool?        // Auto-calculate text colors based on background luminance
}

struct GradientConfiguration: Codable {
    let primary: [String]
    let secondary: [String]?
    let accent: [String]?
}

struct FontConfiguration: Codable {
    // Semantic font styles (matches SwiftUI text styles)
    let headline: SemanticFontConfiguration         // Large, bold text for headings
    let subheadline: SemanticFontConfiguration      // Smaller headings
    let title: SemanticFontConfiguration            // Main titles
    let body: SemanticFontConfiguration             // Regular body text
    let caption: SemanticFontConfiguration          // Small text, labels
    let footnote: SemanticFontConfiguration         // Very small text
    let monospace: SemanticFontConfiguration?       // Code/monospace text
}

struct SemanticFontConfiguration: Codable {
    let family: String
    let weight: String
    let size: CGFloat
}

struct IconConfiguration: Codable {
    let style: String
    let weight: String
    let accentColor: String
    let size: IconSizeConfiguration
    let customMappings: [String: String]?
}

struct IconSizeConfiguration: Codable {
    let small: CGFloat
    let regular: CGFloat
    let large: CGFloat
}

struct EffectConfiguration: Codable {
    let backgroundBlur: BlurConfiguration?
    let cardBlur: BlurConfiguration?
    let animations: AnimationConfiguration?
    let glowEffect: GlowConfiguration?
}

struct BlurConfiguration: Codable {
    let enabled: Bool
    let radius: CGFloat
    let saturation: Double?
}

struct AnimationConfiguration: Codable {
    let enabled: Bool
    let duration: Double
    let curve: String
}

struct GlowConfiguration: Codable {
    let enabled: Bool
    let color: String
    let radius: CGFloat
    let opacity: Double
}

struct ComponentConfiguration: Codable {
    let cards: CardConfiguration
    let buttons: ButtonConfiguration
    let systemInfoCard: SystemInfoCardConfiguration?
}

struct CardConfiguration: Codable {
    let style: String
    let borderWidth: CGFloat
    let borderColor: String
    let cornerRadius: CGFloat
    let backgroundOpacity: Double
    let hoverEffect: HoverEffectConfiguration?
}

struct ButtonConfiguration: Codable {
    let style: String
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let hoverEffect: HoverEffectConfiguration?
}

struct SystemInfoCardConfiguration: Codable {
    let style: String
    let height: CGFloat?
    let backgroundGradient: [String]?
    let borderGlow: Bool?
}

struct HoverEffectConfiguration: Codable {
    let enabled: Bool
    let scale: Double?
    let glowIntensity: Double?
    let brightness: Double?
}

// MARK: - Theme Extensions

extension Theme {
    static var defaultTheme: Theme {
        return Theme(
            id: "basic",
            name: "Basic",
            description: "Clean, minimal theme using native system colors",
            version: "1.0.0",
            author: "PulseBar Team",
            popover: PopoverConfiguration(
                width: 360,
                height: 700,
                cornerRadius: 12,
                shadow: ShadowConfiguration(
                    enabled: true,
                    color: "#000000",
                    opacity: 0.2,
                    radius: 10,
                    offset: OffsetConfiguration(x: 0, y: 5)
                )
            ),
            layout: LayoutConfiguration(
                gridColumns: 2,
                cardSpacing: 10,
                sectionSpacing: 10,
                padding: PaddingConfiguration(horizontal: 10, vertical: 12)
            ),
            colors: ColorConfiguration(
                background: "system.windowBackground",
                secondaryBackground: "system.controlBackground",
                cardBackground: "system.controlBackground",
                primaryText: "system.labelColor",
                secondaryText: "system.secondaryLabel",
                accent: "#007AFF",
                accentSecondary: "#5856D6",
                success: "#30D158",
                warning: "#FF9F0A",
                error: "#FF453A",
                divider: "system.separatorColor",
                gradient: nil,
                surface: nil,
                onSurface: nil,
                outline: nil,
                surfaceVariant: nil,
                onSurfaceVariant: nil,
                preferredContrast: nil,
                adaptiveText: nil
            ),
            fonts: FontConfiguration(
                headline: SemanticFontConfiguration(family: "system", weight: "semibold", size: 17),
                subheadline: SemanticFontConfiguration(family: "system", weight: "regular", size: 15),
                title: SemanticFontConfiguration(family: "system", weight: "regular", size: 28),
                body: SemanticFontConfiguration(family: "system", weight: "regular", size: 17),
                caption: SemanticFontConfiguration(family: "system", weight: "regular", size: 12),
                footnote: SemanticFontConfiguration(family: "system", weight: "regular", size: 13),
                monospace: SemanticFontConfiguration(family: "system-monospace", weight: "regular", size: 13)
            ),
            icons: IconConfiguration(
                style: "fill",
                weight: "medium",
                accentColor: "#007AFF",
                size: IconSizeConfiguration(
                    small: 14,
                    regular: 16,
                    large: 20
                ),
                customMappings: nil
            ),
            effects: EffectConfiguration(
                backgroundBlur: BlurConfiguration(
                    enabled: false,
                    radius: 0,
                    saturation: 1.0
                ),
                cardBlur: nil,
                animations: AnimationConfiguration(
                    enabled: true,
                    duration: 0.2,
                    curve: "easeInOut"
                ),
                glowEffect: GlowConfiguration(
                    enabled: false,
                    color: "#007AFF",
                    radius: 0,
                    opacity: 0.0
                )
            ),
            components: ComponentConfiguration(
                cards: CardConfiguration(
                    style: "standard",
                    borderWidth: 0.5,
                    borderColor: "system.separatorColor",
                    cornerRadius: 8,
                    backgroundOpacity: 1.0,
                    hoverEffect: HoverEffectConfiguration(
                        enabled: true,
                        scale: 1.02,
                        glowIntensity: nil,
                        brightness: 1.05
                    )
                ),
                buttons: ButtonConfiguration(
                    style: "standard",
                    cornerRadius: 6,
                    borderWidth: 0,
                    hoverEffect: HoverEffectConfiguration(
                        enabled: true,
                        scale: nil,
                        glowIntensity: nil,
                        brightness: 1.1
                    )
                ),
                systemInfoCard: SystemInfoCardConfiguration(
                    style: "standard",
                    height: nil,
                    backgroundGradient: nil,
                    borderGlow: false
                )
            )
        )
    }
}

// MARK: - Helper Extensions

extension SemanticFontConfiguration {
    var swiftUIWeight: Font.Weight {
        switch weight.lowercased() {
        case "ultralight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .medium
        }
    }
}

// MARK: - ColorConfiguration Extensions

extension ColorConfiguration {
    var computedSurface: String {
        return surface ?? cardBackground
    }
    
    var computedOnSurface: String {
        if let onSurface = onSurface {
            return onSurface
        }
        
        // Smart text color calculation based on surface luminance
        if adaptiveText == true {
            return calculateContrastingTextColor(for: computedSurface)
        }
        
        return primaryText // Fallback to theme's primary text
    }
    
    var computedSurfaceVariant: String {
        return surfaceVariant ?? secondaryBackground
    }
    
    var computedOnSurfaceVariant: String {
        if let onSurfaceVariant = onSurfaceVariant {
            return onSurfaceVariant
        }
        
        if adaptiveText == true {
            return calculateContrastingTextColor(for: computedSurfaceVariant)
        }
        
        return secondaryText
    }
    
    var computedOutline: String {
        return outline ?? divider
    }
    
    private func calculateContrastingTextColor(for backgroundHex: String) -> String {
        let backgroundLuminance = calculateLuminance(from: backgroundHex)
        
        // Use WCAG contrast guidelines
        // For high contrast preference, use pure black/white
        if preferredContrast == "high" {
            return backgroundLuminance > 0.5 ? "#000000" : "#FFFFFF"
        }
        
        // For medium contrast, use slightly softer colors
        if preferredContrast == "medium" {
            return backgroundLuminance > 0.5 ? "#1C1C1E" : "#F2F2F7"
        }
        
        // For low contrast or default, use theme colors
        return backgroundLuminance > 0.5 ? primaryText : "#FFFFFF"
    }
    
    private func calculateLuminance(from hexString: String) -> Double {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return 0.0
        }
        
        let red = Double(r) / 255.0
        let green = Double(g) / 255.0
        let blue = Double(b) / 255.0
        
        // Convert to linear RGB
        func sRGBToLinear(_ component: Double) -> Double {
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