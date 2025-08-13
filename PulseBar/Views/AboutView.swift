//
//  AboutView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

struct AboutView: View {
    let onBack: () -> Void
    
    @State private var showingSystemInfo = false
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .themedFont(.body)
                        }
                        .themedHighContrastText()
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text("About")
                        .themedFont(.headline)
                        .themedSurfaceText()
                    
                    Spacer()
                    
                    // Invisible placeholder for alignment
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.subheadline.weight(.medium))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Info
                    VStack(spacing: 16) {
                        // App Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        // App Details
                        VStack(spacing: 8) {
                            Text("PulseBar")
                                .themedFont(.title)
                                .themedSurfaceText()
                            
                            Text("System Performance Monitor")
                                .themedFont(.body)
                                .themedSurfaceVariantText()
                            
                            Text("Version \(appVersion) (\(buildNumber))")
                                .themedFont(.footnote)
                                .themedSurfaceVariantText()
                        }
                    }
                    
                    // Features Section
                    infoSection(
                        title: "Features",
                        icon: "star.fill",
                        iconColor: .yellow
                    ) {
                        featureRow(icon: "cpu", title: "CPU Monitoring", description: "Real-time CPU usage and thermal state")
                        featureRow(icon: "memorychip", title: "Memory Analysis", description: "Active, wired, compressed & cached memory")
                        featureRow(icon: "externaldrive", title: "Storage Insights", description: "Disk usage, health & SMART status")
                        featureRow(icon: "wifi", title: "Network Tools", description: "Speed tests & connection monitoring")
                        featureRow(icon: "battery.100", title: "Battery Health", description: "Charge status & battery condition")
                        featureRow(icon: "display", title: "Connected Devices", description: "USB, Thunderbolt & Bluetooth devices")
                    }
                    
                    // System Information
                    infoSection(
                        title: "System Information",
                        icon: "macbook",
                        iconColor: .gray
                    ) {
                        systemInfoRow(label: "macOS Version", value: systemVersion)
                        systemInfoRow(label: "Device Model", value: deviceModel)
                        systemInfoRow(label: "Architecture", value: systemArchitecture)
                        systemInfoRow(label: "Memory", value: totalMemory)
                        systemInfoRow(label: "Uptime", value: systemUptime)
                    }
                    
                    // Technical Details
                    infoSection(
                        title: "Technical",
                        icon: "gearshape.2.fill",
                        iconColor: .blue
                    ) {
                        techRow(label: "Built with", value: "Swift & SwiftUI")
                        techRow(label: "Data Sources", value: "macOS System APIs")
                        techRow(label: "Architecture", value: "Native Apple Silicon")
                        techRow(label: "Frameworks", value: "IOKit, SystemConfiguration")
                        techRow(label: "License", value: "MIT License")
                    }
                    
                    // Actions
                    infoSection(
                        title: "Actions",
                        icon: "square.and.arrow.up",
                        iconColor: .green
                    ) {
                        actionRow(
                            icon: "doc.text",
                            title: "Export System Report",
                            subtitle: "Generate detailed system information",
                            buttonTitle: "Export",
                            buttonColor: .blue,
                            action: exportSystemReport
                        )
                        
                        actionRow(
                            icon: "exclamationmark.bubble",
                            title: "Report Issues",
                            subtitle: "Report bugs or request features on GitHub",
                            buttonTitle: "GitHub Issues",
                            buttonColor: .green,
                            action: openSupport
                        )
                        
                        actionRow(
                            icon: "star",
                            title: "View on GitHub",
                            subtitle: "Star the project and contribute",
                            buttonTitle: "GitHub Repo",
                            buttonColor: .orange,
                            action: rateApp
                        )
                    }
                    
                    // Copyright
                    VStack(spacing: 4) {
                        Text("© 2025 PulseBar")
                            .font(.caption)
                            .themedSurfaceVariantText()
                        
                        Text("Made with ❤️ for macOS")
                            .font(.caption2)
                            .themedSurfaceVariantText()
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
        }
        .standardWindowFrame()
    }
    
    // MARK: - System Information Properties
    private var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    private var deviceModel: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    private var systemArchitecture: String {
        var size = 0
        sysctlbyname("hw.targettype", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.targettype", &machine, &size, nil, 0)
        let targetType = String(cString: machine)
        return targetType.isEmpty ? "Apple Silicon" : targetType
    }
    
    private var totalMemory: String {
        var size = MemoryLayout<UInt64>.size
        var memSize: UInt64 = 0
        sysctlbyname("hw.memsize", &memSize, &size, nil, 0)
        return ByteCountFormatter.string(fromByteCount: Int64(memSize), countStyle: .memory)
    }
    
    private var systemUptime: String {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.size
        if sysctlbyname("kern.boottime", &boottime, &size, nil, 0) == 0 {
            let now = Date()
            let bootDate = Date(timeIntervalSince1970: TimeInterval(boottime.tv_sec))
            let uptime = now.timeIntervalSince(bootDate)
            
            let days = Int(uptime) / 86400
            let hours = (Int(uptime) % 86400) / 3600
            let minutes = (Int(uptime) % 3600) / 60
            
            if days > 0 {
                return "\(days)d \(hours)h \(minutes)m"
            } else if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
        return "Unknown"
    }
    
    // MARK: - Action Methods
    private func exportSystemReport() {
        let report = generateSystemReport()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        
        // You could also save to file or show in a new window
        print("System report copied to clipboard")
    }
    
    private func generateSystemReport() -> String {
        return """
        PulseBar System Report
        Generated: \(Date())
        
        App Information:
        - Version: \(appVersion) (\(buildNumber))
        - Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")
        
        System Information:
        - macOS: \(systemVersion)
        - Model: \(deviceModel)
        - Architecture: \(systemArchitecture)
        - Memory: \(totalMemory)
        - Uptime: \(systemUptime)
        
        Current Metrics:
        - CPU Usage: [Real-time data would go here]
        - Memory Usage: [Real-time data would go here]
        - Network Status: [Real-time data would go here]
        """
    }
    
    private func openSupport() {
        if let url = URL(string: "https://github.com/emrade/pulse-bar/issues") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "https://github.com/emrade/pulse-bar") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - View Components
extension AboutView {
    private func infoSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.themedHeadline)
                
                Text(title)
                    .themedFont(.headline)
                    .themedSurfaceText()
            }
            
            VStack(spacing: 8) {
                content()
            }
        }
        .padding()
        .themedSurfaceVariant()
        .cornerRadius(10)
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.themedBody)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .themedFont(.body)
                    .themedSurfaceText()
                
                Text(description)
                    .themedFont(.footnote)
                    .themedSurfaceVariantText()
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func systemInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .themedFont(.body)
                .themedSurfaceVariantText()
            
            Spacer()
            
            Text(value)
                .themedFont(.body)
                .themedSurfaceText()
        }
        .padding(.vertical, 4)
    }
    
    private func techRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .themedFont(.body)
                .themedSurfaceVariantText()
            
            Spacer()
            
            Text(value)
                .themedFont(.footnote)
                .themedSurfaceText()
        }
        .padding(.vertical, 4)
    }
    
    private func actionRow(
        icon: String,
        title: String,
        subtitle: String,
        buttonTitle: String,
        buttonColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(buttonColor)
                .font(.subheadline)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .themedSurfaceText()
                
                Text(subtitle)
                    .font(.caption)
                    .themedSurfaceVariantText()
            }
            
            Spacer()
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.caption.weight(.medium))
                    .themedHighContrastText()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(buttonColor)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AboutView(onBack: {})
}