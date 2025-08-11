//
//  Color+Theme.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

extension Color {
    // MARK: - Themed Color Accessors
    
    @MainActor
    static func themed(_ keyPath: KeyPath<ColorConfiguration, String>) -> Color {
        return Color(hex: ThemeManager.shared.colors[keyPath: keyPath])
    }
    
    @MainActor
    static func themedOptional(_ keyPath: KeyPath<ColorConfiguration, String?>, 
                              fallback: KeyPath<ColorConfiguration, String>) -> Color {
        let colorConfig = ThemeManager.shared.colors
        if let colorString = colorConfig[keyPath: keyPath] {
            return Color(hex: colorString)
        }
        return Color(hex: colorConfig[keyPath: fallback])
    }
    
    // MARK: - Common Themed Colors
    
    @MainActor
    static var themedBackground: Color {
        Color.themed(\.background)
    }
    
    @MainActor
    static var themedSecondaryBackground: Color {
        Color.themed(\.secondaryBackground)
    }
    
    @MainActor
    static var themedCardBackground: Color {
        Color.themed(\.cardBackground)
    }
    
    @MainActor
    static var themedPrimaryText: Color {
        Color.themed(\.primaryText)
    }
    
    @MainActor
    static var themedSecondaryText: Color {
        Color.themed(\.secondaryText)
    }
    
    @MainActor
    static var themedAccent: Color {
        Color.themed(\.accent)
    }
    
    @MainActor
    static var themedAccentSecondary: Color {
        Color.themedOptional(\.accentSecondary, fallback: \.accent)
    }
    
    @MainActor
    static var themedSuccess: Color {
        Color.themedOptional(\.success, fallback: \.accent)
    }
    
    @MainActor
    static var themedWarning: Color {
        Color.themedOptional(\.warning, fallback: \.accent)
    }
    
    @MainActor
    static var themedError: Color {
        Color.themedOptional(\.error, fallback: \.accent)
    }
    
    @MainActor
    static var themedDivider: Color {
        Color.themed(\.divider)
    }
    
    // MARK: - Gradient Colors
    
    @MainActor
    static func themedGradient(_ type: GradientType) -> LinearGradient {
        let gradientConfig = ThemeManager.shared.colors.gradient
        
        let colors: [String]
        switch type {
        case .primary:
            colors = gradientConfig?.primary ?? [ThemeManager.shared.colors.accent, ThemeManager.shared.colors.accent]
        case .secondary:
            colors = gradientConfig?.secondary ?? [ThemeManager.shared.colors.cardBackground, ThemeManager.shared.colors.secondaryBackground]
        case .accent:
            colors = gradientConfig?.accent ?? [ThemeManager.shared.colors.accent, ThemeManager.shared.colors.accent]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: colors.map { Color(hex: $0) }),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    enum GradientType {
        case primary, secondary, accent
    }
    
    // MARK: - Dynamic Color Variations
    
    func themedOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
    
    func themedBrightness(_ brightness: Double) -> some View {
        return self.brightness(brightness)
    }
    
    // MARK: - Icon Accent Color
    
    @MainActor
    static var themedIconAccent: Color {
        Color(hex: ThemeManager.shared.icons.accentColor)
    }
    
    // MARK: - Glow Effect Color
    
    @MainActor
    static var themedGlow: Color {
        if let glowConfig = ThemeManager.shared.effects.glowEffect,
           glowConfig.enabled {
            return Color(hex: glowConfig.color)
        }
        return Color.themedAccent
    }
}