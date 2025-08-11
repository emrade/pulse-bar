//
//  ThemedCard.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

struct ThemedCard<Content: View>: View {
    let content: Content
    let style: ThemedCardStyle
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovered = false
    
    init(style: ThemedCardStyle = .auto, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.style = style
    }
    
    var body: some View {
        content
            .padding()
            .background(cardBackground)
            .overlay(cardBorder)
            .cornerRadius(themeManager.components.cards.cornerRadius)
            .themedHoverEffect()
            .modifier(ThemedGlowEffectModifier())
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        let cardConfig = themeManager.components.cards
        
        switch resolvedStyle {
        case .auto:
            Color.themedCardBackground
                .opacity(cardConfig.backgroundOpacity)
            
        case .standard:
            Color.themedCardBackground
                .opacity(cardConfig.backgroundOpacity)
        
        case .glass:
            if themeManager.effects.cardBlur?.enabled == true {
                Color.themedCardBackground
                    .opacity(cardConfig.backgroundOpacity)
                    .background(.ultraThinMaterial)
            } else {
                Color.themedCardBackground
                    .opacity(cardConfig.backgroundOpacity * 0.8)
            }
        
        case .gradient:
            if let gradientColors = themeManager.components.systemInfoCard?.backgroundGradient {
                LinearGradient(
                    gradient: Gradient(colors: gradientColors.map { Color(hex: $0) }),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.themedGradient(.primary)
            }
        
        case .nature:
            Color.themedCardBackground
                .opacity(cardConfig.backgroundOpacity)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.themedSuccess.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    @ViewBuilder
    private var cardBorder: some View {
        let cardConfig = themeManager.components.cards
        
        if cardConfig.borderWidth > 0 {
            RoundedRectangle(cornerRadius: cardConfig.cornerRadius)
                .stroke(
                    Color(hex: cardConfig.borderColor),
                    lineWidth: cardConfig.borderWidth
                )
        }
    }
    
    
    private var resolvedStyle: ThemedCardStyle {
        switch style {
        case .auto:
            return ThemedCardStyle.from(string: themeManager.components.cards.style)
        case .standard, .glass, .gradient, .nature:
            return style
        }
    }
}

enum ThemedCardStyle {
    case auto
    case standard
    case glass
    case gradient
    case nature
    
    static func from(string: String) -> ThemedCardStyle {
        switch string.lowercased() {
        case "glass": return .glass
        case "gradient": return .gradient
        case "nature": return .nature
        default: return .standard
        }
    }
}

// MARK: - Themed Glow Effect Modifier

struct ThemedGlowEffectModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        if let glowConfig = themeManager.effects.glowEffect,
           glowConfig.enabled {
            content.shadow(
                color: Color(hex: glowConfig.color).opacity(glowConfig.opacity),
                radius: glowConfig.radius,
                x: 0,
                y: 0
            )
        } else {
            content
        }
    }
}