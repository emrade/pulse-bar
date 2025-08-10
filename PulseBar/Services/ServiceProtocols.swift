//
//  ServiceProtocols.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

// MARK: - Service Protocols

protocol CPUServiceProtocol {
    var metricsPublisher: AnyPublisher<CPUMetrics, Never> { get }
    func updateMetrics() async
}

protocol MemoryServiceProtocol {
    var metricsPublisher: AnyPublisher<MemoryMetrics, Never> { get }
    var processService: ProcessServiceProtocol { get }
    func updateMetrics() async
}

protocol DiskServiceProtocol {
    var metricsPublisher: AnyPublisher<DiskMetrics, Never> { get }
    func updateMetrics() async
}

protocol BatteryServiceProtocol {
    var metricsPublisher: AnyPublisher<BatteryMetrics?, Never> { get }
    func updateMetrics() async
}

protocol WiFiServiceProtocol {
    var metricsPublisher: AnyPublisher<WiFiMetrics, Never> { get }
    func updateMetrics() async
}

protocol DeviceServiceProtocol {
    var metricsPublisher: AnyPublisher<DeviceMetrics, Never> { get }
    func updateMetrics() async
}

protocol NetworkServiceProtocol {
    var speedTestPublisher: AnyPublisher<NetworkSpeedTest, Never> { get }
    func runSpeedTest() async
    func cancelSpeedTest() async
}