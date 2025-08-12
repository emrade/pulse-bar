//
//  AdvancedNetworkUsageView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import SwiftUI
import Charts

struct AdvancedNetworkUsageView: View {
    let metricData: NetworkUsageMetrics
    let onBack: () -> Void
    let onReset: () -> Void
    
    init(metricData: NetworkUsageMetrics, onBack: @escaping () -> Void, onReset: @escaping () -> Void = {}) {
        self.metricData = metricData
        self.onBack = onBack
        self.onReset = onReset
    }
    
    private var usageHistory: [NetworkUsagePoint] {
        // Get real hourly usage data from SystemMonitor
        return SystemMonitor.shared.networkUsageService.getHourlyUsageHistory()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AdvancedViewHeader(
                title: "Data Usage Details",
                icon: "arrow.up.arrow.down.circle",
                onBack: onBack
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Usage Summary
                    usageSummarySection
                    
                    // Usage Chart
                    usageChartSection
                    
                    // Usage Breakdown
                    usageBreakdownSection
                    
                    // Reset Data Section
                    resetDataSection
                    
                    // Remarks
                    RemarkView(remarks: MetricRemarkEngine.generateNetworkUsageRemarks(for: metricData))
                }
                .padding()
            }
        }
        .standardWindowFrame()
    }
    
    private var usageSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Summary")
                .themedFont(.primary, size: .large)
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Downloaded")
                        .themedFont(.primary, size: .small)
                        .themedSurfaceVariantText()
                    
                    VStack(spacing: 4) {
                        Text(formatBytes(metricData.downloaded))
                            .font(.title2.weight(.bold))
                            .foregroundColor(.blue)
                        
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.themedSmall)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Uploaded")
                        .themedFont(.primary, size: .small)
                        .themedSurfaceVariantText()
                    
                    VStack(spacing: 4) {
                        Text(formatBytes(metricData.uploaded))
                            .font(.title2.weight(.bold))
                            .foregroundColor(.green)
                        
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.themedSmall)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Total")
                        .themedFont(.primary, size: .small)
                        .themedSurfaceVariantText()
                    
                    VStack(spacing: 4) {
                        Text(formatBytes(metricData.downloaded + metricData.uploaded))
                            .font(.title2.weight(.bold))
                            .themedSurfaceText()
                        
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.themedSmall)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .themedAdvancedSection()
    }
    
    private var usageChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Usage")
                .themedFont(.primary, size: .large)
            
            Chart {
                ForEach(usageHistory, id: \.timestamp) { point in
                    BarMark(
                        x: .value("Hour", point.timestamp, unit: .hour),
                        y: .value("Downloaded", point.downloaded / (1024 * 1024)) // Convert to MB
                    )
                    .foregroundStyle(.blue)
                    
                    BarMark(
                        x: .value("Hour", point.timestamp, unit: .hour),
                        y: .value("Uploaded", point.uploaded / (1024 * 1024)) // Convert to MB
                    )
                    .foregroundStyle(.green)
                }
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue)) MB")
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .center) {
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        Text("Downloaded")
                            .themedFont(.primary, size: .small)
                    }
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Uploaded")
                            .themedFont(.primary, size: .small)
                    }
                }
            }
            
            Text("Data usage since midnight")
                .themedFont(.primary, size: .small)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
        .themedAdvancedSection()
    }
    
    private var usageBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Statistics")
                .themedFont(.primary, size: .large)
            
            VStack(spacing: 8) {
                InfoRow(label: "Downloaded Today", value: formatBytes(metricData.downloaded))
                InfoRow(label: "Uploaded Today", value: formatBytes(metricData.uploaded))
                InfoRow(label: "Total Usage", value: formatBytes(metricData.downloaded + metricData.uploaded))
                InfoRow(label: "Average Per Hour", value: formatBytes((metricData.downloaded + metricData.uploaded) / UInt64(max(1, Calendar.current.component(.hour, from: Date())))))
                InfoRow(label: "Peak Hour", value: getPeakHour())
                InfoRow(label: "Last Reset", value: "Today at 12:00 AM")
            }
        }
        .themedAdvancedSection()
    }
    
    private var resetDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reset Data Usage")
                .themedFont(.primary, size: .large)
            
            VStack(spacing: 8) {
                Text("Reset today's data usage counters to zero. This action cannot be undone.")
                    .themedFont(.primary, size: .small)
                    .themedSurfaceVariantText()
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Spacer()
                    Button(action: onReset) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.themedSmall)
                            Text("Reset Usage Data")
                                .themedFont(.primary, size: .small)
                        }
                        .themedHighContrastText()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                        )
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
        }
        .themedAdvancedSection()
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        return FormatterUtility.shared.formatNetworkSize(bytes)
    }
    
    private func getPeakHour() -> String {
        let history = usageHistory
        
        guard !history.isEmpty else {
            return "No data available"
        }
        
        // Find the hour with the highest total usage
        let peakUsage = history.max { first, second in
            (first.downloaded + first.uploaded) < (second.downloaded + second.uploaded)
        }
        
        if let peak = peakUsage {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:00 a"
            let startTime = formatter.string(from: peak.timestamp)
            
            let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: peak.timestamp)
            let endTimeString = endTime.map { formatter.string(from: $0) } ?? ""
            
            return "\(startTime) - \(endTimeString)"
        }
        
        return "No peak identified"
    }
}

#Preview {
    AdvancedNetworkUsageView(
        metricData: NetworkUsageMetrics(
            downloaded: 2_500_000_000, // 2.5 GB
            uploaded: 500_000_000,     // 500 MB
            isLoading: false,
            error: nil
        ),
        onBack: {},
        onReset: {}
    )
}