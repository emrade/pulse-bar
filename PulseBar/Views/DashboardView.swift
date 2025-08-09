//
//  DashboardView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var systemMonitor = SystemMonitor.shared
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
            
            // Metric rows with real data
            VStack(spacing: 8) {
                MetricRowView(
                    icon: "cpu",
                    title: "CPU",
                    value: systemMonitor.snapshot.cpu.formattedOverallUsage,
                    detail: systemMonitor.snapshot.cpu.perCoreUsage.isEmpty ? nil : "\(systemMonitor.snapshot.cpu.perCoreUsage.count) cores"
                )
                
                MetricRowView(
                    icon: "memorychip",
                    title: "Memory",
                    value: systemMonitor.snapshot.memory.formattedUsed,
                    detail: systemMonitor.snapshot.memory.formattedTotal
                )
                
                MetricRowView(
                    icon: "internaldrive",
                    title: "Storage",
                    value: systemMonitor.snapshot.disk.formattedBootFree,
                    detail: systemMonitor.snapshot.disk.bootVolume?.name
                )
                
                if let battery = systemMonitor.snapshot.battery {
                    MetricRowView(
                        icon: battery.isCharging ? "battery.100.bolt" : "battery.100",
                        title: "Battery",
                        value: battery.formattedStatus,
                        detail: nil
                    )
                }
                
                MetricRowView(
                    icon: systemMonitor.snapshot.wifi.isConnected ? "wifi" : "wifi.slash",
                    title: "Wi-Fi",
                    value: systemMonitor.snapshot.wifi.formattedStatus,
                    detail: systemMonitor.snapshot.wifi.isConnected ? systemMonitor.snapshot.wifi.signalQuality : nil
                )
                
                MetricRowView(
                    icon: "network",
                    title: "Network",
                    value: systemMonitor.networkSpeedTest.formattedResult,
                    detail: nil,
                    isButton: !systemMonitor.networkSpeedTest.isRunning,
                    action: {
                        if systemMonitor.networkSpeedTest.isRunning {
                            systemMonitor.cancelSpeedTest()
                        } else {
                            systemMonitor.runSpeedTest()
                        }
                    }
                )
                
                MetricRowView(
                    icon: "externaldrive.connected.to.line.below",
                    title: "Devices",
                    value: systemMonitor.snapshot.devices.formattedCount,
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