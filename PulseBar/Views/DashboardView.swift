//
//  DashboardView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            switch viewModel.currentViewState {
            case .basic:
                ThemedDashboardView(viewModel: viewModel)
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
        .themedWindowFrame()
        .themedBackground()
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
    
    private var metricCards: [MetricCardData] {
        [
            MetricCardData(
                icon: "internaldrive",
                title: "Storage",
                value: viewModel.snapshot.disk.formattedBootUsage,
                detail: viewModel.snapshot.disk.bootVolume?.name ?? "Unknown",
                onTap: viewModel.handleStorageTileTap
            ),
            MetricCardData(
                icon: "memorychip",
                title: "Memory",
                value: viewModel.snapshot.memory.formattedUsedWithAvailable,
                detail: viewModel.snapshot.memory.formattedTotal,
                onTap: viewModel.handleMemoryTileTap
            ),
            MetricCardData(
                icon: "cpu",
                title: "CPU",
                value: viewModel.snapshot.cpu.formattedOverallUsage,
                detail: "\(viewModel.snapshot.cpu.perCoreUsage.count) cores",
                onTap: viewModel.handleCPUTileTap
            ),
            MetricCardData(
                icon: viewModel.networkDisplayInfo.icon,
                title: viewModel.networkDisplayInfo.title,
                value: viewModel.networkValueText,
                detail: viewModel.networkDetailText,
                onTap: viewModel.handleNetworkTileTap
            ),
            MetricCardData(
                icon: "arrow.up.arrow.down.circle",
                title: "Data Usage",
                value: viewModel.snapshot.networkUsage.formattedTotal,
                detail: "Today",
                onTap: viewModel.handleNetworkUsageTileTap
            ),
            MetricCardData(
                icon: "externaldrive.connected.to.line.below",
                title: "Devices",
                value: viewModel.snapshot.devices.formattedDetails,
                detail: nil,
                onTap: viewModel.handleDevicesTileTap
            )
        ] + (viewModel.snapshot.battery != nil ? [
            MetricCardData(
                icon: viewModel.snapshot.battery!.isCharging ? "battery.100.bolt" : "battery.100",
                title: "Battery",
                value: viewModel.snapshot.battery!.formattedStatus,
                detail: nil,
                onTap: viewModel.handleBatteryTileTap
            )
        ] : [])
    }
    
    private var basicDashboardView: some View {
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
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
            
            // System Information Card
            systemInfoCard
            
            // Grid layout for metrics
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 160)),
                GridItem(.flexible(minimum: 160))
            ], spacing: 10) {
                TappableMetricCardView(
                    icon: "internaldrive",
                    title: "Storage",
                    value: viewModel.snapshot.disk.formattedBootUsage,
                    detail: "\(viewModel.snapshot.disk.bootVolume?.name ?? "Unknown")",
                    onTap: viewModel.handleStorageTileTap
                )
                
                TappableMetricCardView(
                    icon: "memorychip",
                    title: "Memory",
                    value: viewModel.snapshot.memory.formattedUsedWithAvailable,
                    detail: viewModel.snapshot.memory.formattedTotal,
                    onTap: viewModel.handleMemoryTileTap
                )
                
                TappableMetricCardView(
                    icon: "cpu",
                    title: "CPU",
                    value: viewModel.snapshot.cpu.formattedOverallUsage,
                    detail: "\(viewModel.snapshot.cpu.perCoreUsage.count) cores",
                    onTap: viewModel.handleCPUTileTap
                )
                
                TappableMetricCardView(
                    icon: viewModel.networkDisplayInfo.icon,
                    title: viewModel.networkDisplayInfo.title,
                    value: viewModel.networkValueText,
                    detail: viewModel.networkDetailText,
                    onTap: viewModel.handleNetworkTileTap
                )
                
                TappableMetricCardView(
                    icon: "arrow.up.arrow.down.circle",
                    title: "Data Usage",
                    value: viewModel.snapshot.networkUsage.formattedTotal,
                    detail: "Today",
                    onTap: viewModel.handleNetworkUsageTileTap
                )
                
                TappableMetricCardView(
                    icon: "externaldrive.connected.to.line.below",
                    title: "Devices",
                    value: viewModel.snapshot.devices.formattedDetails,
                    detail: nil,
                    onTap: viewModel.handleDevicesTileTap
                )
                
                // Show battery only if available
                if let battery = viewModel.snapshot.battery {
                    TappableMetricCardView(
                        icon: battery.isCharging ? "battery.100.bolt" : "battery.100",
                        title: "Battery",
                        value: battery.formattedStatus,
                        detail: nil,
                        onTap: viewModel.handleBatteryTileTap
                    )
                }
            }
            .padding(.horizontal, 16)
            
            Spacer(minLength: 8)
            
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
            .padding(.bottom, 16)
        }
    }
    
    private var systemInfoCard: some View {
        SystemInfoCardView()
            .padding(.horizontal, 16)
    }
}

// MARK: - Tappable Metric Card View (for Grid Layout)
struct TappableMetricCardView: View {
    let icon: String
    let title: String
    let value: String
    let detail: String?
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon and title row
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .themedSurfaceText()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                }
                
                // Value and detail
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.8)
                    
                    if let detail = detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
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
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
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

// MARK: - Legacy Row View (kept for compatibility)
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
                        .themedSurfaceText()
                    
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
            .contentShape(Rectangle())
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

// MARK: - System Information Card View
struct SystemInfoCardView: View {
    private let systemInfo = SystemInfoService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with computer icon and name
            HStack(spacing: 8) {
                Image(systemName: "desktopcomputer")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                Text(systemInfo.computerName)
                    .font(.subheadline.weight(.semibold))
                    .themedSurfaceText()
                
                Spacer()
            }
            
            // System specs in a grid
            HStack(spacing: 16) {
                // Left column
                VStack(alignment: .leading, spacing: 8) {
                    systemInfoRow(label: "Chip", value: systemInfo.chipName)
                    systemInfoRow(label: "Memory", value: systemInfo.totalMemory)
                }
                
                Spacer()
                
                // Right column  
                VStack(alignment: .leading, spacing: 8) {
                    systemInfoRow(label: "Model", value: systemInfo.deviceModel)
                    systemInfoRow(label: "OS", value: systemInfo.macOSVersion)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
    
    private func systemInfoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .themedSurfaceText()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#Preview {
    DashboardView()
}
