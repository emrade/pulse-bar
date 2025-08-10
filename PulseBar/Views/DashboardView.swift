//
//  DashboardView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var systemMonitor = SystemMonitor.shared
    @State private var showingResetConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.blue)
                Text("PulseBar")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
            
            // Metric rows with real data
            VStack(spacing: 10) {
                MetricRowView(
                    icon: "internaldrive",
                    title: "Storage",
                    value: systemMonitor.snapshot.disk.formattedBootUsage,
                    detail: "\(systemMonitor.snapshot.disk.bootVolume?.name ?? "Unknown") • \(systemMonitor.snapshot.disk.formattedBootTotal)"
                )
                
                MetricRowView(
                    icon: "memorychip",
                    title: "Memory",
                    value: systemMonitor.snapshot.memory.formattedUsedWithAvailable,
                    detail: systemMonitor.snapshot.memory.formattedTotal
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
                    icon: "cpu",
                    title: "CPU",
                    value: systemMonitor.snapshot.cpu.formattedOverallUsage,
                    detail: systemMonitor.snapshot.cpu.perCoreUsage.isEmpty ? nil : "\(systemMonitor.snapshot.cpu.perCoreUsage.count) cores"
                )
                
                MetricRowView(
                    icon: systemMonitor.networkDisplayInfo.icon,
                    title: systemMonitor.networkDisplayInfo.title,
                    value: systemMonitor.activeConnectionType == .wifi ? 
                        systemMonitor.snapshot.wifi.formattedStatus :
                        "Connected via \(systemMonitor.networkDisplayInfo.connectionDetail ?? "Network")",
                    detail: {
                        switch systemMonitor.activeConnectionType {
                        case .wifi:
                            if systemMonitor.snapshot.wifi.isConnected {
                                let speedTestResult = systemMonitor.networkSpeedTest.formattedResult != "Test Speed" && !systemMonitor.networkSpeedTest.isRunning ? 
                                    " • \(systemMonitor.networkSpeedTest.formattedResult)" : ""
                                return "\(systemMonitor.snapshot.wifi.signalQuality)\(speedTestResult)"
                            }
                            return nil
                        case .ethernet, .other:
                            return systemMonitor.networkSpeedTest.formattedResult != "Test Speed" && !systemMonitor.networkSpeedTest.isRunning ? 
                                systemMonitor.networkSpeedTest.formattedResult : nil
                        }
                    }(),
                    showInfoButton: systemMonitor.activeConnectionType == .wifi,
                    infoContent: systemMonitor.activeConnectionType == .wifi ? """
WiFi Signal Strength (dBm):

dBm measures radio signal power. Higher numbers = weaker signal.

Signal Quality Guide:
• -30 to -50 dBm: Excellent (very close to router)
• -50 to -60 dBm: Good (same room as router) 
• -60 to -70 dBm: Fair (different room, some walls)
• -70 to -80 dBm: Weak (far from router, obstacles)
• -80 to -90 dBm: Very weak (barely usable)

Better signal = faster speeds and more reliable connection.
""" : nil,
                    secondaryButtonText: systemMonitor.networkSpeedTest.isRunning ? 
                        "Testing... \(Int(systemMonitor.networkSpeedTest.progress * 100))%" : "Test Speed",
                    secondaryAction: {
                        if systemMonitor.networkSpeedTest.isRunning {
                            systemMonitor.cancelSpeedTest()
                        } else {
                            systemMonitor.runSpeedTest()
                        }
                    }
                )

                MetricRowView(
                    icon: "arrow.up.arrow.down.circle",
                    title: "Data Usage (Today)",
                    value: systemMonitor.snapshot.networkUsage.formattedTotal,
                    detail: nil,
                    secondaryButtonText: "Reset",
                    secondaryAction: {
                        showingResetConfirmation = true
                    }
                )
                
                MetricRowView(
                    icon: "externaldrive.connected.to.line.below",
                    title: "Devices",
                    value: systemMonitor.snapshot.devices.formattedDetails,
                    detail: nil
                )
            }
            .padding(.horizontal, 16)
            
            Spacer(minLength: 4)
            
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
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 360, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Reset Data Usage", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                systemMonitor.resetDailyDataUsage()
            }
        } message: {
            Text("Are you sure you want to reset today's data usage to 0? This action cannot be undone.")
        }
    }
}

#Preview {
    DashboardView()
}