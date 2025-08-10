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
    
    init(metricData: WiFiMetrics, onBack: @escaping () -> Void) {
        self.metricData = metricData
        self.onBack = onBack
    }
    
    private func handleSpeedTest() {
        if !isSpeedTestRunning {
            isSpeedTestRunning = true
            speedTestButtonText = "Testing..."
            
            // Simulate speed test (in real implementation, would use SystemMonitor)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                speedTestButtonText = "Test Complete"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    speedTestButtonText = "Test Speed"
                    isSpeedTestRunning = false
                }
            }
        }
    }
    
    private var networkSpeedData: [NetworkSpeedPoint] {
        // Simulated network speed history - in real implementation would track actual speeds
        var speedData: [NetworkSpeedPoint] = []
        let baseDownload = 50.0 // Mbps
        let baseUpload = 10.0   // Mbps
        
        for i in 0..<30 {
            let time = Date().addingTimeInterval(-Double(29 - i) * 2) // Every 2 seconds
            let downloadVariation = Double.random(in: -20...20)
            let uploadVariation = Double.random(in: -3...3)
            
            speedData.append(NetworkSpeedPoint(
                timestamp: time,
                downloadSpeed: max(0, baseDownload + downloadVariation),
                uploadSpeed: max(0, baseUpload + uploadVariation)
            ))
        }
        
        return speedData
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
        .frame(width: 360, height: 620)
    }
    
    private var networkSpeedChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Speed")
                .font(.headline.weight(.semibold))
            
            Chart {
                ForEach(networkSpeedData, id: \.timestamp) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Speed", point.downloadSpeed)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    .symbol(.circle)
                    
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Speed", point.uploadSpeed)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)
                    .symbol(.square)
                }
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(values: .stride(by: 10)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.minute().second(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue))")
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .center) {
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        Text("Download")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Upload")
                            .font(.caption)
                    }
                }
            }
            
            // Current speeds
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Download")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("45.2 Mbps")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Upload")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("8.7 Mbps")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.green)
                }
            }
            
            Text("Mbps • Last 60 seconds")
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
                    InfoRow(label: "IP Address", value: "192.168.1.105") // Simulated
                    InfoRow(label: "Router IP", value: "192.168.1.1") // Simulated
                    InfoRow(label: "DNS Server", value: "8.8.8.8") // Simulated
                    InfoRow(label: "Subnet Mask", value: "255.255.255.0") // Simulated
                    InfoRow(label: "Connection Type", value: "WiFi 6 (802.11ax)") // Simulated
                    InfoRow(label: "Channel", value: "36 (5GHz)") // Simulated
                    InfoRow(label: "Security", value: "WPA3") // Simulated
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
                    InfoRow(label: "Current Download", value: "45.2 Mbps") // Simulated
                    InfoRow(label: "Current Upload", value: "8.7 Mbps") // Simulated
                    InfoRow(label: "Latency", value: "12 ms") // Simulated
                    InfoRow(label: "Connection Duration", value: "2h 34m") // Simulated
                    InfoRow(label: "Data Transferred", value: "1.2 GB") // Simulated
                    
                    // Speed Test Button
                    HStack {
                        Spacer()
                        Button(action: handleSpeedTest) {
                            Text(speedTestButtonText)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSpeedTestRunning ? Color.gray : Color.accentColor)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isSpeedTestRunning)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Supporting Data Structure
struct NetworkSpeedPoint {
    let timestamp: Date
    let downloadSpeed: Double // Mbps
    let uploadSpeed: Double   // Mbps
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