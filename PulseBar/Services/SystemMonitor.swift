//
//  SystemMonitor.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

@MainActor
class SystemMonitor: ObservableObject {
    @Published var snapshot = MetricsSnapshot()
    @Published var networkSpeedTest = NetworkSpeedTest()
    
    // Service instances
    private let cpuService: CPUServiceProtocol
    let memoryService: MemoryServiceProtocol
    private let diskService: DiskServiceProtocol
    private let batteryService: BatteryServiceProtocol
    private let wifiService: WiFiServiceProtocol
    private let deviceService: DeviceServiceProtocol
    private let networkService: NetworkServiceProtocol
    let networkUsageService: NetworkUsageServiceProtocol
    let networkInfoService: NetworkInfoServiceProtocol
    
    // Timers for different polling intervals
    private var cpuTimer: Timer?
    private var memoryTimer: Timer?
    private var diskTimer: Timer?
    private var batteryTimer: Timer?
    private var wifiTimer: Timer?
    private var deviceTimer: Timer?
    private var networkUsageTimer: Timer?
    
    // Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Singleton instance
    static let shared = SystemMonitor()
    
    init(
        cpuService: CPUServiceProtocol = CPUService(),
        memoryService: MemoryServiceProtocol = MemoryService(),
        diskService: DiskServiceProtocol = DiskService(),
        batteryService: BatteryServiceProtocol = BatteryService(),
        wifiService: WiFiServiceProtocol = WiFiService(),
        deviceService: DeviceServiceProtocol = DeviceService(),
        networkService: NetworkServiceProtocol = NetworkService(),
        networkUsageService: NetworkUsageServiceProtocol = NetworkUsageService(),
        networkInfoService: NetworkInfoServiceProtocol = NetworkInfoService()
    ) {
        self.cpuService = cpuService
        self.memoryService = memoryService
        self.diskService = diskService
        self.batteryService = batteryService
        self.wifiService = wifiService
        self.deviceService = deviceService
        self.networkService = networkService
        self.networkUsageService = networkUsageService
        self.networkInfoService = networkInfoService
        
        setupSubscriptions()
        startPolling()
    }
    
    deinit {
        // Clean up resources - timers will be deallocated with the object
        cancellables.removeAll()
    }
    
    private func setupSubscriptions() {
        // CPU updates
        cpuService.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cpuMetrics in
                self?.updateCPU(cpuMetrics)
            }
            .store(in: &cancellables)
        
        // Memory updates
        memoryService.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] memoryMetrics in
                self?.updateMemory(memoryMetrics)
            }
            .store(in: &cancellables)
        
        // Disk updates
        diskService.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] diskMetrics in
                self?.updateDisk(diskMetrics)
            }
            .store(in: &cancellables)
        
        // Battery updates
        batteryService.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] batteryMetrics in
                self?.updateBattery(batteryMetrics)
            }
            .store(in: &cancellables)
        
        // WiFi updates
        wifiService.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] wifiMetrics in
                self?.updateWiFi(wifiMetrics)
            }
            .store(in: &cancellables)
        
        // Device updates
        deviceService.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deviceMetrics in
                self?.updateDevices(deviceMetrics)
            }
            .store(in: &cancellables)
        
        // Network speed test updates
        networkService.speedTestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speedTest in
                self?.networkSpeedTest = speedTest
            }
            .store(in: &cancellables)

        // Network usage updates
        networkUsageService.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] networkUsage in
                self?.updateNetworkUsage(networkUsage)
            }
            .store(in: &cancellables)
    }
    
    private func startPolling() {
        // CPU polling (1.5s interval)
        cpuTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            Task {
                await self.cpuService.updateMetrics()
            }
        }
        
        // Memory polling (2s interval)
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await self.memoryService.updateMetrics()
            }
        }
        
        // Disk polling (10s interval)
        diskTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task {
                await self.diskService.updateMetrics()
            }
        }
        
        // Battery polling (10s interval)
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task {
                await self.batteryService.updateMetrics()
            }
        }
        
        // WiFi polling (5s interval)
        wifiTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task {
                await self.wifiService.updateMetrics()
                await self.updateConnectionType()
            }
        }
        
        // Device polling (5s interval)
        deviceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task {
                await self.deviceService.updateMetrics()
            }
        }

        // Network usage polling (5s interval)
        networkUsageTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task {
                await self.networkUsageService.updateMetrics()
            }
        }
        
        // Initial update
        Task {
            await updateAllMetrics()
            await updateConnectionType()
        }
    }
    
    private func stopPolling() {
        cpuTimer?.invalidate()
        memoryTimer?.invalidate()
        diskTimer?.invalidate()
        batteryTimer?.invalidate()
        wifiTimer?.invalidate()
        deviceTimer?.invalidate()
        networkUsageTimer?.invalidate()
        
        cpuTimer = nil
        memoryTimer = nil
        diskTimer = nil
        batteryTimer = nil
        wifiTimer = nil
        deviceTimer = nil
        networkUsageTimer = nil
    }
    
    private func updateAllMetrics() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.cpuService.updateMetrics() }
            group.addTask { await self.memoryService.updateMetrics() }
            group.addTask { await self.diskService.updateMetrics() }
            group.addTask { await self.batteryService.updateMetrics() }
            group.addTask { await self.wifiService.updateMetrics() }
            group.addTask { await self.deviceService.updateMetrics() }
            group.addTask { await self.networkUsageService.updateMetrics() }
        }
    }
    
    // MARK: - Update Methods
    private func updateCPU(_ cpu: CPUMetrics) {
        snapshot = MetricsSnapshot(
            cpu: cpu,
            memory: snapshot.memory,
            disk: snapshot.disk,
            battery: snapshot.battery,
            wifi: snapshot.wifi,
            devices: snapshot.devices,
            networkUsage: snapshot.networkUsage,
            timestamp: Date()
        )
    }
    
    private func updateMemory(_ memory: MemoryMetrics) {
        snapshot = MetricsSnapshot(
            cpu: snapshot.cpu,
            memory: memory,
            disk: snapshot.disk,
            battery: snapshot.battery,
            wifi: snapshot.wifi,
            devices: snapshot.devices,
            networkUsage: snapshot.networkUsage,
            timestamp: Date()
        )
    }
    
    private func updateDisk(_ disk: DiskMetrics) {
        snapshot = MetricsSnapshot(
            cpu: snapshot.cpu,
            memory: snapshot.memory,
            disk: disk,
            battery: snapshot.battery,
            wifi: snapshot.wifi,
            devices: snapshot.devices,
            networkUsage: snapshot.networkUsage,
            timestamp: Date()
        )
    }
    
    private func updateBattery(_ battery: BatteryMetrics?) {
        snapshot = MetricsSnapshot(
            cpu: snapshot.cpu,
            memory: snapshot.memory,
            disk: snapshot.disk,
            battery: battery,
            wifi: snapshot.wifi,
            devices: snapshot.devices,
            networkUsage: snapshot.networkUsage,
            timestamp: Date()
        )
    }
    
    private func updateWiFi(_ wifi: WiFiMetrics) {
        snapshot = MetricsSnapshot(
            cpu: snapshot.cpu,
            memory: snapshot.memory,
            disk: snapshot.disk,
            battery: snapshot.battery,
            wifi: wifi,
            devices: snapshot.devices,
            networkUsage: snapshot.networkUsage,
            timestamp: Date()
        )
    }
    
    private func updateDevices(_ devices: DeviceMetrics) {
        snapshot = MetricsSnapshot(
            cpu: snapshot.cpu,
            memory: snapshot.memory,
            disk: snapshot.disk,
            battery: snapshot.battery,
            wifi: snapshot.wifi,
            devices: devices,
            networkUsage: snapshot.networkUsage,
            timestamp: Date()
        )
    }

    private func updateNetworkUsage(_ networkUsage: NetworkUsageMetrics) {
        snapshot = MetricsSnapshot(
            cpu: snapshot.cpu,
            memory: snapshot.memory,
            disk: snapshot.disk,
            battery: snapshot.battery,
            wifi: snapshot.wifi,
            devices: snapshot.devices,
            networkUsage: networkUsage,
            timestamp: Date()
        )
    }
    
    // MARK: - Network Connection Detection
    @Published var activeConnectionType: NetworkConnectionType = .other
    
    func updateConnectionType() async {
        let connectionType: NetworkConnectionType
        
        // Check if WiFi is connected and active
        if snapshot.wifi.isConnected {
            connectionType = .wifi
        } else {
            // Check for active ethernet connection
            let hasEthernet = await checkEthernetConnection()
            connectionType = hasEthernet ? .ethernet : .other
        }
        
        await MainActor.run {
            activeConnectionType = connectionType
        }
    }
    
    private func checkEthernetConnection() async -> Bool {
        do {
            // First, get list of ethernet hardware ports
            let ethernetInterfaces = try await getEthernetInterfaces()
            
            // Check if any ethernet interface is active
            for interface in ethernetInterfaces {
                let isActive = try await checkInterfaceStatus(interface)
                if isActive {
                    return true
                }
            }
            
            return false
        } catch {
            return false
        }
    }
    
    private func getEthernetInterfaces() async throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        
        // Validate and sanitize arguments
        let sanitizedArguments = sanitizeNetworkArguments(["-listallhardwareports"])
        process.arguments = sanitizedArguments
        
        // Set secure environment
        process.environment = createSecureNetworkEnvironment()
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Capture errors
        
        try process.run()
        
        // Implement timeout mechanism
        let timeoutResult = try await waitForNetworkProcessWithTimeout(task: process, pipe: pipe, timeout: 10.0)
        
        guard timeoutResult.success && process.terminationStatus == 0 else {
            if !timeoutResult.success {
                print("SystemMonitor: networksetup process timed out")
                process.terminate()
            }
            throw NetworkProcessError.processTimeout
        }
        
        guard let output = String(data: timeoutResult.data, encoding: .utf8) else { 
            throw NetworkProcessError.invalidOutput
        }
        
        var ethernetInterfaces: [String] = []
        let lines = output.components(separatedBy: .newlines)
        
        for i in 0..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.contains("Ethernet") && i + 1 < lines.count {
                let deviceLine = lines[i + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                if deviceLine.hasPrefix("Device:") {
                    let device = deviceLine.replacingOccurrences(of: "Device:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    // Validate device name format
                    if isValidInterfaceName(device) {
                        ethernetInterfaces.append(device)
                    }
                }
            }
        }
        
        return ethernetInterfaces
    }
    
    private func checkInterfaceStatus(_ interface: String) async throws -> Bool {
        // Validate interface name before using it
        guard isValidInterfaceName(interface) else {
            print("SystemMonitor: Invalid interface name: \(interface)")
            return false
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
        
        // Validate and sanitize arguments
        let sanitizedArguments = sanitizeNetworkArguments([interface])
        process.arguments = sanitizedArguments
        
        // Set secure environment
        process.environment = createSecureNetworkEnvironment()
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Capture errors
        
        try process.run()
        
        // Implement timeout mechanism
        let timeoutResult = try await waitForNetworkProcessWithTimeout(task: process, pipe: pipe, timeout: 5.0)
        
        guard timeoutResult.success && process.terminationStatus == 0 else {
            if !timeoutResult.success {
                print("SystemMonitor: ifconfig process timed out for interface: \(interface)")
                process.terminate()
            }
            return false
        }
        
        guard let output = String(data: timeoutResult.data, encoding: .utf8) else { 
            return false
        }
        
        // Check if interface is up and has an IP address
        return output.contains("status: active") || (output.contains("UP") && output.contains("inet "))
    }
    
    var networkDisplayInfo: (icon: String, title: String, connectionDetail: String?) {
        switch activeConnectionType {
        case .wifi:
            return (
                icon: snapshot.wifi.isConnected ? "wifi" : "wifi.slash",
                title: "Network",
                connectionDetail: snapshot.wifi.isConnected ? "Wi-Fi" : nil
            )
        case .ethernet:
            return (
                icon: "ethernet",
                title: "Network", 
                connectionDetail: "Ethernet"
            )
        case .other:
            return (
                icon: "network",
                title: "Network",
                connectionDetail: nil
            )
        }
    }
    
    // MARK: - Public Methods
    func runSpeedTest() {
        Task {
            await networkService.runSpeedTest()
        }
    }
    
    func cancelSpeedTest() {
        Task {
            await networkService.cancelSpeedTest()
        }
    }
    
    func refreshAllMetrics() {
        Task {
            await updateAllMetrics()
        }
    }
    
    func resetDailyDataUsage() {
        Task {
            await networkUsageService.resetDailyUsage()
        }
    }
    
    func stop() {
        stopPolling()
    }
    
    // MARK: - Security Helper Methods
    
    private func sanitizeNetworkArguments(_ arguments: [String]) -> [String] {
        return arguments.compactMap { arg in
            // Remove any potentially dangerous characters
            let sanitized = arg.replacingOccurrences(of: ";", with: "")
                              .replacingOccurrences(of: "|", with: "")
                              .replacingOccurrences(of: "&", with: "")
                              .replacingOccurrences(of: "$", with: "")
                              .replacingOccurrences(of: "`", with: "")
                              .replacingOccurrences(of: ">", with: "")
                              .replacingOccurrences(of: "<", with: "")
                              .replacingOccurrences(of: "(", with: "")
                              .replacingOccurrences(of: ")", with: "")
            
            // Validate argument format
            if sanitized.hasPrefix("-") {
                // Whitelist allowed networksetup options
                let validOptions = ["-listallhardwareports", "-getinfo", "-listnetworkserviceorder"]
                guard validOptions.contains(sanitized) else {
                    print("SystemMonitor: Invalid network option: \(sanitized)")
                    return nil
                }
            } else {
                // For interface names, validate format
                guard isValidInterfaceName(sanitized) else {
                    print("SystemMonitor: Invalid interface name: \(sanitized)")
                    return nil
                }
            }
            
            return sanitized.isEmpty ? nil : sanitized
        }
    }
    
    private func isValidInterfaceName(_ name: String) -> Bool {
        // Validate interface name format (e.g., en0, en1, eth0, etc.)
        let interfacePattern = "^[a-zA-Z]+[0-9]+$"
        let regex = try? NSRegularExpression(pattern: interfacePattern)
        let range = NSRange(location: 0, length: name.count)
        
        // Check against common valid interface prefixes
        let validPrefixes = ["en", "eth", "lo", "utun", "awdl", "llw", "anpi", "ipsec"]
        let hasValidPrefix = validPrefixes.contains { name.hasPrefix($0) }
        
        return hasValidPrefix && 
               name.count <= 10 && // Reasonable length limit
               regex?.firstMatch(in: name, options: [], range: range) != nil
    }
    
    private func createSecureNetworkEnvironment() -> [String: String] {
        // Create minimal, secure environment for network commands
        var secureEnv: [String: String] = [:]
        
        // Only include essential environment variables
        let allowedKeys = ["PATH", "HOME", "USER"]
        
        for key in allowedKeys {
            if let value = ProcessInfo.processInfo.environment[key] {
                // Sanitize environment values
                let sanitizedValue = value.replacingOccurrences(of: ";", with: "")
                                         .replacingOccurrences(of: "|", with: "")
                                         .replacingOccurrences(of: "&", with: "")
                                         .replacingOccurrences(of: "$", with: "")
                                         .replacingOccurrences(of: "`", with: "")
                
                secureEnv[key] = sanitizedValue
            }
        }
        
        // Override PATH to only include system directories
        secureEnv["PATH"] = "/bin:/usr/bin:/sbin:/usr/sbin"
        
        return secureEnv
    }
    
    private func waitForNetworkProcessWithTimeout(task: Process, pipe: Pipe, timeout: TimeInterval) async throws -> (success: Bool, data: Data) {
        return try await withCheckedThrowingContinuation { continuation in
            let semaphore = DispatchSemaphore(value: 0)
            var processData = Data()
            var processCompleted = false
            var hasResumed = false
            
            // Read data asynchronously
            DispatchQueue.global().async {
                processData = pipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()
                processCompleted = true
                semaphore.signal()
            }
            
            // Set up timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                semaphore.signal()
            }
            
            // Wait for completion or timeout
            DispatchQueue.global().async {
                semaphore.wait()
                
                if !hasResumed {
                    hasResumed = true
                    if processCompleted {
                        continuation.resume(returning: (success: true, data: processData))
                    } else {
                        // Timeout occurred
                        if task.isRunning {
                            task.terminate()
                            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                                if task.isRunning {
                                    task.interrupt()
                                }
                            }
                        }
                        continuation.resume(returning: (success: false, data: Data()))
                    }
                }
            }
        }
    }
}

// MARK: - Network Process Errors

enum NetworkProcessError: Error, LocalizedError {
    case processTimeout
    case invalidOutput
    case invalidInterface
    
    var errorDescription: String? {
        switch self {
        case .processTimeout:
            return "Network process timed out"
        case .invalidOutput:
            return "Invalid network process output"
        case .invalidInterface:
            return "Invalid network interface name"
        }
    }
}