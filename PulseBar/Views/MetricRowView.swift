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
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.primary)
            
            // Title and detail
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Value or button
            if isButton {
                Button(value) {
                    action?()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
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