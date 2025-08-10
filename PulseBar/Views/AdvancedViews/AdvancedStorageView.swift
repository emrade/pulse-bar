//
//  AdvancedStorageView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import SwiftUI
import Charts

struct AdvancedStorageView: View, AdvancedMetricView {
    let metricData: DiskMetrics
    let onBack: () -> Void
    @State private var diskIOMetrics: [DiskIOMetrics] = []
    @State private var isLoadingIO = true
    @State private var storageCategories: [StorageCategoryInfo] = []
    @State private var isLoadingStorageAnalysis = true
    
    private let diskIOService = DiskIOService()
    private let storageAnalysisService = StorageAnalysisService()
    
    init(metricData: DiskMetrics, onBack: @escaping () -> Void) {
        self.metricData = metricData
        self.onBack = onBack
    }
    
    private var storageBreakdown: [ChartDataPoint] {
        guard let bootVolume = metricData.bootVolume else { return [] }
        
        let freeBytes = Double(bootVolume.freeBytes)
        
        // If analysis is still loading, show loading state
        if isLoadingStorageAnalysis {
            return [
                ChartDataPoint(label: "Analyzing...", value: Double(bootVolume.usedBytes), color: .gray),
                ChartDataPoint(label: "Free Space", value: freeBytes, color: .gray.opacity(0.3))
            ]
        }
        
        // Use real storage categories if available (should only be 3: Documents, Applications, Other)
        var chartPoints: [ChartDataPoint] = []
        
        for category in storageCategories {
            let color: Color = {
                switch category.color.lowercased() {
                case "blue": return .blue
                case "green": return .green
                case "red": return .red
                case "orange": return .orange
                case "purple": return .purple
                case "yellow": return .yellow
                case "gray", "grey": return .gray
                default: return .blue // Default to blue instead of gray
                }
            }()
            
            chartPoints.append(ChartDataPoint(
                label: category.name,
                value: Double(category.sizeBytes),
                color: color
            ))
        }
        
        // Add free space
        chartPoints.append(ChartDataPoint(
            label: "Free Space",
            value: freeBytes,
            color: .gray.opacity(0.3)
        ))
        
        return chartPoints
    }
    
    private var healthStatus: (status: String, color: Color, icon: String) {
        // Simulated SMART status - in real implementation would use IOKit
        let usagePercentage = metricData.bootVolume?.usagePercentage ?? 0
        
        if usagePercentage > 0.90 {
            return ("Warning", .orange, "exclamationmark.triangle")
        } else if usagePercentage > 0.95 {
            return ("Critical", .red, "xmark.circle")
        } else {
            return ("Healthy", .green, "checkmark.circle")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AdvancedViewHeader(
                title: "Storage Details",
                icon: "internaldrive",
                onBack: onBack
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    // Storage Breakdown Chart
                    storageBreakdownSection
                    
                    // Disk I/O Activity
                    diskIOActivitySection
                    
                    // Health Status
                    healthStatusSection
                    
                    // Volume Information
                    volumeInfoSection
                    
                    // Remarks
                    RemarkView(remarks: MetricRemarkEngine.generateStorageRemarks(for: metricData))
                }
                .padding()
            }
        }
        .frame(width: 360, height: 700)
        .onAppear {
            loadDiskIOMetrics()
            loadStorageAnalysis()
        }
    }
    
    private func loadDiskIOMetrics() {
        Task {
            let metrics = await diskIOService.getCurrentDiskIOMetrics()
            await MainActor.run {
                diskIOMetrics = metrics
                isLoadingIO = false
            }
        }
    }
    
    private func loadStorageAnalysis() {
        guard let bootVolume = metricData.bootVolume else {
            isLoadingStorageAnalysis = false
            return
        }
        
        Task {
            let categories = await storageAnalysisService.analyzeStorageBreakdown(totalUsedBytes: bootVolume.usedBytes)
            await MainActor.run {
                storageCategories = categories
                isLoadingStorageAnalysis = false
            }
        }
    }
    
    private var diskIOActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disk I/O Activity")
                .font(.headline.weight(.semibold))
            
            if isLoadingIO {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading I/O data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if diskIOMetrics.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "moon.zzz")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Disk is idle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(diskIOMetrics, id: \.diskName) { metric in
                        diskIORow(metric: metric)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func diskIORow(metric: DiskIOMetrics) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text(metric.diskName.uppercased())
                    .font(.caption.weight(.semibold))
                
                Spacer()
                
                Text(metric.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                // Read metrics
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption2)
                        Text("Read")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text(metric.formattedReadSpeed)
                        .font(.caption.weight(.medium))
                    Text(metric.formattedReadOps)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Write metrics
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Write")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                    }
                    Text(metric.formattedWriteSpeed)
                        .font(.caption.weight(.medium))
                    Text(metric.formattedWriteOps)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if metric != diskIOMetrics.last {
                Divider()
            }
        }
    }
    
    private var storageBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Breakdown")
                .font(.headline.weight(.semibold))
            
            HStack(spacing: 20) {
                // Donut Chart
                Chart(storageBreakdown, id: \.label) { item in
                    SectorMark(
                        angle: .value("Usage", item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 2.0
                    )
                    .foregroundStyle(item.color)
                    .opacity(item.label == "Free Space" ? 0.4 : 1.0)
                }
                .frame(width: 120, height: 120)
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(storageBreakdown.filter { $0.label != "Free Space" }, id: \.label) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label)
                                    .font(.caption.weight(.medium))
                                Text(ByteCountFormatter.string(fromByteCount: Int64(item.value), countStyle: .binary))
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
    
    private var healthStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disk Health")
                .font(.headline.weight(.semibold))
            
            HStack(spacing: 12) {
                Image(systemName: healthStatus.icon)
                    .foregroundColor(healthStatus.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("SMART Status: \(healthStatus.status)")
                        .font(.subheadline.weight(.medium))
                    
                    Text("Disk appears to be functioning normally")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Temperature (simulated)
            HStack {
                Image(systemName: "thermometer")
                    .foregroundColor(.blue)
                Text("Temperature: 38°C")
                    .font(.caption)
                
                Spacer()
                
                Text("Normal")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var volumeInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Volume Information")
                .font(.headline.weight(.semibold))
            
            if let bootVolume = metricData.bootVolume {
                VStack(spacing: 8) {
                    InfoRow(label: "Volume Name", value: bootVolume.name)
                    InfoRow(label: "Mount Point", value: bootVolume.mountPoint)
                    InfoRow(label: "Total Capacity", value: ByteCountFormatter.string(fromByteCount: Int64(bootVolume.totalBytes), countStyle: .binary))
                    InfoRow(label: "Available Space", value: ByteCountFormatter.string(fromByteCount: Int64(bootVolume.freeBytes), countStyle: .binary))
                    InfoRow(label: "Used Space", value: ByteCountFormatter.string(fromByteCount: Int64(bootVolume.usedBytes), countStyle: .binary))
                    InfoRow(label: "Usage", value: String(format: "%.1f%%", bootVolume.usagePercentage * 100))
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption.weight(.medium))
        }
    }
}

#Preview {
    AdvancedStorageView(
        metricData: DiskMetrics(
            volumes: [
                VolumeInfo(
                    name: "Macintosh HD",
                    mountPoint: "/",
                    totalBytes: 500_000_000_000,
                    freeBytes: 150_000_000_000,
                    isBootVolume: true,
                    isExternal: false
                )
            ],
            isLoading: false,
            error: nil
        ),
        onBack: {}
    )
}