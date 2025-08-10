//
//  NetworkInfoService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation
import SystemConfiguration
import Darwin

struct NetworkConnectionInfo {
    let ipAddress: String?
    let routerIP: String?
    let dnsServers: [String]
    let subnetMask: String?
    let interfaceType: String?
    let connectionType: String?
    let channel: String?
    let security: String?
}

protocol NetworkInfoServiceProtocol {
    func getNetworkConnectionInfo() async -> NetworkConnectionInfo
}

final class NetworkInfoService: NetworkInfoServiceProtocol, @unchecked Sendable {
    
    func getNetworkConnectionInfo() async -> NetworkConnectionInfo {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let info = self.fetchNetworkInfo()
                continuation.resume(returning: info)
            }
        }
    }
    
    private func fetchNetworkInfo() -> NetworkConnectionInfo {
        var ipAddress: String?
        var routerIP: String?
        var dnsServers: [String] = []
        var subnetMask: String?
        var interfaceType: String?
        var connectionType: String?
        var channel: String?
        var security: String?
        
        // Get primary interface information
        if let primaryInterface = getPrimaryInterface() {
            ipAddress = getIPAddress(for: primaryInterface)
            subnetMask = getSubnetMask(for: primaryInterface)
            interfaceType = getInterfaceType(primaryInterface)
            
            // Get router IP from route table
            routerIP = getDefaultGateway()
            
            // Get DNS servers
            dnsServers = getDNSServers()
            
            // For WiFi connections, try to get additional details
            // Check interface type to detect WiFi vs Ethernet
            if interfaceType?.contains("WiFi") == true || interfaceType?.contains("Wi-Fi") == true {
                connectionType = getWiFiConnectionType()
                channel = getWiFiChannel()
                security = getWiFiSecurity()
            } else if primaryInterface.hasPrefix("en") {
                connectionType = "Ethernet"
            }
        }
        
        return NetworkConnectionInfo(
            ipAddress: ipAddress,
            routerIP: routerIP,
            dnsServers: dnsServers,
            subnetMask: subnetMask,
            interfaceType: interfaceType,
            connectionType: connectionType,
            channel: channel,
            security: security
        )
    }
    
    private func getPrimaryInterface() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "getPrimaryInterface" as CFString, nil, nil) else {
            return nil
        }
        
        guard let globalState = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any] else {
            return nil
        }
        
        return globalState["PrimaryInterface"] as? String
    }
    
    private func getIPAddress(for interface: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interfaceAddr = ptr?.pointee
            let addrFamily = interfaceAddr?.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: (interfaceAddr?.ifa_name)!)
                if name == interface {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(interfaceAddr?.ifa_addr, socklen_t((interfaceAddr?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                        return String(cString: hostname)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func getSubnetMask(for interface: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interfaceAddr = ptr?.pointee
            let addrFamily = interfaceAddr?.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: (interfaceAddr?.ifa_name)!)
                if name == interface, let netmask = interfaceAddr?.ifa_netmask {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(netmask, socklen_t(netmask.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                        return String(cString: hostname)
                    }
                }
            }
        }
        
        return nil
    }
    
    private func getInterfaceType(_ interface: String) -> String? {
        // Use ifconfig to get interface details
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
        process.arguments = [interface]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if output.contains("type Wi-Fi") || output.contains("media: autoselect") {
                    return "Wi-Fi"
                } else if output.contains("media: autoselect") {
                    return "Ethernet"
                } else if interface.hasPrefix("en") {
                    return "Ethernet"
                }
            }
        } catch {
            // Fallback based on interface name
            if interface.hasPrefix("en") {
                return interface.hasSuffix("0") ? "Ethernet" : "Wi-Fi"
            }
        }
        
        return "Unknown"
    }
    
    private func getDefaultGateway() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
        process.arguments = ["-rn", "-f", "inet"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.hasPrefix("default") || line.hasPrefix("0.0.0.0") {
                        let components = line.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                        if components.count >= 2 {
                            return components[1]
                        }
                    }
                }
            }
        } catch {}
        
        return nil
    }
    
    private func getDNSServers() -> [String] {
        guard let store = SCDynamicStoreCreate(nil, "getDNSServers" as CFString, nil, nil) else {
            return []
        }
        
        guard let dnsSettings = SCDynamicStoreCopyValue(store, "State:/Network/Global/DNS" as CFString) as? [String: Any] else {
            return []
        }
        
        if let servers = dnsSettings["ServerAddresses"] as? [String] {
            return servers
        }
        
        return []
    }
    
    private func getWiFiConnectionType() -> String {
        // Use airport command to get WiFi details
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport")
        process.arguments = ["-I"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("802.11ac") {
                        return "WiFi 5 (802.11ac)"
                    } else if line.contains("802.11ax") {
                        return "WiFi 6 (802.11ax)"
                    } else if line.contains("802.11n") {
                        return "WiFi 4 (802.11n)"
                    }
                }
                return "WiFi"
            }
        } catch {}
        
        return "WiFi"
    }
    
    private func getWiFiChannel() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath:
            "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
        )
        process.arguments = ["-I"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if let line = output.components(separatedBy: .newlines)
                    .first(where: { $0.lowercased().contains("channel:") }) {

                    let channelNumber = line
                        .components(separatedBy: ":")
                        .last?
                        .trimmingCharacters(in: .whitespaces)

                    if let ch = channelNumber {
                        if ch.contains("5") { return "\(ch) (5GHz)" }
                        else { return "\(ch) (2.4GHz)" }
                    }
                }
            }
        } catch {}
        return "Unknown"
    }
    
    private func getWiFiSecurity() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath:
            "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
        )
        process.arguments = ["-I"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lower = output.lowercased()

                if lower.contains("wpa3") || lower.contains("wpa3-") { return "WPA3" }
                if lower.contains("wpa2") || lower.contains("wpa2-") { return "WPA2" }
                if lower.contains("wpa") || lower.contains("wpa-") { return "WPA" }
                if lower.contains("wep") { return "WEP" }
            }
        } catch {}

        return "Unknown"
    }
}