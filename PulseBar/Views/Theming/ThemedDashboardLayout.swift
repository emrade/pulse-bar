//
//  ThemedDashboardLayout.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

struct ThemedDashboardLayout<Content: View>: View {
    let content: Content
    @EnvironmentObject var themeManager: ThemeManager
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(
            columns: gridColumns,
            spacing: themeManager.layout.cardSpacing
        ) {
            content
        }
        .themedLayoutPadding()
    }
    
    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: minimumColumnWidth)),
            count: themeManager.layout.gridColumns
        )
    }
    
    private var minimumColumnWidth: CGFloat {
        let totalPadding = themeManager.layout.padding.horizontal * 2
        let totalSpacing = themeManager.layout.cardSpacing * CGFloat(themeManager.layout.gridColumns - 1)
        let availableWidth = themeManager.popover.width - totalPadding - totalSpacing
        
        return availableWidth / CGFloat(themeManager.layout.gridColumns)
    }
}

// MARK: - Themed Dashboard View

struct ThemedDashboardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        VStack(spacing: themeManager.layout.sectionSpacing) {
            // Header
            ThemedHeader()
            
            ThemedDivider()
            
            // System Information Card
            ThemedSystemInfoCard()
            
            // Metrics Grid
            ThemedDashboardLayout {
                ForEach(metricCards, id: \.title) { card in
                    ThemedMetricCard(
                        icon: card.icon,
                        title: card.title,
                        value: card.value,
                        detail: card.detail,
                        onTap: card.onTap
                    )
                }
            }
            
            Spacer(minLength: 8)
            
            // Footer
            ThemedDivider()
            ThemedFooter()
        }
        .themedWindowFrame()
        .themedBackground()
        .environmentObject(themeManager)
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
}

// MARK: - Themed Header

struct ThemedHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: "waveform.path.ecg")
                .themedIcon(size: .regular)
            
            Text("PulseBar")
                .themedFont(.primary, size: .title)
                .themedPrimaryText()
            
            Spacer()
        }
        .themedHorizontalPadding()
        .themedVerticalPadding()
    }
}

// MARK: - Themed Footer

struct ThemedFooter: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        HStack(spacing: 20) {
            FooterButton(
                icon: "gearshape.fill",
                title: "Settings",
                action: viewModel.showSettings
            )
            
            Spacer()
            
            FooterButton(
                icon: "info.circle.fill", 
                title: "About",
                action: viewModel.showAbout
            )
            
            Spacer()
            
            FooterButton(
                icon: "power.circle.fill",
                title: "Quit",
                action: viewModel.quitApp
            )
        }
        .themedHorizontalPadding()
        .themedVerticalPadding()
    }
}

struct FooterButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .themedIcon(size: .small)
                
                Text(title)
                    .themedFont(.primary, size: .small)
            }
            .themedSecondaryText()
        }
        .buttonStyle(.plain)
        .themedHoverEffect()
    }
}

// MARK: - Themed Divider

struct ThemedDivider: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Divider()
            .background(Color.themedDivider)
    }
}

// MARK: - Metric Card Data

struct MetricCardData {
    let icon: String
    let title: String
    let value: String
    let detail: String?
    let onTap: () -> Void
}

// MARK: - Preview

#Preview {
    ThemedDashboardView()
        .environmentObject(ThemeManager.shared)
}