//
//  WiFiService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

final class WiFiService: WiFiServiceProtocol, @unchecked Sendable {
    private let metricsSubject = CurrentValueSubject<WiFiMetrics, Never>(WiFiMetrics())
    
    var metricsPublisher: AnyPublisher<WiFiMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    func updateMetrics() async {
        // TODO: Implement real WiFi monitoring using CoreWLAN
        // Placeholder implementation
        let mockMetrics = WiFiMetrics(
            ssid: "MyWiFiNetwork",
            bssid: "aa:bb:cc:dd:ee:ff",
            rssi: -45,
            linkSpeed: 144.0,
            isConnected: true,
            isLoading: false,
            error: nil
        )
        
        await MainActor.run {
            metricsSubject.send(mockMetrics)
        }
    }
}