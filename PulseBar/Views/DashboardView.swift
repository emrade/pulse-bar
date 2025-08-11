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
        Group {
            switch viewModel.currentViewState {
            case .basic:
                basicDashboardView
            case .advancedStorage:
                AdvancedStorageView(
                    metricData: viewModel.snapshot.disk,
                    onBack: viewModel.showBasicView
                )
            case .advancedMemory:
                AdvancedMemoryView(
                    metricData: viewModel.snapshot.memory,
                    onBack: viewModel.showBasicView
                )
            case .advancedBattery:
                AdvancedBatteryView(
                    metricData: viewModel.snapshot.battery,
                    onBack: viewModel.showBasicView
                )
            case .advancedCPU:
                AdvancedCPUView(
                    metricData: viewModel.snapshot.cpu,
                    onBack: viewModel.showBasicView
                )
            case .advancedNetwork:
                AdvancedNetworkView(
                    metricData: viewModel.snapshot.wifi,
                    onBack: viewModel.showBasicView
                )
            case .advancedDevices:
                AdvancedDeviceView(
                    metricData: viewModel.snapshot.devices,
                    onBack: viewModel.showBasicView
                )
            case .advancedNetworkUsage:
                AdvancedNetworkUsageView(
                    metricData: viewModel.snapshot.networkUsage,
                    onBack: viewModel.showBasicView,
                    onReset: viewModel.showResetConfirmation
                )
            case .settings:
                SettingsView(onBack: viewModel.showBasicView)
            case .about:
                AboutView(onBack: viewModel.showBasicView)
            }
        }
        .frame(width: 360, height: 700)
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
    
    private var basicDashboardView: some View {
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
                TappableMetricRowView(
                    icon: "internaldrive",
                    title: "Storage",
                    value: viewModel.snapshot.disk.formattedBootUsage,
                    detail: "\(viewModel.snapshot.disk.bootVolume?.name ?? "Unknown") • \(viewModel.snapshot.disk.formattedBootTotal)",
                    onTap: viewModel.handleStorageTileTap
                )
                
                TappableMetricRowView(
                    icon: "memorychip",
                    title: "Memory",
                    value: viewModel.snapshot.memory.formattedUsedWithAvailable,
                    detail: viewModel.snapshot.memory.formattedTotal,
                    onTap: viewModel.handleMemoryTileTap
                )
                
                if let battery = viewModel.snapshot.battery {
                    TappableMetricRowView(
                        icon: battery.isCharging ? "battery.100.bolt" : "battery.100",
                        title: "Battery",
                        value: battery.formattedStatus,
                        detail: nil,
                        onTap: viewModel.handleBatteryTileTap
                    )
                }
                
                TappableMetricRowView(
                    icon: "cpu",
                    title: "CPU",
                    value: viewModel.snapshot.cpu.formattedOverallUsage,
                    detail: viewModel.snapshot.cpu.perCoreUsage.isEmpty ? nil : "\(viewModel.snapshot.cpu.perCoreUsage.count) cores",
                    onTap: viewModel.handleCPUTileTap
                )
                
                TappableMetricRowView(
                    icon: viewModel.networkDisplayInfo.icon,
                    title: viewModel.networkDisplayInfo.title,
                    value: viewModel.networkValueText,
                    detail: viewModel.networkDetailText,
                    onTap: viewModel.handleNetworkTileTap
                )

                TappableMetricRowView(
                    icon: "arrow.up.arrow.down.circle",
                    title: "Data Usage (Today)",
                    value: viewModel.snapshot.networkUsage.formattedTotal,
                    detail: "Tap for details • Reset available",
                    onTap: viewModel.handleNetworkUsageTileTap
                )
                
                TappableMetricRowView(
                    icon: "externaldrive.connected.to.line.below",
                    title: "Devices",
                    value: viewModel.snapshot.devices.formattedDetails,
                    detail: nil,
                    onTap: viewModel.handleDevicesTileTap
                )
            }
            .padding(.horizontal, 16)
            
            Spacer(minLength: 4)
            
            // Footer
            Divider()
            HStack(spacing: 20) {
                Button(action: { viewModel.showSettings() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                        Text("Settings")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: { viewModel.showAbout() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                        Text("About")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: { viewModel.quitApp() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power.circle.fill")
                            .font(.system(size: 14))
                        Text("Quit")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Tappable Metric Row View
struct TappableMetricRowView: View {
    let icon: String
    let title: String
    let value: String
    let detail: String?
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .frame(width: 24, alignment: .center)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(value)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        if let detail = detail {
                            Text(detail)
                                .font(.caption2)
                                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 50)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle()) // inside the label so full frame is tappable
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
            )
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
}

#Preview {
    DashboardView()
}