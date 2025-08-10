//
//  AdvancedCPUView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import SwiftUI
import Charts

struct AdvancedCPUView: View, AdvancedMetricView {
    let metricData: CPUMetrics
    let onBack: () -> Void
    @State private var temperatureMetrics: TemperatureMetrics?
    @State private var isLoadingTemperature = true
    
    private let temperatureService = TemperatureService()
    
    init(metricData: CPUMetrics, onBack: @escaping () -> Void) {
        self.metricData = metricData
        self.onBack = onBack
    }
    
    private var cpuHistoryData: [CPUHistoryPoint] {
        // Simulated CPU usage history - in real implementation would track over time
        let currentUsage = metricData.overallUsage
        var history: [CPUHistoryPoint] = []
        
        for i in 0..<60 {
            let time = Date().addingTimeInterval(-Double(59 - i))
            let variation = Double.random(in: -0.15...0.15)
            let usage = max(0.0, min(1.0, currentUsage + variation))
            history.append(CPUHistoryPoint(timestamp: time, usage: usage))
        }
        
        return history
    }
    
    private var cpuCoreData: [CPUCoreData] {
        metricData.perCoreUsage.enumerated().map { index, usage in
            CPUCoreData(
                coreId: index,
                usage: usage,
                temperature: Double.random(in: 45...75), // Simulated temperature
                frequency: Double.random(in: 2.0...3.8) // Simulated frequency in GHz
            )
        }
    }
    
    private var thermalState: (level: String, color: Color, description: String) {
        guard let tempMetrics = temperatureMetrics else {
            return ("Loading...", .gray, "Reading thermal sensors...")
        }
        
        let color: Color = {
            switch tempMetrics.thermalStateColor {
            case "green": return .green
            case "yellow": return .yellow
            case "orange": return .orange  
            case "red": return .red
            default: return .gray
            }
        }()
        
        return (tempMetrics.thermalStateDescription, color, "System thermal state")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AdvancedViewHeader(
                title: "CPU Details",
                icon: "cpu",
                onBack: onBack
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    // CPU Usage Chart
                    cpuUsageChartSection
                    
                    // Core Usage
                    coreUsageSection
                    
                    // Thermal Information
                    thermalInfoSection
                    
                    // CPU Statistics
                    cpuStatsSection
                    
                    // Remarks
                    RemarkView(remarks: MetricRemarkEngine.generateCPURemarks(for: metricData))
                }
                .padding()
            }
        }
        .frame(width: 360, height: 700)
        .onAppear {
            loadTemperatureMetrics()
        }
    }
    
    private func loadTemperatureMetrics() {
        Task {
            let metrics = await temperatureService.getCurrentTemperatureMetrics()
            await MainActor.run {
                temperatureMetrics = metrics
                isLoadingTemperature = false
            }
        }
    }
    
    private var cpuUsageChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CPU Usage History")
                .font(.headline.weight(.semibold))
            
            Chart(cpuHistoryData, id: \.timestamp) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Usage", point.usage * 100)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Usage", point.usage * 100)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.3), .blue.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(values: .stride(by: 15)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.minute(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text("\(Int(intValue))%")
                        }
                    }
                }
            }
            .chartYScale(domain: 0...100)
            
            // Current usage display
            HStack {
                Text("Current Usage:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.1f%%", metricData.overallUsage * 100))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(metricData.overallUsage > 0.8 ? .red : .primary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var coreUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CPU Cores (\(cpuCoreData.count) cores)")
                .font(.headline.weight(.semibold))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 12) {
                ForEach(cpuCoreData, id: \.coreId) { core in
                    VStack(spacing: 8) {
                        HStack {
                            Text("Core \(core.coreId)")
                                .font(.caption.weight(.medium))
                            Spacer()
                            Text(String(format: "%.0f%%", core.usage * 100))
                                .font(.caption)
                                .foregroundColor(core.usage > 0.8 ? .red : .secondary)
                        }
                        
                        // Usage bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                
                                Rectangle()
                                    .fill(core.usage > 0.8 ? Color.red : Color.blue)
                                    .frame(
                                        width: geometry.size.width * core.usage,
                                        height: 4
                                    )
                                    .cornerRadius(2)
                            }
                        }
                        .frame(height: 4)
                        
                        // Additional core info
                        HStack {
                            Text(String(format: "%.1f°C", core.temperature))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: "%.1fGHz", core.frequency))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.quaternarySystemFill))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var thermalInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thermal Status")
                .font(.headline.weight(.semibold))
            
            HStack(spacing: 12) {
                Circle()
                    .fill(thermalState.color)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(thermalState.level)
                        .font(.subheadline.weight(.medium))
                    
                    Text(thermalState.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Temperature readings
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "thermometer")
                        .foregroundColor(.orange)
                    
                    Text("CPU Temperature:")
                        .font(.caption)
                    
                    Spacer()
                    
                    if let tempMetrics = temperatureMetrics {
                        Text(tempMetrics.formattedTemperature)
                            .font(.caption.weight(.medium))
                    } else {
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    
                    Text("Last Updated:")
                        .font(.caption)
                    
                    Spacer()
                    
                    if let tempMetrics = temperatureMetrics {
                        Text(tempMetrics.timestamp, style: .time)
                            .font(.caption.weight(.medium))
                    } else {
                        Text("--")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var cpuStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CPU Information")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                InfoRow(label: "Current Usage", value: String(format: "%.1f%%", metricData.overallUsage * 100))
                InfoRow(label: "Core Count", value: "\(cpuCoreData.count)")
                InfoRow(label: "Architecture", value: "Apple Silicon") // Simulated
                InfoRow(label: "Base Frequency", value: "3.2 GHz") // Simulated
                InfoRow(label: "Max Frequency", value: "3.8 GHz") // Simulated
                InfoRow(label: "Thermal State", value: thermalState.level)
                
                if let tempMetrics = temperatureMetrics {
                    InfoRow(label: "CPU Temperature", value: tempMetrics.formattedTemperature)
                } else {
                    InfoRow(label: "CPU Temperature", value: "Loading...")
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Supporting Data Structures
struct CPUHistoryPoint {
    let timestamp: Date
    let usage: Double
}

struct CPUCoreData {
    let coreId: Int
    let usage: Double
    let temperature: Double
    let frequency: Double
}

#Preview {
    AdvancedCPUView(
        metricData: CPUMetrics(
            overallUsage: 0.45,
            perCoreUsage: [0.4, 0.5, 0.3, 0.6, 0.2, 0.7, 0.4, 0.3],
            isLoading: false,
            error: nil
        ),
        onBack: {}
    )
}