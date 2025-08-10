//
//  MetricRemarkEngine.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation

// MARK: - Metric Remark Engine
struct MetricRemarkEngine {
    
    // MARK: - Storage Remarks
    static func generateStorageRemarks(for metrics: DiskMetrics) -> [String] {
        var remarks: [String] = []
        
        guard let bootVolume = metrics.bootVolume else { return remarks }
        
        let usagePercentage = bootVolume.usagePercentage * 100
        
        // Storage usage warnings
        if usagePercentage > 90 {
            remarks.append("Critical: Over 90% storage used. System performance may be affected.")
        } else if usagePercentage > 80 {
            remarks.append("Warning: Storage is over 80% full. Consider cleaning up files.")
        } else if usagePercentage > 70 {
            remarks.append("Your disk is getting full. Consider moving large files to external storage.")
        }
        
        // Free space recommendations
        let freeGB = Double(bootVolume.freeBytes) / (1024 * 1024 * 1024)
        if freeGB < 10 {
            remarks.append("Less than 10GB free space remaining. Immediate action recommended.")
        } else if freeGB < 50 {
            remarks.append("Low free space. Consider using storage optimization tools.")
        }
        
        return remarks
    }
    
    // MARK: - Memory Remarks
    static func generateMemoryRemarks(for metrics: MemoryMetrics) -> [String] {
        var remarks: [String] = []
        
        let usagePercentage = metrics.usagePercentage * 100
        let totalGB = Double(metrics.totalBytes) / (1024 * 1024 * 1024)
        let usedGB = Double(metrics.usedBytes) / (1024 * 1024 * 1024)
        
        // Memory pressure warnings
        if usagePercentage > 90 {
            remarks.append("Critical memory pressure detected. Close unused applications.")
        } else if usagePercentage > 80 {
            remarks.append("High memory usage detected. Consider closing some applications.")
        } else if usagePercentage > 70 {
            remarks.append("Memory usage is getting high. Monitor for performance impact.")
        }
        
        // Memory recommendations
        if totalGB < 8 {
            remarks.append("Consider upgrading to more RAM for better performance.")
        }
        
        if usedGB > totalGB * 0.8 {
            remarks.append("High compressed memory may indicate memory pressure.")
        }
        
        return remarks
    }
    
    // MARK: - Battery Remarks
    static func generateBatteryRemarks(for metrics: BatteryMetrics?) -> [String] {
        var remarks: [String] = []
        
        guard let battery = metrics else {
            remarks.append("No battery detected. Device is running on external power.")
            return remarks
        }
        
        // Battery health warnings
        if battery.percentage < 20 && !battery.isCharging {
            remarks.append("Low battery warning. Connect to power soon.")
        } else if battery.percentage < 10 {
            remarks.append("Critical battery level. Save your work immediately.")
        }
        
        // Charging status insights
        if battery.isCharging && battery.percentage > 80 {
            remarks.append("Battery is charging efficiently. Disconnect when full to preserve battery health.")
        } else if battery.isCharging && battery.percentage < 20 {
            remarks.append("Battery is charging from low level. This is normal.")
        }
        
        // Health recommendations
        if let cycleCount = battery.cycleCount {
            if cycleCount > 1000 {
                remarks.append("High battery cycle count detected. Consider battery service.")
            } else if cycleCount > 500 {
                remarks.append("Battery cycle count is moderate. Monitor battery health.")
            }
        }
        
        return remarks
    }
    
    // MARK: - CPU Remarks
    static func generateCPURemarks(for metrics: CPUMetrics) -> [String] {
        var remarks: [String] = []
        
        let usagePercentage = metrics.overallUsage * 100
        
        // CPU usage warnings
        if usagePercentage > 90 {
            remarks.append("Very high CPU usage detected. System may become unresponsive.")
        } else if usagePercentage > 70 {
            remarks.append("High CPU usage detected. Check Activity Monitor for resource-heavy processes.")
        } else if usagePercentage > 50 {
            remarks.append("Moderate CPU usage. Performance is within normal range.")
        }
        
        // Core utilization
        if !metrics.perCoreUsage.isEmpty {
            let maxCoreUsage = metrics.perCoreUsage.max() ?? 0
            if maxCoreUsage > 0.95 {
                remarks.append("One or more CPU cores are at maximum utilization.")
            }
        }
        
        return remarks
    }
    
    // MARK: - Network Remarks
    static func generateNetworkRemarks(for wifiMetrics: WiFiMetrics, speedTest: NetworkSpeedTest) -> [String] {
        var remarks: [String] = []
        
        // WiFi signal strength
        if let rssi = wifiMetrics.rssi, wifiMetrics.isConnected {
            if rssi <= -80 {
                remarks.append("Very weak WiFi signal. Consider moving closer to router.")
            } else if rssi <= -70 {
                remarks.append("Weak WiFi signal may affect network performance.")
            } else if rssi <= -60 {
                remarks.append("Fair WiFi signal strength.")
            } else if rssi <= -50 {
                remarks.append("Good WiFi signal strength.")
            } else {
                remarks.append("Excellent WiFi signal strength.")
            }
        }
        
        // Speed test insights
        if let downloadSpeed = speedTest.downloadSpeed {
            if downloadSpeed < 10 {
                remarks.append("Slow internet connection detected. Check with your ISP.")
            } else if downloadSpeed < 50 {
                remarks.append("Moderate internet speed. Consider upgrading for better performance.")
            } else if downloadSpeed > 100 {
                remarks.append("Fast internet connection detected.")
            }
            
            if let uploadSpeed = speedTest.uploadSpeed {
                let ratio = uploadSpeed / downloadSpeed
                if ratio < 0.1 {
                    remarks.append("Upload speed is significantly slower than download speed.")
                }
            }
        }
        
        return remarks
    }
    
    // MARK: - Device Remarks
    static func generateDeviceRemarks(for metrics: DeviceMetrics) -> [String] {
        var remarks: [String] = []
        
        let deviceCount = metrics.devices.count
        
        if deviceCount > 10 {
            remarks.append("Many devices connected. Monitor power consumption on battery.")
        } else if deviceCount > 5 {
            remarks.append("Several devices connected. May impact system performance.")
        } else if deviceCount == 0 {
            remarks.append("No external devices detected.")
        }
        
        // Device type insights
        let storageDevices = metrics.devices.filter { $0.type == .storage }
        if storageDevices.count > 2 {
            remarks.append("Multiple storage devices connected. Ensure proper ejection.")
        }
        
        return remarks
    }
    
    // MARK: - Network Usage Remarks
    static func generateNetworkUsageRemarks(for metrics: NetworkUsageMetrics) -> [String] {
        var remarks: [String] = []
        
        let totalUsageGB = Double(metrics.downloaded + metrics.uploaded) / (1024 * 1024 * 1024)
        let downloadedGB = Double(metrics.downloaded) / (1024 * 1024 * 1024)
        
        if totalUsageGB > 10 {
            remarks.append("High daily data usage detected. Monitor if on metered connection.")
        } else if totalUsageGB > 5 {
            remarks.append("Moderate daily data usage.")
        }
        
        if downloadedGB > 5 {
            remarks.append("Large amount of data downloaded today. Check for background apps.")
        }
        
        return remarks
    }
}