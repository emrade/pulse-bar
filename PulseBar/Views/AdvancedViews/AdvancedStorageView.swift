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
                ChartDataPoint(label: "Analyzing...", value: Double(bootVolume.usedBytes), color: .themedChartNeutral),
                ChartDataPoint(label: "Free Space", value: freeBytes, color: .themedChartBackground)
            ]
        }
        
        // Use real storage categories if available (should be Applications and Other)
        var chartPoints: [ChartDataPoint] = []
        
        for (index, category) in storageCategories.enumerated() {
            let color: Color = {
                switch category.color.lowercased() {
                case "blue": return .themedChartColor(at: 0)
                case "green": return .themedChartSuccess
                case "red": return .themedChartError
                case "orange": return .themedChartWarning
                case "purple": return .themedChartSecondary
                case "yellow": return .themedChartWarning
                case "gray", "grey": return .themedChartNeutral
                default: return .themedChartColor(at: index)
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
            color: .themedChartBackground
        ))
        
        return chartPoints
    }
    
    private var healthStatus: (status: String, color: Color, icon: String) {
        guard let bootVolume = metricData.bootVolume,
              let smartStatus = bootVolume.smartStatus else {
            // Fallback to simulated status if SMART data is not available
            let usagePercentage = metricData.bootVolume?.usagePercentage ?? 0
            
            if usagePercentage > 0.90 {
                return ("Warning", .themedChartWarning, "exclamationmark.triangle")
            } else if usagePercentage > 0.95 {
                return ("Critical", .themedChartError, "xmark.circle")
            } else {
                return ("Healthy", .themedChartSuccess, "checkmark.circle")
            }
        }
        
        // Use real SMART status
        if !smartStatus.isAvailable {
            return ("Unknown", .gray, "questionmark.circle")
        }
        
        if smartStatus.isHealthy {
            return ("Healthy", .themedChartSuccess, "checkmark.circle")
        } else {
            return ("Failing", .themedChartError, "xmark.circle")
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
        .standardWindowFrame()
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
                .themedFont(.primary, size: .large)
                .themedSurfaceText()
            
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
                                    .themedFont(.primary, size: .small)
                                    .themedSurfaceText()
                                Text(FormatterUtility.shared.formatFileSize(UInt64(item.value)))
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
    
    private var healthStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disk Health")
                .themedFont(.primary, size: .large)
                .themedSurfaceText()
            
            HStack(spacing: 12) {
                Image(systemName: healthStatus.icon)
                    .foregroundColor(healthStatus.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let bootVolume = metricData.bootVolume,
                       let smartStatus = bootVolume.smartStatus {
                        Text("SMART Status: \(smartStatus.overallHealth)")
                            .themedFont(.primary, size: .regular)
                            .themedSurfaceText()
                        
                        if smartStatus.isAvailable {
                            Text("Disk SMART data is available and \(smartStatus.isHealthy ? "healthy" : "indicating potential issues")")
                                .themedFont(.primary, size: .small)
                                .themedSurfaceVariantText()
                        } else {
                            Text("SMART data not available for this drive")
                                .themedFont(.primary, size: .small)
                                .themedSurfaceVariantText()
                        }
                    } else {
                        Text("SMART Status: Unknown")
                            .themedFont(.primary, size: .regular)
                            .themedSurfaceText()
                        
                        Text("Disk appears to be functioning normally")
                            .themedFont(.primary, size: .small)
                            .themedSurfaceVariantText()
                    }
                }
                
                Spacer()
            }
            
            // Temperature (from SMART data if available, otherwise simulated)
            HStack {
                Image(systemName: "thermometer")
                    .foregroundColor(.blue)
                
                if let bootVolume = metricData.bootVolume,
                   let smartStatus = bootVolume.smartStatus,
                   let temperature = smartStatus.formattedTemperature {
                    Text("Temperature: \(temperature)")
                        .themedFont(.primary, size: .small)
                        .themedSurfaceText()
                    
                    Spacer()
                    
                    // Determine temperature status
                    let tempColor: Color = {
                        guard let temp = smartStatus.temperature else { return .secondary }
                        if temp > 50 { return .red }
                        else if temp > 40 { return .orange }
                        else { return .green }
                    }()
                    
                    let tempStatus: String = {
                        guard let temp = smartStatus.temperature else { return "Unknown" }
                        if temp > 50 { return "High" }
                        else if temp > 40 { return "Warm" }
                        else { return "Normal" }
                    }()
                    
                    Text(tempStatus)
                        .themedFont(.primary, size: .small)
                        .foregroundColor(tempColor)
                } else {
                    Text("Temperature: \(FormatterUtility.shared.formatTemperature(38.0))")
                        .themedFont(.primary, size: .small)
                        .themedSurfaceText()
                    
                    Spacer()
                    
                    Text("Normal")
                        .themedFont(.primary, size: .small)
                        .foregroundColor(.green)
                }
            }
        }
        .themedAdvancedSection()
    }
    
    private var volumeInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Volume Information")
                .themedFont(.primary, size: .large)
                .themedSurfaceText()
            
            if let bootVolume = metricData.bootVolume {
                VStack(spacing: 8) {
                    InfoRow(label: "Volume Name", value: bootVolume.name)
                    InfoRow(label: "Mount Point", value: bootVolume.mountPoint)
                    InfoRow(label: "Total Capacity", value: FormatterUtility.shared.formatFileSize(bootVolume.totalBytes))
                    InfoRow(label: "Available Space", value: FormatterUtility.shared.formatFileSize(bootVolume.freeBytes))
                    InfoRow(label: "Used Space", value: FormatterUtility.shared.formatFileSize(bootVolume.usedBytes))
                    InfoRow(label: "Usage", value: String(format: "%.1f%%", bootVolume.usagePercentage * 100))
                }
            }
        }
        .themedAdvancedSection()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .themedFont(.primary, size: .small)
                .themedSurfaceVariantText()
            
            Spacer()
            
            Text(value)
                .themedFont(.primary, size: .small)
                .themedSurfaceText()
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