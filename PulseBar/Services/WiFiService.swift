//
//  WiFiService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine
import CoreWLAN

final class WiFiService: WiFiServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<WiFiMetrics, Never>(WiFiMetrics())
    
    var metricsPublisher: AnyPublisher<WiFiMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    init() {
        // Initialize with first reading
        Task {
            await updateMetrics()
        }
    }
    
    func updateMetrics() async {
        do {
            let wifiMetrics = try await fetchWiFiMetrics()
            await MainActor.run {
                metricsSubject.send(wifiMetrics)
            }
        } catch {
            print("WiFi Service Error: \(error)")
            let errorMetrics = WiFiMetrics(
                ssid: nil,
                bssid: nil,
                rssi: nil,
                linkSpeed: nil,
                isConnected: false,
                isLoading: false,
                error: error.localizedDescription
            )
            await MainActor.run {
                metricsSubject.send(errorMetrics)
            }
        }
    }
    
    private func fetchWiFiMetrics() async throws -> WiFiMetrics {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let metrics = try self.getWiFiInfo()
                    continuation.resume(returning: metrics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getWiFiInfo() throws -> WiFiMetrics {
        // Try CoreWLAN first
        do {
            return try getCoreWLANInfo()
        } catch {
            print("CoreWLAN failed: \(error), trying command line approach...")
            // Fallback to command-line approach - doesn't throw errors
            return getWiFiInfoViaCommands()
        }
    }
    
    private func getCoreWLANInfo() throws -> WiFiMetrics {
        // Check if we have a WiFi client at all
        let wifiClient = CWWiFiClient.shared()
        
        // First try to get default interface
        if let interface = wifiClient.interface() {
            return try getWiFiInfoFromInterface(interface)
        }
        
        // If default interface is nil, try to get available interfaces
        let interfaces = wifiClient.interfaces()
        if let interfaces = interfaces, !interfaces.isEmpty {
            // Try to find a WiFi interface (usually en0 or en1)
            for interface in interfaces {
                if let interfaceName = interface.interfaceName,
                   (interfaceName.hasPrefix("en") || interfaceName.contains("Wi-Fi")) {
                    return try getWiFiInfoFromInterface(interface)
                }
            }
            
            // If no good interface found, try the first one
            if let firstInterface = interfaces.first {
                return try getWiFiInfoFromInterface(firstInterface)
            }
        }
        
        throw WiFiServiceError.noWiFiInterface
    }
    
    private func getWiFiInfoViaCommands() -> WiFiMetrics {
        do {
            // Use system_profiler for more reliable WiFi information
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            process.arguments = ["SPAirPortDataType"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                print("WiFi Debug: No output from system_profiler command")
                return createNotConnectedWiFiMetrics()
            }
            
            print("WiFi Debug: Parsing system_profiler output...")
            return parseSystemProfilerWiFiOutput(output)
            
        } catch {
            print("WiFi Debug: system_profiler execution failed: \(error)")
            return createNotConnectedWiFiMetrics()
        }
    }
    
    private func parseSystemProfilerWiFiOutput(_ output: String) -> WiFiMetrics {
        let lines = output.components(separatedBy: .newlines)
        
        var isConnected = false
        var ssid: String?
        var rssi: Int?
        var linkSpeed: Double?
        var inCurrentNetworkInfo = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Look for Status: Connected
            if trimmedLine.hasPrefix("Status: ") {
                let status = trimmedLine.replacingOccurrences(of: "Status: ", with: "")
                isConnected = status.contains("Connected")
                print("WiFi Debug: WiFi status: \(status)")
                continue
            }
            
            // Look for "Current Network Information:"
            if trimmedLine == "Current Network Information:" {
                inCurrentNetworkInfo = true
                print("WiFi Debug: Found Current Network Information section")
                continue
            }
            
            // Reset flag when we exit current network info section
            if inCurrentNetworkInfo && !line.hasPrefix("            ") && !line.hasPrefix("          Current Network Information:") {
                inCurrentNetworkInfo = false
            }
            
            // Look for network name when in current network info section
            if inCurrentNetworkInfo && trimmedLine.hasSuffix(":") && !trimmedLine.contains(" ") && !trimmedLine.isEmpty {
                ssid = String(trimmedLine.dropLast())
                print("WiFi Debug: Found network name: \(ssid ?? "nil")")
                continue
            }
            
            // Look for Signal / Noise information (only when connected)
            if isConnected && trimmedLine.hasPrefix("Signal / Noise: ") {
                let signalInfo = trimmedLine.replacingOccurrences(of: "Signal / Noise: ", with: "")
                // Format: "-53 dBm / -96 dBm"
                let components = signalInfo.components(separatedBy: " / ")
                if let firstComponent = components.first {
                    let rssiString = firstComponent.replacingOccurrences(of: " dBm", with: "")
                    rssi = Int(rssiString)
                }
                print("WiFi Debug: Found signal strength: \(rssi ?? 0) dBm")
                continue
            }
            
            // Look for Transmit Rate (only when connected)
            if isConnected && trimmedLine.hasPrefix("Transmit Rate: ") {
                let rateString = trimmedLine.replacingOccurrences(of: "Transmit Rate: ", with: "")
                linkSpeed = Double(rateString)
                print("WiFi Debug: Found transmit rate: \(linkSpeed ?? 0) Mbps")
                continue
            }
        }
        
        if isConnected && ssid != nil {
            print("WiFi Debug: Successfully parsed WiFi connection - SSID: \(ssid!), RSSI: \(rssi ?? 0), Speed: \(linkSpeed ?? 0)")
            return WiFiMetrics(
                ssid: ssid,
                bssid: nil,
                rssi: rssi,
                linkSpeed: linkSpeed,
                isConnected: true,
                isLoading: false,
                error: nil
            )
        } else {
            print("WiFi Debug: No active WiFi connection found (Connected: \(isConnected), SSID: \(ssid ?? "nil"))")
            return createNotConnectedWiFiMetrics()
        }
    }
    
    private func createNotConnectedWiFiMetrics() -> WiFiMetrics {
        return WiFiMetrics(
            ssid: nil,
            bssid: nil,
            rssi: nil,
            linkSpeed: nil,
            isConnected: false,
            isLoading: false,
            error: nil
        )
    }
    
    private func getWiFiInfoFromInterface(_ interface: CWInterface) throws -> WiFiMetrics {
        // Check if WiFi is powered on
        guard interface.powerOn() else {
            return WiFiMetrics(
                ssid: nil,
                bssid: nil,
                rssi: nil,
                linkSpeed: nil,
                isConnected: false,
                isLoading: false,
                error: "WiFi is turned off"
            )
        }
        
        // Get current WiFi network info
        guard let ssid = interface.ssid(),
              !ssid.isEmpty else {
            return WiFiMetrics(
                ssid: nil,
                bssid: nil,
                rssi: nil,
                linkSpeed: nil,
                isConnected: false,
                isLoading: false,
                error: nil
            )
        }
        
        // Extract network details
        let bssid = interface.bssid()
        let rssi = interface.rssiValue()
        let linkSpeed = interface.transmitRate()
        
        return WiFiMetrics(
            ssid: ssid,
            bssid: bssid,
            rssi: Int(rssi),
            linkSpeed: linkSpeed,
            isConnected: true,
            isLoading: false,
            error: nil
        )
    }
}

enum WiFiServiceError: Error, LocalizedError {
    case noWiFiInterface
    case permissionDenied
    case wifiTurnedOff
    
    var errorDescription: String? {
        switch self {
        case .noWiFiInterface:
            return "No WiFi interface available"
        case .permissionDenied:
            return "Location permission required for WiFi info"
        case .wifiTurnedOff:
            return "WiFi is turned off"
        }
    }
}