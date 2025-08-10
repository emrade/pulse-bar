//
//  AdvancedMemoryView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import SwiftUI
import Charts

struct AdvancedMemoryView: View, AdvancedMetricView {
    let metricData: MemoryMetrics
    let onBack: () -> Void
    
    init(metricData: MemoryMetrics, onBack: @escaping () -> Void) {
        self.metricData = metricData
        self.onBack = onBack
    }
    
    private var memoryBreakdown: [ChartDataPoint] {
        let totalBytes = Double(metricData.totalBytes)
        let usedBytes = Double(metricData.usedBytes)
        let cachedBytes = Double(metricData.cachedBytes)
        let freeBytes = Double(metricData.freeBytes)
        
        // Simulated memory breakdown
        let appMemory = usedBytes * 0.60    // 60% app memory
        let wiredMemory = usedBytes * 0.25   // 25% wired
        let compressedMemory = usedBytes * 0.15 // 15% compressed
        
        return [
            ChartDataPoint(label: "App Memory", value: appMemory, color: .blue),
            ChartDataPoint(label: "Wired Memory", value: wiredMemory, color: .orange),
            ChartDataPoint(label: "Compressed", value: compressedMemory, color: .red),
            ChartDataPoint(label: "Cached", value: cachedBytes, color: .green),
            ChartDataPoint(label: "Free", value: freeBytes, color: .gray.opacity(0.3))
        ]
    }
    
    private var topProcesses: [(name: String, usage: Double)] {
        // Simulated top processes - in real implementation would use ActivityMonitor APIs
        return [
            ("Claude Code", 1.2),
            ("Xcode", 0.8),
            ("System Preferences", 0.3),
            ("WindowServer", 0.2),
            ("Dock", 0.1)
        ]
    }
    
    private var memoryPressure: (level: String, color: Color, description: String) {
        let usagePercentage = metricData.usagePercentage
        
        if usagePercentage > 0.90 {
            return ("Critical", .red, "System may become unresponsive")
        } else if usagePercentage > 0.80 {
            return ("High", .orange, "Close unused applications")
        } else if usagePercentage > 0.70 {
            return ("Moderate", .yellow, "Monitor for performance impact")
        } else {
            return ("Normal", .green, "Memory usage is healthy")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AdvancedViewHeader(
                title: "Memory Details",
                icon: "memorychip",
                onBack: onBack
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    // Memory Breakdown Chart
                    memoryBreakdownSection
                    
                    // Memory Pressure
                    memoryPressureSection
                    
                    // Top Processes
                    topProcessesSection
                    
                    // Memory Stats
                    memoryStatsSection
                    
                    // Remarks
                    RemarkView(remarks: MetricRemarkEngine.generateMemoryRemarks(for: metricData))
                }
                .padding()
            }
        }
        .frame(width: 360, height: 620)
    }
    
    private var memoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage")
                .font(.headline.weight(.semibold))
            
            HStack(spacing: 20) {
                // Pie Chart
                Chart(memoryBreakdown, id: \.label) { item in
                    SectorMark(
                        angle: .value("Usage", item.value),
                        angularInset: 1.0
                    )
                    .foregroundStyle(item.color)
                    .opacity(item.label == "Free" ? 0.4 : 1.0)
                }
                .frame(width: 120, height: 120)
                
                // Legend
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(memoryBreakdown.filter { $0.label != "Free" }, id: \.label) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.label)
                                    .font(.caption.weight(.medium))
                                Text(ByteCountFormatter.string(fromByteCount: Int64(item.value), countStyle: .memory))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var memoryPressureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Pressure")
                .font(.headline.weight(.semibold))
            
            HStack(spacing: 12) {
                Circle()
                    .fill(memoryPressure.color)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(memoryPressure.level)
                        .font(.subheadline.weight(.medium))
                    
                    Text(memoryPressure.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Usage bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f%%", metricData.usagePercentage * 100))
                        .font(.caption.weight(.medium))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(memoryPressure.color)
                            .frame(
                                width: geometry.size.width * metricData.usagePercentage,
                                height: 6
                            )
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var topProcessesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Memory Users")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                ForEach(Array(topProcesses.enumerated()), id: \.offset) { index, process in
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(process.name)
                            .font(.caption.weight(.medium))
                        
                        Spacer()
                        
                        Text(String(format: "%.1f GB", process.usage))
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
    
    private var memoryStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Information")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                InfoRow(label: "Total Memory", value: metricData.formattedTotal)
                InfoRow(label: "Used Memory", value: metricData.formattedUsed)
                InfoRow(label: "Available Memory", value: metricData.formattedAvailable)
                InfoRow(label: "Cached Memory", value: ByteCountFormatter.string(fromByteCount: Int64(metricData.cachedBytes), countStyle: .memory))
                InfoRow(label: "Swap Used", value: "0 bytes") // Simulated
                InfoRow(label: "Memory Pressure", value: memoryPressure.level)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

#Preview {
    AdvancedMemoryView(
        metricData: MemoryMetrics(
            totalBytes: 16_000_000_000,
            usedBytes: 12_000_000_000,
            cachedBytes: 2_000_000_000,
            freeBytes: 2_000_000_000,
            isLoading: false,
            error: nil
        ),
        onBack: {}
    )
}