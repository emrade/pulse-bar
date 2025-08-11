//
//  AdvancedNetworkView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import SwiftUI
import Charts

struct AdvancedNetworkView: View, AdvancedMetricView {
    let metricData: WiFiMetrics
    let onBack: () -> Void
    
    @State private var speedTestButtonText = "Test Speed"
    @State private var isSpeedTestRunning = false
    @State private var networkConnectionInfo: NetworkConnectionInfo?
    @State private var currentSpeedTest = NetworkSpeedTest()
    
    init(metricData: WiFiMetrics, onBack: @escaping () -> Void) {
        self.metricData = metricData
        self.onBack = onBack
    }
    
    private func handleSpeedTest() {
        if !isSpeedTestRunning {
            SystemMonitor.shared.runSpeedTest()
        }
    }
    
    private var hasSpeedTestResults: Bool {
        currentSpeedTest.downloadSpeed != nil || currentSpeedTest.uploadSpeed != nil
    }
    
    private var signalQualityLevel: (level: String, color: Color, description: String) {
        if !metricData.isConnected {
            return ("Disconnected", .gray, "Not connected to WiFi")
        }
        
        // Use RSSI directly from metricData
        let signalStrength = metricData.rssi ?? -75
        
        if signalStrength >= -50 {
            return ("Excellent", .green, "Very close to router")
        } else if signalStrength >= -60 {
            return ("Good", .blue, "Same room as router")
        } else if signalStrength >= -70 {
            return ("Fair", .yellow, "Different room, some walls")
        } else if signalStrength >= -80 {
            return ("Weak", .orange, "Far from router, obstacles")
        } else {
            return ("Very Weak", .red, "Barely usable")
        }
    }
    
    private var rssiDisplayString: String {
        guard let rssi = metricData.rssi else { return "Unknown" }
        return "\(rssi) dBm"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AdvancedViewHeader(
                title: "Network Details",
                icon: metricData.isConnected ? "wifi" : "wifi.slash",
                onBack: onBack
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    // Network Speed Chart
                    networkSpeedChartSection
                    
                    // Signal Quality
                    signalQualitySection
                    
                    // Connection Details
                    connectionDetailsSection
                    
                    // Network Statistics
                    networkStatsSection
                    
                    // Remarks
                    RemarkView(remarks: MetricRemarkEngine.generateNetworkRemarks(for: metricData, speedTest: NetworkSpeedTest()))
                }
                .padding()
            }
        }
        .standardWindowFrame()
        .task {
            await loadNetworkConnectionInfo()
        }
        .onReceive(SystemMonitor.shared.$networkSpeedTest) { speedTest in
            currentSpeedTest = speedTest
            
            // Update button state based on test progress
            if speedTest.isRunning {
                if !isSpeedTestRunning {
                    isSpeedTestRunning = true
                }
                // Update progress text based on completion percentage
                let progressPercent = Int(speedTest.progress * 100)
                if progressPercent < 10 {
                    speedTestButtonText = "Measuring latency..."
                } else if progressPercent < 60 {
                    speedTestButtonText = "Testing download (\(progressPercent)%)"
                } else if progressPercent < 100 {
                    speedTestButtonText = "Testing upload (\(progressPercent)%)"
                } else {
                    speedTestButtonText = "Finishing..."
                }
            } else if isSpeedTestRunning {
                // Test completed
                if speedTest.downloadSpeed != nil {
                    speedTestButtonText = "Test Complete"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        speedTestButtonText = "Test Speed"
                        isSpeedTestRunning = false
                    }
                } else if speedTest.error != nil {
                    speedTestButtonText = "Test Failed"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        speedTestButtonText = "Test Speed"
                        isSpeedTestRunning = false
                    }
                }
            }
        }
    }
    
    private func loadNetworkConnectionInfo() async {
        let info = await SystemMonitor.shared.networkInfoService.getNetworkConnectionInfo()
        await MainActor.run {
            networkConnectionInfo = info
        }
    }
    
    private func formatSpeed(_ speed: Double?) -> String {
        guard let speed = speed else { return "Unknown" }
        return String(format: "%.1f Mbps", speed)
    }
    
    private var networkSpeedChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Speed Test")
                .font(.headline.weight(.semibold))
            
            if hasSpeedTestResults {
                // Show current speed test results
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Download")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(formatSpeed(currentSpeedTest.downloadSpeed))
                                .font(.title2.weight(.bold))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Upload")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(formatSpeed(currentSpeedTest.uploadSpeed))
                                .font(.title2.weight(.bold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let latency = currentSpeedTest.latency {
                        HStack {
                            Text("Latency")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f ms", latency))
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.orange)
                        }
                    }
                }
            } else {
                // Show placeholder when no test results
                VStack(spacing: 16) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Speed Test Results")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Text("Run a speed test to see current network performance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
            }
            
            // Speed Test Button
            HStack {
                Spacer()
                Button(action: handleSpeedTest) {
                    Text(speedTestButtonText)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSpeedTestRunning ? Color.gray : Color.accentColor)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isSpeedTestRunning)
                Spacer()
            }
            .padding(.top, 8)
            
            Text("Real-time network speed testing • Results are current measurements")
                .font(.caption2)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var signalQualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Signal Quality")
                .font(.headline.weight(.semibold))
            
            HStack(spacing: 12) {
                Circle()
                    .fill(signalQualityLevel.color)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(signalQualityLevel.level)
                        .font(.subheadline.weight(.medium))
                    
                    Text(signalQualityLevel.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Signal strength bar
            if metricData.isConnected {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Signal Strength")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(rssiDisplayString)
                            .font(.caption.weight(.medium))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            let signalStrength = metricData.rssi ?? -75
                            let normalizedStrength = max(0.0, min(1.0, Double(signalStrength + 90) / 60)) // -30 to -90 dBm range
                            
                            Rectangle()
                                .fill(signalQualityLevel.color)
                                .frame(
                                    width: geometry.size.width * normalizedStrength,
                                    height: 6
                                )
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var connectionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Details")
                .font(.headline.weight(.semibold))
            
            if metricData.isConnected {
                VStack(spacing: 8) {
                    InfoRow(label: "Network Name", value: metricData.ssid ?? "Unknown")
                    InfoRow(label: "IP Address", value: networkConnectionInfo?.ipAddress ?? "Fetching...")
                    InfoRow(label: "Router IP", value: networkConnectionInfo?.routerIP ?? "Fetching...")
                    InfoRow(label: "DNS Server", value: networkConnectionInfo?.dnsServers.first ?? "Fetching...")
                    InfoRow(label: "Subnet Mask", value: networkConnectionInfo?.subnetMask ?? "Fetching...")
                    InfoRow(label: "Connection Type", value: networkConnectionInfo?.connectionType ?? "Fetching...")
                    InfoRow(label: "Channel", value: networkConnectionInfo?.channel ?? "Fetching...")
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Not Connected to WiFi")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var networkStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Statistics")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                InfoRow(label: "Status", value: metricData.isConnected ? "Connected" : "Disconnected")
                
                if metricData.isConnected {
                    InfoRow(label: "Signal Strength", value: rssiDisplayString)
                    InfoRow(label: "Quality Level", value: signalQualityLevel.level)
                    InfoRow(label: "Interface Type", value: networkConnectionInfo?.interfaceType ?? "Unknown")
                    if let dnsCount = networkConnectionInfo?.dnsServers.count, dnsCount > 1 {
                        InfoRow(label: "DNS Servers", value: "\(dnsCount) configured")
                    }
                    InfoRow(label: "Connection Status", value: "Connected")
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}


#Preview {
    AdvancedNetworkView(
        metricData: WiFiMetrics(
            ssid: "MyNetwork",
            bssid: "aa:bb:cc:dd:ee:ff",
            rssi: -45,
            linkSpeed: 150.0,
            isConnected: true,
            isLoading: false,
            error: nil
        ),
        onBack: {}
    )
}