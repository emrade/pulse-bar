//
//  Metrics.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation

// MARK: - Main Metrics Snapshot
struct MetricsSnapshot {
    let cpu: CPUMetrics
    let memory: MemoryMetrics
    let disk: DiskMetrics
    let battery: BatteryMetrics?
    let wifi: WiFiMetrics
    let devices: DeviceMetrics
    let networkUsage: NetworkUsageMetrics
    let timestamp: Date
    
    init(
        cpu: CPUMetrics = CPUMetrics(),
        memory: MemoryMetrics = MemoryMetrics(),
        disk: DiskMetrics = DiskMetrics(),
        battery: BatteryMetrics? = nil,
        wifi: WiFiMetrics = WiFiMetrics(),
        devices: DeviceMetrics = DeviceMetrics(),
        networkUsage: NetworkUsageMetrics = NetworkUsageMetrics(),
        timestamp: Date = Date()
    ) {
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.battery = battery
        self.wifi = wifi
        self.devices = devices
        self.networkUsage = networkUsage
        self.timestamp = timestamp
    }
}

// MARK: - CPU Metrics
struct CPUMetrics {
    let overallUsage: Double // 0.0 to 1.0 (0% to 100%)
    let perCoreUsage: [Double] // Array of per-core usage
    let isLoading: Bool
    let error: String?
    
    init(
        overallUsage: Double = 0.0,
        perCoreUsage: [Double] = [],
        isLoading: Bool = true,
        error: String? = nil
    ) {
        self.overallUsage = overallUsage
        self.perCoreUsage = perCoreUsage
        self.isLoading = isLoading
        self.error = error
    }
    
    var formattedOverallUsage: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        return String(format: "Load: %.0f%%", overallUsage * 100)
    }
}

// MARK: - Memory Metrics
struct MemoryMetrics {
    let totalBytes: UInt64
    let usedBytes: UInt64
    let cachedBytes: UInt64
    let freeBytes: UInt64
    let isLoading: Bool
    let error: String?
    
    init(
        totalBytes: UInt64 = 0,
        usedBytes: UInt64 = 0,
        cachedBytes: UInt64 = 0,
        freeBytes: UInt64 = 0,
        isLoading: Bool = true,
        error: String? = nil
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.cachedBytes = cachedBytes
        self.freeBytes = freeBytes
        self.isLoading = isLoading
        self.error = error
    }
    
    var formattedUsed: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        return ByteCountFormatter.string(fromByteCount: Int64(usedBytes), countStyle: .binary)
    }
    
    var formattedTotal: String {
        return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .binary)
    }
    
    var formattedAvailable: String {
        let availableBytes = freeBytes + cachedBytes // Free + reclaimable memory
        return ByteCountFormatter.string(fromByteCount: Int64(availableBytes), countStyle: .binary)
    }
    
    var formattedUsedWithAvailable: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        return "\(formattedUsed) used • \(formattedAvailable) available"
    }
    
    var usagePercentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}

// MARK: - Disk Metrics
struct DiskMetrics {
    let volumes: [VolumeInfo]
    let isLoading: Bool
    let error: String?
    
    init(
        volumes: [VolumeInfo] = [],
        isLoading: Bool = true,
        error: String? = nil
    ) {
        self.volumes = volumes
        self.isLoading = isLoading
        self.error = error
    }
    
    var bootVolume: VolumeInfo? {
        return volumes.first { $0.isBootVolume }
    }
    
    var formattedBootFree: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        guard let boot = bootVolume else { return "No boot volume" }
        return ByteCountFormatter.string(fromByteCount: Int64(boot.freeBytes), countStyle: .binary) + " free"
    }
    
    var formattedBootUsage: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        guard let boot = bootVolume else { return "No boot volume" }
        let usedFormatted = ByteCountFormatter.string(fromByteCount: Int64(boot.usedBytes), countStyle: .binary)
        let freeFormatted = ByteCountFormatter.string(fromByteCount: Int64(boot.freeBytes), countStyle: .binary)
        return "\(usedFormatted) used • \(freeFormatted) free"
    }
    
    var formattedBootTotal: String {
        guard let boot = bootVolume else { return "" }
        return ByteCountFormatter.string(fromByteCount: Int64(boot.totalBytes), countStyle: .binary)
    }
}

struct VolumeInfo {
    let name: String
    let mountPoint: String
    let totalBytes: UInt64
    let freeBytes: UInt64
    let isBootVolume: Bool
    let isExternal: Bool
    
    var usedBytes: UInt64 {
        return totalBytes > freeBytes ? totalBytes - freeBytes : 0
    }
    
    var usagePercentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}

// MARK: - Battery Metrics
struct BatteryMetrics {
    let percentage: Int // 0 to 100
    let isCharging: Bool
    let timeRemaining: TimeInterval? // seconds
    let health: String?
    let cycleCount: Int?
    let temperature: Double? // in Celsius
    let maxCapacity: Double? // as percentage of design capacity
    let isLoading: Bool
    let error: String?
    
    init(
        percentage: Int = 0,
        isCharging: Bool = false,
        timeRemaining: TimeInterval? = nil,
        health: String? = nil,
        cycleCount: Int? = nil,
        temperature: Double? = nil,
        maxCapacity: Double? = nil,
        isLoading: Bool = true,
        error: String? = nil
    ) {
        self.percentage = percentage
        self.isCharging = isCharging
        self.timeRemaining = timeRemaining
        self.health = health
        self.cycleCount = cycleCount
        self.temperature = temperature
        self.maxCapacity = maxCapacity
        self.isLoading = isLoading
        self.error = error
    }
    
    var formattedStatus: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        
        var status = "\(percentage)%"
        if isCharging {
            status += " (Charging)"
        } else if let timeRemaining = timeRemaining, timeRemaining > 0 {
            let hours = Int(timeRemaining) / 3600
            let minutes = (Int(timeRemaining) % 3600) / 60
            status += " (\(hours)h \(minutes)m)"
        }
        return status
    }
}

// MARK: - WiFi Metrics
struct WiFiMetrics {
    let ssid: String?
    let bssid: String?
    let rssi: Int? // Signal strength in dBm
    let linkSpeed: Double? // Mbps
    let isConnected: Bool
    let isLoading: Bool
    let error: String?
    
    init(
        ssid: String? = nil,
        bssid: String? = nil,
        rssi: Int? = nil,
        linkSpeed: Double? = nil,
        isConnected: Bool = false,
        isLoading: Bool = true,
        error: String? = nil
    ) {
        self.ssid = ssid
        self.bssid = bssid
        self.rssi = rssi
        self.linkSpeed = linkSpeed
        self.isConnected = isConnected
        self.isLoading = isLoading
        self.error = error
    }
    
    var formattedStatus: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        if !isConnected { return "Not connected" }
        
        guard let ssid = ssid else { return "Connected" }
        if let rssi = rssi {
            return "\(ssid) (\(rssi) dBm)"
        }
        return ssid
    }
    
    var signalQuality: String {
        guard let rssi = rssi else { return "Unknown" }
        if rssi >= -30 { return "Excellent" }
        if rssi >= -50 { return "Good" }
        if rssi >= -60 { return "Fair" }
        if rssi >= -70 { return "Weak" }
        return "Very Weak"
    }
}

// MARK: - Device Metrics
struct DeviceMetrics {
    let devices: [ConnectedDevice]
    let isLoading: Bool
    let error: String?
    
    init(
        devices: [ConnectedDevice] = [],
        isLoading: Bool = true,
        error: String? = nil
    ) {
        self.devices = devices
        self.isLoading = isLoading
        self.error = error
    }
    
    var formattedCount: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        return "\(devices.count) connected"
    }

    var formattedDetails: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        if devices.isEmpty { return "No devices connected" }

        return devices.map { device in
            "\(device.name) (\(device.type.displayName))"
        }.joined(separator: "\n")
    }
}

struct ConnectedDevice {
    let name: String
    let type: DeviceType
    let vendorID: String?
    let productID: String?
    let mountPoint: String? // For storage devices
    
    enum DeviceType: Equatable {
        case usb
        case thunderbolt
        case storage
        case display
        case other(String)
        
        var displayName: String {
            switch self {
            case .usb: return "USB"
            case .thunderbolt: return "Thunderbolt"
            case .storage: return "Storage"
            case .display: return "Display"
            case .other(let name): return name
            }
        }
    }
}

// MARK: - Network Speed Test
struct NetworkSpeedTest {
    let downloadSpeed: Double? // Mbps
    let uploadSpeed: Double? // Mbps
    let latency: Double? // ms
    let isRunning: Bool
    let progress: Double // 0.0 to 1.0
    let error: String?
    
    init(
        downloadSpeed: Double? = nil,
        uploadSpeed: Double? = nil,
        latency: Double? = nil,
        isRunning: Bool = false,
        progress: Double = 0.0,
        error: String? = nil
    ) {
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.latency = latency
        self.isRunning = isRunning
        self.progress = progress
        self.error = error
    }
    
    var formattedResult: String {
        if isRunning {
            return "Testing... \(Int(progress * 100))%"
        }
        if let errorMessage = error {
            return "Error: \(errorMessage)"
        }
        if let download = downloadSpeed {
            if let upload = uploadSpeed {
                return "↓ \(String(format: "%.0f", download)) Mbps ↑ \(String(format: "%.0f", upload)) Mbps"
            } else {
                return "↓ \(String(format: "%.0f", download)) Mbps"
            }
        }
        return "Test Speed"
    }
}

// MARK: - Network Connection Types
enum NetworkConnectionType {
    case wifi
    case ethernet  
    case other
}

// MARK: - Network Usage Metrics
struct NetworkUsageMetrics {
    let downloaded: UInt64
    let uploaded: UInt64
    let isLoading: Bool
    let error: String?

    init(
        downloaded: UInt64 = 0,
        uploaded: UInt64 = 0,
        isLoading: Bool = true,
        error: String? = nil
    ) {
        self.downloaded = downloaded
        self.uploaded = uploaded
        self.isLoading = isLoading
        self.error = error
    }

    var formattedDownloaded: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        return ByteCountFormatter.string(fromByteCount: Int64(downloaded), countStyle: .file)
    }

    var formattedUploaded: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        return ByteCountFormatter.string(fromByteCount: Int64(uploaded), countStyle: .file)
    }

    var formattedTotal: String {
        if isLoading { return "Loading..." }
        if error != nil { return "Error" }
        return "↓ \(formattedDownloaded) / ↑ \(formattedUploaded)"
    }
}