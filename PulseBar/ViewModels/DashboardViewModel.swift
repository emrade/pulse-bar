//
//  DashboardViewModel.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 10/08/2025.
//

import Foundation
import Combine
import SwiftUI

// MARK: - View States
enum DashboardViewState {
    case basic
    case advancedStorage
    case advancedMemory  
    case advancedBattery
    case advancedCPU
    case advancedNetwork
    case advancedDevices
    case advancedNetworkUsage
    case settings
    case about
}

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showingResetConfirmation = false
    @Published var snapshot = MetricsSnapshot()
    @Published var networkSpeedTest = NetworkSpeedTest()
    @Published var currentViewState: DashboardViewState = .basic
    
    // MARK: - Private Properties
    private let systemMonitor = SystemMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var activeConnectionType: NetworkConnectionType {
        systemMonitor.activeConnectionType
    }
    
    var networkDisplayInfo: (icon: String, title: String, connectionDetail: String?) {
        systemMonitor.networkDisplayInfo
    }
    
    // MARK: - Formatted Network Detail
    var networkDetailText: String? {
        switch activeConnectionType {
        case .wifi:
            if snapshot.wifi.isConnected {
                let speedTestResult = networkSpeedTest.formattedResult != "Test Speed" && !networkSpeedTest.isRunning ? 
                    " • \(networkSpeedTest.formattedResult)" : ""
                return "\(snapshot.wifi.signalQuality)\(speedTestResult)"
            }
            return nil
        case .ethernet, .other:
            return networkSpeedTest.formattedResult != "Test Speed" && !networkSpeedTest.isRunning ? 
                networkSpeedTest.formattedResult : nil
        }
    }
    
    var networkValueText: String {
        activeConnectionType == .wifi ? 
            snapshot.wifi.formattedStatus :
            "Connected via \(networkDisplayInfo.connectionDetail ?? "Network")"
    }
    
    var shouldShowNetworkInfoButton: Bool {
        activeConnectionType == .wifi
    }
    
    var networkInfoContent: String? {
        guard activeConnectionType == .wifi else { return nil }
        return """
WiFi Signal Strength (dBm):

dBm measures radio signal power. Higher numbers = weaker signal.

Signal Quality Guide:
• -30 to -50 dBm: Excellent (very close to router)
• -50 to -60 dBm: Good (same room as router) 
• -60 to -70 dBm: Fair (different room, some walls)
• -70 to -80 dBm: Weak (far from router, obstacles)
• -80 to -90 dBm: Very weak (barely usable)

Better signal = faster speeds and more reliable connection.
"""
    }
    
    var speedTestButtonText: String {
        networkSpeedTest.isRunning ? 
            "Testing... \(Int(networkSpeedTest.progress * 100))%" : "Test Speed"
    }
    
    // MARK: - Initialization
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to SystemMonitor updates
        systemMonitor.$snapshot
            .receive(on: DispatchQueue.main)
            .assign(to: \.snapshot, on: self)
            .store(in: &cancellables)
        
        systemMonitor.$networkSpeedTest
            .receive(on: DispatchQueue.main)
            .assign(to: \.networkSpeedTest, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    func handleSpeedTestAction() {
        if networkSpeedTest.isRunning {
            systemMonitor.cancelSpeedTest()
        } else {
            systemMonitor.runSpeedTest()
        }
    }
    
    func showResetConfirmation() {
        showingResetConfirmation = true
    }
    
    func resetDailyDataUsage() {
        systemMonitor.resetDailyDataUsage()
        showingResetConfirmation = false
    }
    
    func cancelReset() {
        showingResetConfirmation = false
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func refreshAllMetrics() {
        systemMonitor.refreshAllMetrics()
    }
    
    // MARK: - Advanced View Navigation
    func showAdvancedView(for metric: DashboardViewState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentViewState = metric
        }
    }
    
    func showBasicView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentViewState = .basic
        }
    }
    
    // MARK: - Metric Tile Actions
    func handleStorageTileTap() {
        showAdvancedView(for: .advancedStorage)
    }
    
    func handleMemoryTileTap() {
        showAdvancedView(for: .advancedMemory)
    }
    
    func handleBatteryTileTap() {
        showAdvancedView(for: .advancedBattery)
    }
    
    func handleCPUTileTap() {
        showAdvancedView(for: .advancedCPU)
    }
    
    func handleNetworkTileTap() {
        showAdvancedView(for: .advancedNetwork)
    }
    
    func handleDevicesTileTap() {
        showAdvancedView(for: .advancedDevices)
    }
    
    func handleNetworkUsageTileTap() {
        showAdvancedView(for: .advancedNetworkUsage)
    }
    
    func showSettings() {
        showAdvancedView(for: .settings)
    }
    
    func showAbout() {
        showAdvancedView(for: .about)
    }
}