//
//  View+Theme.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

extension View {
    // MARK: - Themed Background
    
    func themedBackground() -> some View {
        self.background(Color.themedBackground)
    }
    
    func themedCardBackground() -> some View {
        self.background(Color.themedCardBackground)
    }
    
    func themedSecondaryBackground() -> some View {
        self.background(Color.themedSecondaryBackground)
    }
    
    // MARK: - Themed Text Colors
    
    func themedPrimaryText() -> some View {
        self.foregroundColor(.themedPrimaryText)
    }
    
    func themedSecondaryText() -> some View {
        self.foregroundColor(.themedSecondaryText)
    }
    
    func themedAccentText() -> some View {
        self.foregroundColor(.themedAccent)
    }
    
    // MARK: - Themed Card Style
    
    func themedCard() -> some View {
        let cardConfig = ThemeManager.shared.components.cards
        
        return self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cardConfig.cornerRadius)
                    .fill(Color.themedCardBackground)
                    .opacity(cardConfig.backgroundOpacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cardConfig.cornerRadius)
                    .stroke(Color(hex: cardConfig.borderColor), lineWidth: cardConfig.borderWidth)
            )
            .themedCardStyle()
    }
    
    private func themedCardStyle() -> some View {
        let cardConfig = ThemeManager.shared.components.cards
        let effectsConfig = ThemeManager.shared.effects
        
        var view = AnyView(self)
        
        // Apply glow effect if enabled
        if let glowConfig = effectsConfig.glowEffect, glowConfig.enabled {
            view = AnyView(
                view.shadow(
                    color: Color(hex: glowConfig.color).opacity(glowConfig.opacity),
                    radius: glowConfig.radius,
                    x: 0,
                    y: 0
                )
            )
        }
        
        // Apply blur effect if enabled
        if let blurConfig = effectsConfig.cardBlur, blurConfig.enabled {
            view = AnyView(
                view.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cardConfig.cornerRadius))
            )
        }
        
        return view
    }
    
    // MARK: - Themed Button Style
    
    func themedButton(style: ThemedButtonStyle = .primary) -> some View {
        let buttonConfig = ThemeManager.shared.components.buttons
        
        return self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                themedButtonBackground(style: style, config: buttonConfig)
            )
            .cornerRadius(buttonConfig.cornerRadius)
    }
    
    private func themedButtonBackground(style: ThemedButtonStyle, config: ButtonConfiguration) -> some View {
        switch style {
        case .primary:
            return AnyView(Color.themedGradient(.primary))
        case .secondary:
            return AnyView(Color.themedAccentSecondary)
        case .outline:
            return AnyView(
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .stroke(Color.themedAccent, lineWidth: 1)
                    .background(Color.clear)
            )
        }
    }
    
    // MARK: - Themed Hover Effects
    
    func themedHoverEffect() -> some View {
        let cardConfig = ThemeManager.shared.components.cards
        let hoverConfig = cardConfig.hoverEffect
        
        return self.modifier(ThemedHoverEffectModifier(config: hoverConfig))
    }
    
    // MARK: - Themed Animations
    
    @MainActor
    func themedAnimation<V: Equatable>(_ value: V) -> some View {
        let animationConfig = ThemeManager.shared.effects.animations
        
        if let config = animationConfig, config.enabled {
            let animation: Animation
            
            switch config.curve {
            case "easeIn":
                animation = .easeIn(duration: config.duration)
            case "easeOut":
                animation = .easeOut(duration: config.duration)
            case "easeInOut":
                animation = .easeInOut(duration: config.duration)
            case "linear":
                animation = .linear(duration: config.duration)
            case "spring":
                animation = .spring(response: config.duration)
            default:
                animation = .easeInOut(duration: config.duration)
            }
            
            return AnyView(self.animation(animation, value: value))
        }
        
        return AnyView(self)
    }
    
    // MARK: - Themed Window Frame
    
    func themedWindowFrame() -> some View {
        let popoverConfig = ThemeManager.shared.popover
        
        return self
            .frame(
                width: popoverConfig.width,
                height: popoverConfig.height
            )
            .background(Color.themedBackground)
            .cornerRadius(popoverConfig.cornerRadius)
            .themedWindowShadow()
    }
    
    private func themedWindowShadow() -> some View {
        let shadowConfig = ThemeManager.shared.popover.shadow
        
        if let shadow = shadowConfig, shadow.enabled {
            return AnyView(
                self.shadow(
                    color: Color(hex: shadow.color).opacity(shadow.opacity),
                    radius: shadow.radius,
                    x: shadow.offset.x,
                    y: shadow.offset.y
                )
            )
        }
        
        return AnyView(self)
    }
    
    // MARK: - Themed Spacing
    
    func themedCardSpacing() -> some View {
        let spacing = ThemeManager.shared.layout.cardSpacing
        return self.padding(spacing / 2)
    }
    
    func themedSectionSpacing() -> some View {
        let spacing = ThemeManager.shared.layout.sectionSpacing
        return self.padding(.vertical, spacing / 2)
    }
    
    func themedHorizontalPadding() -> some View {
        let padding = ThemeManager.shared.layout.padding.horizontal
        return self.padding(.horizontal, padding)
    }
    
    func themedVerticalPadding() -> some View {
        let padding = ThemeManager.shared.layout.padding.vertical
        return self.padding(.vertical, padding)
    }
    
    func themedLayoutPadding() -> some View {
        let paddingConfig = ThemeManager.shared.layout.padding
        return self.padding(.horizontal, paddingConfig.horizontal)
                  .padding(.vertical, paddingConfig.vertical)
    }
}

// MARK: - Themed Button Style Enum

enum ThemedButtonStyle {
    case primary
    case secondary
    case outline
}

// MARK: - Hover Effect Modifier

struct ThemedHoverEffectModifier: ViewModifier {
    let config: HoverEffectConfiguration?
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(hoveredScale)
            .brightness(hoveredBrightness)
            .themedAnimation(isHovered)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
    }
    
    private var hoveredScale: CGFloat {
        guard let config = config, config.enabled, isHovered else { return 1.0 }
        return config.scale ?? 1.0
    }
    
    private var hoveredBrightness: Double {
        guard let config = config, config.enabled, isHovered else { return 0.0 }
        return (config.brightness ?? 1.0) - 1.0
    }
}

// MARK: - Icon Theme Extensions

extension Image {
    @MainActor
    func themedIcon(size: IconSize = .regular) -> some View {
        let iconConfig = ThemeManager.shared.icons
        let iconSize = iconConfig.size
        
        let fontSize: CGFloat
        switch size {
        case .small:
            fontSize = iconSize.small
        case .regular:
            fontSize = iconSize.regular
        case .large:
            fontSize = iconSize.large
        }
        
        return self
            .font(.system(size: fontSize, weight: iconConfig.weight.swiftUIFontWeight))
            .foregroundColor(Color.themedIconAccent)
    }
    
    @MainActor
    func themedSystemIcon(_ systemName: String, size: IconSize = .regular) -> some View {
        let iconConfig = ThemeManager.shared.icons
        
        // Check for custom mapping first
        let finalSystemName: String
        if let customMappings = iconConfig.customMappings,
           let customName = customMappings[systemName] {
            finalSystemName = customName
        } else {
            finalSystemName = systemName
        }
        
        return Image(systemName: finalSystemName)
            .themedIcon(size: size)
    }
}

extension String {
    var swiftUIFontWeight: Font.Weight {
        switch self.lowercased() {
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

enum IconSize {
    case small, regular, large
}