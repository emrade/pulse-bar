//
//  ThemedSystemInfoCard.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

struct ThemedSystemInfoCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let systemInfo = SystemInfoService.shared
    
    var body: some View {
        ThemedCard(style: systemInfoCardStyle) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with computer icon and name
                HStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .themedIcon(size: .regular)
                    
                    Text(systemInfo.computerName)
                        .themedFont(.primary, size: .large)
                        .themedPrimaryText()
                    
                    Spacer()
                }
                
                // System specs in a grid
                HStack(spacing: 16) {
                    // Left column
                    VStack(alignment: .leading, spacing: 8) {
                        systemInfoRow(label: "Chip", value: systemInfo.chipName)
                        systemInfoRow(label: "Memory", value: systemInfo.totalMemory)
                    }
                    
                    Spacer()
                    
                    // Right column  
                    VStack(alignment: .leading, spacing: 8) {
                        systemInfoRow(label: "Model", value: systemInfo.deviceModel)
                        systemInfoRow(label: "OS", value: systemInfo.macOSVersion)
                    }
                }
            }
        }
        .frame(height: systemInfoCardHeight)
        .modifier(ThemedSystemInfoEffectModifier())
    }
    
    @ViewBuilder
    private func systemInfoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .themedFont(.primary, size: .small)
                .themedSecondaryText()
            
            Text(value)
                .themedFont(.primary, size: .small)
                .themedPrimaryText()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    private var systemInfoCardStyle: ThemedCardStyle {
        guard let cardConfig = themeManager.components.systemInfoCard else {
            return .auto
        }
        
        return ThemedCardStyle.from(string: cardConfig.style)
    }
    
    private var systemInfoCardHeight: CGFloat? {
        return themeManager.components.systemInfoCard?.height
    }
    
}

// MARK: - Themed System Info Effect Modifier

struct ThemedSystemInfoEffectModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        let cardConfig = themeManager.components.systemInfoCard
        
        if cardConfig?.borderGlow == true,
           let glowConfig = themeManager.effects.glowEffect,
           glowConfig.enabled {
            content.overlay(
                RoundedRectangle(cornerRadius: themeManager.components.cards.cornerRadius)
                    .stroke(
                        Color(hex: glowConfig.color).opacity(glowConfig.opacity * 0.5),
                        lineWidth: 2
                    )
                    .blur(radius: 2)
            )
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    ThemedSystemInfoCard()
        .environmentObject(ThemeManager.shared)
        .themedBackground()
        .themedLayoutPadding()
}