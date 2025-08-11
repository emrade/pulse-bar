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
}

struct GradientConfiguration: Codable {
    let primary: [String]
    let secondary: [String]?
    let accent: [String]?
}

struct FontConfiguration: Codable {
    let primary: FontStyleConfiguration
    let monospace: FontStyleConfiguration?
}

struct FontStyleConfiguration: Codable {
    let family: String
    let weight: String
    let size: FontSizeConfiguration
}

struct FontSizeConfiguration: Codable {
    let small: CGFloat
    let regular: CGFloat
    let large: CGFloat
    let title: CGFloat
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
                cardSpacing: 12,
                sectionSpacing: 16,
                padding: PaddingConfiguration(horizontal: 16, vertical: 16)
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
                gradient: nil
            ),
            fonts: FontConfiguration(
                primary: FontStyleConfiguration(
                    family: "SF Pro Display",
                    weight: "medium",
                    size: FontSizeConfiguration(
                        small: 11,
                        regular: 13,
                        large: 16,
                        title: 18
                    )
                ),
                monospace: FontStyleConfiguration(
                    family: "SF Mono",
                    weight: "regular",
                    size: FontSizeConfiguration(
                        small: 10,
                        regular: 12,
                        large: 14,
                        title: 16
                    )
                )
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

extension FontStyleConfiguration {
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

extension FontSizeConfiguration {
    func value(for size: ThemedFontSize) -> CGFloat {
        switch size {
        case .small: return small
        case .regular: return regular
        case .large: return large
        case .title: return title
        }
    }
}

enum ThemedFontSize {
    case small, regular, large, title
}

enum ThemedFontStyle {
    case primary, monospace
}