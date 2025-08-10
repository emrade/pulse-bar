//
//  AdvancedBatteryView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import SwiftUI
import Charts

struct AdvancedBatteryView: View, AdvancedMetricView {
    let metricData: BatteryMetrics?
    let onBack: () -> Void
    
    init(metricData: BatteryMetrics?, onBack: @escaping () -> Void) {
        self.metricData = metricData
        self.onBack = onBack
    }
    
    private var batteryHealthColor: Color {
        guard let battery = metricData else { return .gray }
        
        // Simulated health based on cycle count
        if let cycleCount = battery.cycleCount {
            if cycleCount > 1000 { return .red }
            else if cycleCount > 500 { return .orange }
        }
        return .green
    }
    
    private var batteryCondition: String {
        guard let battery = metricData else { return "No Battery" }
        
        if let cycleCount = battery.cycleCount {
            if cycleCount > 1000 { return "Replace Soon" }
            else if cycleCount > 800 { return "Service Recommended" }
            else if cycleCount > 500 { return "Fair" }
            else if cycleCount > 200 { return "Good" }
        }
        return "Excellent"
    }
    
    private var estimatedChargeTime: String? {
        guard let battery = metricData, battery.isCharging else { return nil }
        
        let currentPercentage = battery.percentage
        let remainingPercentage = 100 - currentPercentage
        
        // Rough estimation: ~1.5% per minute for typical charging
        let estimatedMinutes = Int(Double(remainingPercentage) / 1.5)
        let hours = estimatedMinutes / 60
        let minutes = estimatedMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m to full charge"
        } else {
            return "\(minutes)m to full charge"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AdvancedViewHeader(
                title: "Battery Details",
                icon: metricData?.isCharging == true ? "battery.100.bolt" : "battery.100",
                onBack: onBack
            )
            
            if let battery = metricData {
                ScrollView {
                    VStack(spacing: 20) {
                        // Battery Level
                        batteryLevelSection(battery: battery)
                        
                        // Battery Health
                        batteryHealthSection(battery: battery)
                        
                        // Charging Information
                        if battery.isCharging {
                            chargingInfoSection(battery: battery)
                        }
                        
                        // Battery Statistics
                        batteryStatsSection(battery: battery)
                        
                        // Remarks
                        RemarkView(remarks: MetricRemarkEngine.generateBatteryRemarks(for: battery))
                    }
                    .padding()
                }
            } else {
                noBatteryView
            }
        }
        .frame(width: 360, height: 620)
    }
    
    private func batteryLevelSection(battery: BatteryMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Level")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 16) {
                // Large percentage display
                Text("\(battery.percentage)%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(battery.percentage < 20 ? .red : .primary)
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: Double(battery.percentage) / 100)
                        .stroke(
                            battery.percentage < 20 ? Color.red :
                            battery.percentage < 50 ? Color.orange : Color.green,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: battery.percentage)
                    
                    Image(systemName: battery.isCharging ? "bolt.fill" : "battery.100")
                        .font(.title2)
                        .foregroundColor(battery.isCharging ? .yellow : .secondary)
                }
                
                // Status text
                Text(battery.isCharging ? "Charging" : "On Battery")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(battery.isCharging ? .green : .secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func batteryHealthSection(battery: BatteryMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Health")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(batteryHealthColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Condition: \(batteryCondition)")
                            .font(.subheadline.weight(.medium))
                        
                        if let cycleCount = battery.cycleCount {
                            Text("Cycle Count: \(cycleCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Simulated capacity health
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Maximum Capacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("98%") // Simulated - realistic for new PC
                            .font(.caption.weight(.medium))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(batteryHealthColor)
                                .frame(width: geometry.size.width * 0.98, height: 6)
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
    
    private func chargingInfoSection(battery: BatteryMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Charging Information")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "bolt.circle.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Connected to Power")
                        .font(.subheadline.weight(.medium))
                    
                    Spacer()
                }
                
                if let chargeTime = estimatedChargeTime {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        
                        Text(chargeTime)
                            .font(.caption)
                        
                        Spacer()
                    }
                }
                
                HStack {
                    Image(systemName: "thermometer")
                        .foregroundColor(.orange)
                    
                    Text("Temperature: 32°C") // Simulated
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("Normal")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func batteryStatsSection(battery: BatteryMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Information")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                InfoRow(label: "Current Charge", value: "\(battery.percentage)%")
                InfoRow(label: "Status", value: battery.isCharging ? "Charging" : "Discharging")
                InfoRow(label: "Condition", value: batteryCondition)
                
                if let cycleCount = battery.cycleCount {
                    InfoRow(label: "Cycle Count", value: "\(cycleCount)")
                }
                
                if let timeRemaining = battery.timeRemaining, timeRemaining > 0 {
                    let hours = Int(timeRemaining) / 3600
                    let minutes = (Int(timeRemaining) % 3600) / 60
                    InfoRow(label: "Time Remaining", value: "\(hours)h \(minutes)m")
                }
                
                InfoRow(label: "Temperature", value: "32°C") // Simulated
                InfoRow(label: "Design Capacity", value: "100%") // Simulated
                InfoRow(label: "Full Charge Capacity", value: "98%") // Simulated - realistic for new PC
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var noBatteryView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "power.plug")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Battery Detected")
                    .font(.headline.weight(.semibold))
                
                Text("This device is running on external power")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AdvancedBatteryView(
        metricData: BatteryMetrics(
            percentage: 85,
            isCharging: true,
            timeRemaining: nil,
            health: "Good",
            cycleCount: 15,
            isLoading: false,
            error: nil
        ),
        onBack: {}
    )
}