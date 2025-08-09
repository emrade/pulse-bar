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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Top row: Icon, Title, and Detail
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.primary)
                
                // Title
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Detail (if exists)
                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // Bottom row: Value or button (indented to align with title)
            HStack {
                Spacer()
                    .frame(width: 32) // Space for icon + spacing
                
                if isButton {
                    Button(value) {
                        action?()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Spacer()
                } else {
                    Text(value)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
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