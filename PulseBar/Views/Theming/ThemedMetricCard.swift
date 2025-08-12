//
//  ThemedMetricCard.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

struct ThemedMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let detail: String?
    let onTap: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
    
    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and title row - exact match to original
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: icon)
                    .font(.themedLarge)
                    .foregroundColor(.accentColor)
                    .frame(width: 20, height: 20, alignment: .center)
                
                Text(title)
                    .themedFont(.primary, size: .extraSmall)
                    .themedSurfaceText()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
            
            // Value and detail - exact match to original
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .themedFont(.primary, size: .extraSmall)
                    .themedSurfaceVariantText()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
                
                if let detail = detail {
                    Text(detail)
                        .themedFont(.primary, size: .extraSmall)
                        .themedSurfaceVariantText()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .padding(12)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.themedCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.themedDivider.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        )
        .overlay(
            // Hover effect
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlAccentColor).opacity(isHovered ? 0.1 : 0))
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        )
    }
    
}

// MARK: - Preview

#Preview {
    VStack {
        ThemedMetricCard(
            icon: "cpu",
            title: "CPU",
            value: "45%",
            detail: "4 cores",
            onTap: {}
        )
        
        ThemedMetricCard(
            icon: "memorychip",
            title: "Memory",
            value: "8.2 GB",
            detail: "16 GB total",
            onTap: {}
        )
    }
    .environmentObject(ThemeManager.shared)
    .themedBackground()
    .themedLayoutPadding()
}