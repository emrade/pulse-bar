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
    @State private var topProcesses: [ProcessMemoryInfo] = []
    @State private var isLoadingProcesses = true
    
    private let processService = ProcessService()
    
    init(metricData: MemoryMetrics, onBack: @escaping () -> Void) {
        self.metricData = metricData
        self.onBack = onBack
    }
    
    private var memoryBreakdown: [ChartDataPoint] {
        let activeBytes = Double(metricData.activeBytes)
        let wiredBytes = Double(metricData.wiredBytes)
        let compressedBytes = Double(metricData.compressedBytes)
        let cachedBytes = Double(metricData.cachedBytes)
        let freeBytes = Double(metricData.freeBytes)
        
        return [
            ChartDataPoint(label: "Active Memory", value: activeBytes, color: .themedChartColor(at: 0)),
            ChartDataPoint(label: "Wired Memory", value: wiredBytes, color: .themedChartColor(at: 1)),
            ChartDataPoint(label: "Compressed", value: compressedBytes, color: .themedChartColor(at: 2)),
            ChartDataPoint(label: "Cached", value: cachedBytes, color: .themedChartColor(at: 3)),
            ChartDataPoint(label: "Free", value: freeBytes, color: .themedChartBackground)
        ]
    }
    
    @State private var showSimplifiedView = true
    
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
                    
                    // Top Memory Users
                    topMemoryUsersSection
                    
                    // Memory Usage Categories
                    memoryUsageCategoriesSection
                    
                    // Memory Stats
                    memoryStatsSection
                    
                    // Remarks
                    RemarkView(remarks: MetricRemarkEngine.generateMemoryRemarks(for: metricData))
                }
                .padding()
            }
        }
        .standardWindowFrame()
        .onAppear {
            loadTopProcesses()
        }
    }
    
    private func loadTopProcesses() {
        Task {
            let processes = await processService.getTopMemoryProcesses(limit: 5)
            await MainActor.run {
                topProcesses = processes
                isLoadingProcesses = false
            }
        }
    }
    
    private var topMemoryUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Memory Users")
                .themedFont(.primary, size: .large)
            
            if isLoadingProcesses {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading process data...")
                        .themedFont(.primary, size: .small)
                        .themedSurfaceVariantText()
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if topProcesses.isEmpty {
                HStack {
                    Spacer()
                    Text("No process data available")
                        .themedFont(.primary, size: .small)
                        .themedSurfaceVariantText()
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(topProcesses.enumerated()), id: \.element.pid) { index, process in
                        processRow(
                            rank: index + 1,
                            name: process.name,
                            memory: process.memoryUsage,
                            pid: process.pid
                        )
                    }
                }
            }
        }
        .themedAdvancedSection()
    }
    
    private func processRow(rank: Int, name: String, memory: UInt64, pid: Int32) -> some View {
        HStack {
            // Rank circle
            ZStack {
                Circle()
                    .fill(rankColor(for: rank))
                    .frame(width: 20, height: 20)
                
                Text("\(rank)")
                    .themedFont(.primary, size: .small)
                    .themedHighContrastText()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .themedFont(.primary, size: .small)
                    .lineLimit(1)
                
                Text("PID: \(pid)")
                    .themedFont(.primary, size: .small)
                    .themedSurfaceVariantText()
            }
            
            Spacer()
            
            Text(FormatterUtility.shared.formatMemorySize(UInt64(memory)))
                .themedFont(.primary, size: .small)
                .themedSurfaceText()
        }
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }
    
    private var memoryUsageCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage Categories")
                .themedFont(.primary, size: .large)
            
            VStack(spacing: 8) {
                memoryUsageRow(
                    label: "Active Memory", 
                    amount: Double(metricData.activeBytes),
                    color: .themedChartColor(at: 0),
                    description: "Applications and their data"
                )
                
                memoryUsageRow(
                    label: "Wired Memory", 
                    amount: Double(metricData.wiredBytes),
                    color: .themedChartColor(at: 1),
                    description: "System kernel and drivers"
                )
                
                memoryUsageRow(
                    label: "Compressed", 
                    amount: Double(metricData.compressedBytes),
                    color: .themedChartColor(at: 2),
                    description: "Compressed inactive memory"
                )
                
                memoryUsageRow(
                    label: "Cached Files", 
                    amount: Double(metricData.cachedBytes),
                    color: .themedChartColor(at: 3),
                    description: "File system cache"
                )
                
                memoryUsageRow(
                    label: "Free Memory", 
                    amount: Double(metricData.freeBytes),
                    color: .themedChartBackground,
                    description: "Available for new apps"
                )
            }
        }
        .themedAdvancedSection()
    }
    
    private func memoryUsageRow(label: String, amount: Double, color: Color, description: String) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .themedFont(.primary, size: .small)
                    .frame(width: 80, alignment: .leading)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(FormatterUtility.shared.formatMemorySize(UInt64(amount)))
                    .themedFont(.primary, size: .small)
                
                Text(description)
                    .themedFont(.primary, size: .small)
                    .themedSurfaceVariantText()
            }
        }
    }
    
    private var memoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage")
                .themedFont(.primary, size: .large)
            
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
                                    .themedFont(.primary, size: .small)
                                Text(FormatterUtility.shared.formatMemorySize(UInt64(item.value)))
                                    .themedFont(.primary, size: .small)
                                    .themedSurfaceVariantText()
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                Spacer()
            }
        }
        .themedAdvancedSection()
    }
    
    private var memoryPressureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Pressure")
                .themedFont(.primary, size: .large)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(memoryPressure.color)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(memoryPressure.level)
                        .themedFont(.primary, size: .regular)
                    
                    Text(memoryPressure.description)
                        .themedFont(.primary, size: .small)
                        .themedSurfaceVariantText()
                }
                
                Spacer()
            }
            
            // Usage bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Usage")
                        .themedFont(.primary, size: .small)
                        .themedSurfaceVariantText()
                    Spacer()
                    Text(String(format: "%.1f%%", metricData.usagePercentage * 100))
                        .themedFont(.primary, size: .small)
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
        .themedAdvancedSection()
    }
    
    
    private var memoryStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Information")
                .themedFont(.primary, size: .large)
            
            VStack(spacing: 8) {
                InfoRow(label: "Total Memory", value: metricData.formattedTotal)
                InfoRow(label: "Used Memory", value: metricData.formattedUsed)
                InfoRow(label: "Available Memory", value: metricData.formattedAvailable)
                InfoRow(label: "Cached Memory", value: FormatterUtility.shared.formatMemorySize(metricData.cachedBytes))
                InfoRow(label: "Memory Pressure", value: memoryPressure.level)
            }
        }
        .themedAdvancedSection()
    }
}

#Preview {
    AdvancedMemoryView(
        metricData: MemoryMetrics(
            totalBytes: 16_000_000_000,
            usedBytes: 12_000_000_000,
            cachedBytes: 2_000_000_000,
            freeBytes: 2_000_000_000,
            activeBytes: 8_000_000_000,
            wiredBytes: 3_000_000_000,
            compressedBytes: 1_000_000_000,
            isLoading: false,
            error: nil
        ),
        onBack: {}
    )
}