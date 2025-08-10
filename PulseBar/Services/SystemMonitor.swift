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
    private let memoryService: MemoryServiceProtocol
    private let diskService: DiskServiceProtocol
    private let batteryService: BatteryServiceProtocol
    private let wifiService: WiFiServiceProtocol
    private let deviceService: DeviceServiceProtocol
    private let networkService: NetworkServiceProtocol
    private let networkUsageService: NetworkUsageServiceProtocol
    
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
        networkUsageService: NetworkUsageServiceProtocol = NetworkUsageService()
    ) {
        self.cpuService = cpuService
        self.memoryService = memoryService
        self.diskService = diskService
        self.batteryService = batteryService
        self.wifiService = wifiService
        self.deviceService = deviceService
        self.networkService = networkService
        self.networkUsageService = networkUsageService
        
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
    var activeConnectionType: NetworkConnectionType {
        // Check if WiFi is connected and active
        if snapshot.wifi.isConnected {
            return .wifi
        }
        // Check for active ethernet connection (simplified)
        // In a real implementation, we'd check ethernet interfaces for active connections
        return .ethernet
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
    
    func stop() {
        stopPolling()
    }
}