//
//  ThemePreview.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

struct ThemePreview: View {
    let theme: Theme
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Mini popover preview
            previewCard
            
            // Theme name
            Text(theme.name)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .lineLimit(1)
            
            // Theme description
            Text(theme.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 140)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                .stroke(
                    isSelected ? Color.accentColor : Color.clear,
                    lineWidth: isSelected ? 2 : 0
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    @ViewBuilder
    private var previewCard: some View {
        RoundedRectangle(cornerRadius: theme.popover.cornerRadius / 2)
            .fill(Color(hex: theme.colors.background))
            .frame(width: 120, height: 80)
            .overlay(
                VStack(spacing: 4) {
                    // Sample header
                    HStack {
                        Circle()
                            .fill(Color(hex: theme.colors.accent))
                            .frame(width: 8, height: 8)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: theme.colors.primaryText))
                            .frame(width: 40, height: 4)
                        
                        Spacer()
                    }
                    
                    // Sample system info card
                    RoundedRectangle(cornerRadius: 4)
                        .overlay(previewSystemInfoBackground)
                        .frame(height: 16)
                        .overlay(
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color(hex: theme.colors.accent))
                                    .frame(width: 3, height: 3)
                                
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color(hex: theme.colors.primaryText).opacity(0.7))
                                    .frame(width: 20, height: 2)
                                
                                Spacer()
                            }
                            .padding(2)
                        )
                    
                    // Sample metric cards
                    HStack(spacing: 4) {
                        ForEach(0..<2, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .overlay(previewCardBackground(index: index))
                                .frame(height: 20)
                                .overlay(
                                    VStack(spacing: 1) {
                                        Circle()
                                            .fill(Color(hex: theme.colors.accent))
                                            .frame(width: 2, height: 2)
                                        
                                        RoundedRectangle(cornerRadius: 0.5)
                                            .fill(Color(hex: theme.colors.secondaryText))
                                            .frame(width: 12, height: 1)
                                    }
                                )
                        }
                    }
                }
                .padding(6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.popover.cornerRadius / 2)
                    .stroke(
                        Color(hex: theme.colors.divider),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: previewShadowColor,
                radius: 2,
                x: 0,
                y: 1
            )
    }
    
    @ViewBuilder
    private var previewSystemInfoBackground: some View {
        if let systemInfoConfig = theme.components.systemInfoCard,
           let gradientColors = systemInfoConfig.backgroundGradient {
            LinearGradient(
                gradient: Gradient(colors: gradientColors.map { Color(hex: $0) }),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color(hex: theme.colors.cardBackground)
        }
    }
    
    private func previewCardBackground(index: Int) -> some View {
        let cardStyle = theme.components.cards.style
        
        switch cardStyle.lowercased() {
        case "gradient":
            if let gradientColors = theme.colors.gradient?.primary {
                return AnyView(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors.map { Color(hex: $0) }),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.8)
                )
            }
            fallthrough
        case "glass":
            return AnyView(
                Color(hex: theme.colors.cardBackground)
                    .opacity(theme.components.cards.backgroundOpacity * 0.8)
            )
        case "nature":
            return AnyView(
                Color(hex: theme.colors.cardBackground)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: theme.colors.accent).opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        default:
            return AnyView(Color(hex: theme.colors.cardBackground))
        }
    }
    
    private var previewShadowColor: Color {
        if let shadowConfig = theme.popover.shadow,
           shadowConfig.enabled {
            return Color(hex: shadowConfig.color).opacity(shadowConfig.opacity * 0.5)
        }
        return Color.black.opacity(0.1)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        ThemePreview(
            theme: Theme.defaultTheme,
            isSelected: true,
            onSelect: {}
        )
        
        ThemePreview(
            theme: Theme.defaultTheme,
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
    .background(Color(.windowBackgroundColor))
}