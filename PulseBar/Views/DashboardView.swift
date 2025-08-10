//
//  DashboardView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
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
                    value: viewModel.snapshot.disk.formattedBootUsage,
                    detail: "\(viewModel.snapshot.disk.bootVolume?.name ?? "Unknown") • \(viewModel.snapshot.disk.formattedBootTotal)"
                )
                
                MetricRowView(
                    icon: "memorychip",
                    title: "Memory",
                    value: viewModel.snapshot.memory.formattedUsedWithAvailable,
                    detail: viewModel.snapshot.memory.formattedTotal
                )
                
                if let battery = viewModel.snapshot.battery {
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
                    value: viewModel.snapshot.cpu.formattedOverallUsage,
                    detail: viewModel.snapshot.cpu.perCoreUsage.isEmpty ? nil : "\(viewModel.snapshot.cpu.perCoreUsage.count) cores"
                )
                
                MetricRowView(
                    icon: viewModel.networkDisplayInfo.icon,
                    title: viewModel.networkDisplayInfo.title,
                    value: viewModel.networkValueText,
                    detail: viewModel.networkDetailText,
                    showInfoButton: viewModel.shouldShowNetworkInfoButton,
                    infoContent: viewModel.networkInfoContent,
                    secondaryButtonText: viewModel.speedTestButtonText,
                    secondaryAction: viewModel.handleSpeedTestAction
                )

                MetricRowView(
                    icon: "arrow.up.arrow.down.circle",
                    title: "Data Usage (Today)",
                    value: viewModel.snapshot.networkUsage.formattedTotal,
                    detail: nil,
                    secondaryButtonText: "Reset",
                    secondaryAction: viewModel.showResetConfirmation
                )
                
                MetricRowView(
                    icon: "externaldrive.connected.to.line.below",
                    title: "Devices",
                    value: viewModel.snapshot.devices.formattedDetails,
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
                    viewModel.quitApp()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 360, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Reset Data Usage", isPresented: $viewModel.showingResetConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelReset()
            }
            Button("Reset", role: .destructive) {
                viewModel.resetDailyDataUsage()
            }
        } message: {
            Text("Are you sure you want to reset today's data usage to 0? This action cannot be undone.")
        }
    }
}

#Preview {
    DashboardView()
}