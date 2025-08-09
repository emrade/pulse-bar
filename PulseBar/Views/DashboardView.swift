//
//  DashboardView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.blue)
                Text("PulseBar")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            // Metric rows (placeholders for now)
            VStack(spacing: 8) {
                MetricRowView(
                    icon: "cpu",
                    title: "CPU",
                    value: "Loading...",
                    detail: nil
                )
                
                MetricRowView(
                    icon: "memorychip",
                    title: "Memory",
                    value: "Loading...",
                    detail: "16 GB"
                )
                
                MetricRowView(
                    icon: "internaldrive",
                    title: "Storage",
                    value: "Loading...",
                    detail: "512 GB SSD"
                )
                
                MetricRowView(
                    icon: "battery.100",
                    title: "Battery",
                    value: "Loading...",
                    detail: nil
                )
                
                MetricRowView(
                    icon: "wifi",
                    title: "Wi-Fi",
                    value: "Loading...",
                    detail: nil
                )
                
                MetricRowView(
                    icon: "network",
                    title: "Network",
                    value: "Test Speed",
                    detail: nil,
                    isButton: true
                )
                
                MetricRowView(
                    icon: "externaldrive.connected.to.line.below",
                    title: "Devices",
                    value: "Loading...",
                    detail: nil
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Footer
            Divider()
            HStack {
                Button("Settings") {
                    // TODO: Open settings
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("About") {
                    // TODO: Open about
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 320, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    DashboardView()
}