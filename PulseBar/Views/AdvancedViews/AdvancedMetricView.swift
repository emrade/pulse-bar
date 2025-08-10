//
//  AdvancedMetricView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import SwiftUI

// MARK: - Protocol for Advanced Metric Views
protocol AdvancedMetricView: View {
    associatedtype MetricType
    
    var metricData: MetricType { get }
    var onBack: () -> Void { get }
    
    init(metricData: MetricType, onBack: @escaping () -> Void)
}

// MARK: - Common Advanced View Components
struct AdvancedViewHeader: View {
    let title: String
    let icon: String
    let onBack: () -> Void
    
    @State private var isBackHovered = false
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.medium))
                    Text("Back")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(width: 60, height: 32)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isBackHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear)
                        .animation(.easeInOut(duration: 0.2), value: isBackHovered)
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isBackHovered = hovering
                if hovering {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct RemarkView: View {
    let remarks: [String]
    
    var body: some View {
        if !remarks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Insights")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(remarks, id: \.self) { remark in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 4, height: 4)
                                .padding(.top, 6)
                            Text(remark)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Chart Data Models
struct ChartDataPoint {
    let label: String
    let value: Double
    let color: Color
}

// MARK: - Common Extensions
extension Color {
    static let chartColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink, .cyan, .yellow
    ]
    
    static func chartColor(for index: Int) -> Color {
        chartColors[index % chartColors.count]
    }
}