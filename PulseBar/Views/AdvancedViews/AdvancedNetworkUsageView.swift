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
        // Simulated hourly usage data for today
        var history: [NetworkUsagePoint] = []
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        for hour in 0...currentHour {
            let time = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
            let download = Double.random(in: 50...500) * 1024 * 1024 // MB in bytes
            let upload = Double.random(in: 10...100) * 1024 * 1024   // MB in bytes
            history.append(NetworkUsagePoint(timestamp: time, downloaded: download, uploaded: upload))
        }
        
        return history
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
        .frame(width: 360, height: 620)
    }
    
    private var usageSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Summary")
                .font(.headline.weight(.semibold))
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Downloaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text(formatBytes(metricData.downloaded))
                            .font(.title2.weight(.bold))
                            .foregroundColor(.blue)
                        
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Uploaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text(formatBytes(metricData.uploaded))
                            .font(.title2.weight(.bold))
                            .foregroundColor(.green)
                        
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text(formatBytes(metricData.downloaded + metricData.uploaded))
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                        
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var usageChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Usage")
                .font(.headline.weight(.semibold))
            
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
                            .font(.caption)
                    }
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Uploaded")
                            .font(.caption)
                    }
                }
            }
            
            Text("Data usage since midnight")
                .font(.caption2)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var usageBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Statistics")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                InfoRow(label: "Downloaded Today", value: formatBytes(metricData.downloaded))
                InfoRow(label: "Uploaded Today", value: formatBytes(metricData.uploaded))
                InfoRow(label: "Total Usage", value: formatBytes(metricData.downloaded + metricData.uploaded))
                InfoRow(label: "Average Per Hour", value: formatBytes((metricData.downloaded + metricData.uploaded) / UInt64(max(1, Calendar.current.component(.hour, from: Date())))))
                InfoRow(label: "Peak Hour", value: "2:00 PM - 3:00 PM") // Simulated
                InfoRow(label: "Last Reset", value: "Today at 12:00 AM")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var resetDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reset Data Usage")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                Text("Reset today's data usage counters to zero. This action cannot be undone.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Spacer()
                    Button(action: onReset) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                            Text("Reset Usage Data")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(.white)
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
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Supporting Data Structure
struct NetworkUsagePoint {
    let timestamp: Date
    let downloaded: Double
    let uploaded: Double
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