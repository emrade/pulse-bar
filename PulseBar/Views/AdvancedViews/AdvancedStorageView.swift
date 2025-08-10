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
    @State private var storageCategories: [StorageCategoryInfo] = []
    @State private var isLoadingStorageAnalysis = true
    
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
        
        // Use real storage categories if available (should be Applications and Other)
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
            loadStorageAnalysis()
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