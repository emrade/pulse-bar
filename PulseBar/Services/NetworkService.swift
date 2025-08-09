//
//  NetworkService.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import Foundation
import Combine

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    private let speedTestSubject = CurrentValueSubject<NetworkSpeedTest, Never>(NetworkSpeedTest())
    
    var speedTestPublisher: AnyPublisher<NetworkSpeedTest, Never> {
        speedTestSubject.eraseToAnyPublisher()
    }
    
    private var currentTask: Task<Void, Never>?
    
    func runSpeedTest() async {
        // Cancel any existing test
        await cancelSpeedTest()
        
        currentTask = Task {
            await performSpeedTest()
        }
        
        await currentTask?.value
    }
    
    func cancelSpeedTest() async {
        currentTask?.cancel()
        currentTask = nil
        
        await MainActor.run {
            speedTestSubject.send(NetworkSpeedTest(isRunning: false, progress: 0.0))
        }
    }
    
    private func performSpeedTest() async {
        await MainActor.run {
            speedTestSubject.send(NetworkSpeedTest(isRunning: true, progress: 0.0))
        }
        
        // TODO: Implement real speed test
        // For now, simulate a speed test
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            guard !Task.isCancelled else {
                await MainActor.run {
                    speedTestSubject.send(NetworkSpeedTest(isRunning: false, progress: 0.0))
                }
                return
            }
            
            await MainActor.run {
                speedTestSubject.send(NetworkSpeedTest(isRunning: true, progress: progress))
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        // Simulate final results
        let finalResult = NetworkSpeedTest(
            downloadSpeed: 120.5,
            uploadSpeed: 45.2,
            latency: 15.0,
            isRunning: false,
            progress: 1.0,
            error: nil
        )
        
        await MainActor.run {
            speedTestSubject.send(finalResult)
        }
        
        // Reset after 5 seconds
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        await MainActor.run {
            speedTestSubject.send(NetworkSpeedTest())
        }
    }
}