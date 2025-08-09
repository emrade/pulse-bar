//
//  MetricRowView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import SwiftUI

struct MetricRowView: View {
    let icon: String
    let title: String
    let value: String
    let detail: String?
    var isButton: Bool = false
    var action: (() -> Void)? = nil
    var showInfoButton: Bool = false
    var infoContent: String? = nil
    var secondaryButtonText: String? = nil
    var secondaryAction: (() -> Void)? = nil
    
    @State private var showingInfoPopover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Top row: Icon, Title, Info Button, and Detail
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.primary)
                
                // Title
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                // Info button (if enabled)
                if showInfoButton {
                    Button(action: {
                        showingInfoPopover = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingInfoPopover) {
                        if let infoContent = infoContent {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(infoContent)
                                    .font(.system(size: 13))
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(16)
                            .frame(maxWidth: 300)
                        }
                    }
                }
                
                Spacer()
                
                // Detail (if exists)
                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // Bottom row: Value and/or buttons (indented to align with title)
            HStack {
                Spacer()
                    .frame(width: 32) // Space for icon + spacing
                
                if isButton {
                    HStack(spacing: 8) {
                        Button(value) {
                            action?()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        // Secondary button (if exists)
                        if let secondaryButtonText = secondaryButtonText {
                            Button(secondaryButtonText) {
                                secondaryAction?()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(value)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Secondary button below value (if exists)
                        if let secondaryButtonText = secondaryButtonText {
                            Button(secondaryButtonText) {
                                secondaryAction?()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.clear)
        .cornerRadius(6)
    }
}

#Preview {
    VStack {
        MetricRowView(
            icon: "cpu",
            title: "CPU",
            value: "12%",
            detail: "8 cores"
        )
        
        MetricRowView(
            icon: "network",
            title: "Network",
            value: "Test Speed",
            detail: nil,
            isButton: true
        )
    }
    .padding()
}