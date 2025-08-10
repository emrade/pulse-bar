//
//  AdvancedDeviceView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import SwiftUI

struct AdvancedDeviceView: View, AdvancedMetricView {
    typealias MetricType = DeviceMetrics
    
    let metricData: DeviceMetrics
    let onBack: () -> Void
    
    init(metricData: DeviceMetrics, onBack: @escaping () -> Void) {
        self.metricData = metricData
        self.onBack = onBack
    }
    
    private var categorizedDevices: [DeviceCategory] {
        // Simulated device categorization - in real implementation would parse actual device data
        let usbDevices = [
            DetailedDevice(name: "Magic Keyboard", type: "Keyboard", connectionType: "USB", isActive: true),
            DetailedDevice(name: "Magic Mouse", type: "Mouse", connectionType: "USB", isActive: true),
            DetailedDevice(name: "External SSD", type: "Storage", connectionType: "USB 3.2", isActive: true),
            DetailedDevice(name: "Webcam", type: "Camera", connectionType: "USB 2.0", isActive: false)
        ]
        
        let thunderboltDevices = [
            DetailedDevice(name: "Studio Display", type: "Monitor", connectionType: "Thunderbolt 4", isActive: true),
            DetailedDevice(name: "Audio Interface", type: "Audio", connectionType: "Thunderbolt 3", isActive: true)
        ]
        
        let bluetoothDevices = [
            DetailedDevice(name: "AirPods Pro", type: "Audio", connectionType: "Bluetooth", isActive: true),
            DetailedDevice(name: "iPhone", type: "Phone", connectionType: "Bluetooth", isActive: false)
        ]
        
        return [
            DeviceCategory(name: "USB Devices", devices: usbDevices, icon: "usb.c"),
            DeviceCategory(name: "Thunderbolt", devices: thunderboltDevices, icon: "bolt.horizontal"),
            DeviceCategory(name: "Bluetooth", devices: bluetoothDevices, icon: "antenna.radiowaves.left.and.right")
        ]
    }
    
    private var deviceSummary: DeviceSummary {
        let allDevices = categorizedDevices.flatMap { $0.devices }
        let activeDevices = allDevices.filter { $0.isActive }
        
        return DeviceSummary(
            totalDevices: allDevices.count,
            activeDevices: activeDevices.count,
            usbDevices: categorizedDevices.first { $0.name == "USB Devices" }?.devices.count ?? 0,
            thunderboltDevices: categorizedDevices.first { $0.name == "Thunderbolt" }?.devices.count ?? 0,
            bluetoothDevices: categorizedDevices.first { $0.name == "Bluetooth" }?.devices.count ?? 0
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AdvancedViewHeader(
                title: "Connected Devices",
                icon: "externaldrive.connected.to.line.below",
                onBack: onBack
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    // Device Summary
                    deviceSummarySection
                    
                    // Device Categories
                    ForEach(categorizedDevices, id: \.name) { category in
                        deviceCategorySection(category: category)
                    }
                    
                    // System Information
                    systemInfoSection
                    
                    // Remarks
                    RemarkView(remarks: MetricRemarkEngine.generateDeviceRemarks(for: metricData))
                }
                .padding()
            }
        }
        .frame(width: 360, height: 700)
    }
    
    private var deviceSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Summary")
                .font(.headline.weight(.semibold))
            
            HStack(spacing: 20) {
                // Active devices indicator
                VStack(spacing: 4) {
                    Text("\(deviceSummary.activeDevices)")
                        .font(.title.weight(.bold))
                        .foregroundColor(.green)
                    
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Total devices
                VStack(spacing: 4) {
                    Text("\(deviceSummary.totalDevices)")
                        .font(.title.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Connection types breakdown
                VStack(spacing: 6) {
                    HStack(spacing: 12) {
                        connectionTypeIndicator(count: deviceSummary.usbDevices, color: .blue, label: "USB")
                        connectionTypeIndicator(count: deviceSummary.thunderboltDevices, color: .purple, label: "⚡")
                        connectionTypeIndicator(count: deviceSummary.bluetoothDevices, color: .orange, label: "BT")
                    }
                    
                    Text("Connection Types")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func connectionTypeIndicator(count: Int, color: Color, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func deviceCategorySection(category: DeviceCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(.accentColor)
                
                Text(category.name)
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Text("\(category.devices.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if category.devices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No devices connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(category.devices, id: \.name) { device in
                        deviceRow(device: device)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func deviceRow(device: DetailedDevice) -> some View {
        HStack(spacing: 12) {
            // Device type icon
            Image(systemName: deviceTypeIcon(for: device.type))
                .foregroundColor(device.isActive ? .green : .gray)
                .frame(width: 20, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(device.isActive ? .primary : .secondary)
                
                Text(device.connectionType)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(device.isActive ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
                
                Text(device.isActive ? "Active" : "Idle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(device.isActive ? Color.green.opacity(0.05) : Color.clear)
        )
    }
    
    private func deviceTypeIcon(for type: String) -> String {
        switch type.lowercased() {
        case "keyboard": return "keyboard"
        case "mouse": return "computermouse"
        case "storage": return "externaldrive"
        case "camera": return "camera"
        case "monitor": return "display"
        case "audio": return "speaker.wave.2"
        case "phone": return "iphone"
        default: return "questionmark.circle"
        }
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Information")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                InfoRow(label: "USB Controller", value: "USB 3.2 Gen 2") // Simulated
                InfoRow(label: "Thunderbolt Version", value: "Thunderbolt 4") // Simulated
                InfoRow(label: "Bluetooth Version", value: "5.3") // Simulated
                InfoRow(label: "Available USB Ports", value: "2") // Simulated
                InfoRow(label: "Available TB Ports", value: "4") // Simulated
                InfoRow(label: "Power Delivery", value: "Supported") // Simulated
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Supporting Data Structures
struct DetailedDevice {
    let name: String
    let type: String
    let connectionType: String
    let isActive: Bool
}

struct DeviceCategory {
    let name: String
    let devices: [DetailedDevice]
    let icon: String
}

struct DeviceSummary {
    let totalDevices: Int
    let activeDevices: Int
    let usbDevices: Int
    let thunderboltDevices: Int
    let bluetoothDevices: Int
}

#Preview {
    AdvancedDeviceView(
        metricData: DeviceMetrics(
            devices: [],
            isLoading: false,
            error: nil
        ),
        onBack: {}
    )
}