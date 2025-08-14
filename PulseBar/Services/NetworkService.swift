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
        
        do {
            // Perform real speed test
            let (downloadSpeed, uploadSpeed, latency) = try await performRealSpeedTest()
            
            let finalResult = NetworkSpeedTest(
                downloadSpeed: downloadSpeed,
                uploadSpeed: uploadSpeed,
                latency: latency,
                isRunning: false,
                progress: 1.0,
                error: nil
            )
            
            await MainActor.run {
                speedTestSubject.send(finalResult)
            }
            
            // Reset after 10 seconds
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            await MainActor.run {
                speedTestSubject.send(NetworkSpeedTest())
            }
            
        } catch {
            let errorResult = NetworkSpeedTest(
                downloadSpeed: nil,
                uploadSpeed: nil,
                latency: nil,
                isRunning: false,
                progress: 0.0,
                error: error.localizedDescription
            )
            
            await MainActor.run {
                speedTestSubject.send(errorResult)
            }
            
            // Reset after 5 seconds on error
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                speedTestSubject.send(NetworkSpeedTest())
            }
        }
    }
    
    private func performRealSpeedTest() async throws -> (downloadSpeed: Double, uploadSpeed: Double, latency: Double) {
        // First, test latency
        let latency = try await measureLatency()
        
        // Update progress
        await MainActor.run {
            speedTestSubject.send(NetworkSpeedTest(isRunning: true, progress: 0.1))
        }
        
        guard !Task.isCancelled else { throw CancellationError() }
        
        // Test download speed with multiple endpoints and larger files
        let downloadSpeed = try await measureDownloadSpeed()
        
        // Update progress
        await MainActor.run {
            speedTestSubject.send(NetworkSpeedTest(isRunning: true, progress: 0.7))
        }
        
        guard !Task.isCancelled else { throw CancellationError() }
        
        // Test upload speed
        let uploadSpeed = try await measureUploadSpeed()
        
        await MainActor.run {
            speedTestSubject.send(NetworkSpeedTest(isRunning: true, progress: 1.0))
        }
        
        return (downloadSpeed: downloadSpeed, uploadSpeed: uploadSpeed, latency: latency)
    }
    
    private func measureDownloadSpeed() async throws -> Double {
        // Test endpoints with larger files for more accurate speed measurement
        let testEndpoints = [
            // Use publicly available test files from reliable CDNs
            "https://speed.cloudflare.com/__down?bytes=25000000", // 25MB file
            "https://www.google.com/favicon.ico", // Fallback small file
            "https://httpbin.org/bytes/10000000", // 10MB file
            "https://github.com/favicon.ico" // Another fallback
        ]
        
        // Validate endpoints before use
        let validatedEndpoints = testEndpoints.compactMap { endpoint in
            validateAndSanitizeURL(endpoint)
        }
        
        guard !validatedEndpoints.isEmpty else {
            throw NetworkSpeedTestError.allEndpointsFailed
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // Increased for security
        configuration.timeoutIntervalForResource = 30
        configuration.urlCache = nil // Disable caching for accurate measurement
        
        // Enhanced security settings
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let session = URLSession(configuration: configuration, delegate: SecureURLSessionDelegate(), delegateQueue: nil)
        
        var bestSpeed: Double = 0.0
        var successfulTests = 0
        let maxTestDuration: TimeInterval = 10.0 // Maximum time per test
        
        for (index, endpoint) in validatedEndpoints.enumerated() {
            guard !Task.isCancelled else { throw CancellationError() }
            
            do {
                print("Speed Test Debug: Testing endpoint \(index + 1)/\(validatedEndpoints.count): \(endpoint)")
                
                // Create secure request
                var request = URLRequest(url: endpoint)
                request.timeoutInterval = 30
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                request.setValue("PulseBar/1.0", forHTTPHeaderField: "User-Agent")
                
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Create a task with timeout and size limits
                let downloadTask = Task {
                    return try await performSecureDownload(session: session, request: request, maxSize: 50_000_000) // 50MB limit
                }
                
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: UInt64(maxTestDuration * 1_000_000_000))
                    downloadTask.cancel()
                }
                
                let (data, response) = try await downloadTask.value
                timeoutTask.cancel()
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let duration = endTime - startTime
                
                // Validate response
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      duration > 0.1, // Minimum duration for meaningful measurement
                      data.count > 1000, // Minimum data size
                      data.count <= 50_000_000 else { // Maximum data size
                    print("Speed Test Debug: Endpoint \(endpoint.absoluteString) - Invalid response, too fast, or size violation")
                    continue
                }
                
                // Calculate speed
                let bytesPerSecond = Double(data.count) / duration
                let mbps = (bytesPerSecond * 8) / 1_000_000 // Convert to Mbps
                
                print("Speed Test Debug: Endpoint \(endpoint.absoluteString) - Downloaded \(data.count) bytes in \(duration)s = \(mbps) Mbps")
                
                bestSpeed = max(bestSpeed, mbps)
                successfulTests += 1
                
                // Update progress
                await MainActor.run {
                    let progress = 0.1 + (Double(index + 1) / Double(validatedEndpoints.count)) * 0.5
                    speedTestSubject.send(NetworkSpeedTest(isRunning: true, progress: progress))
                }
                
                // If we get a good speed from Cloudflare, prioritize it
                if endpoint.absoluteString.contains("cloudflare") && mbps > 1.0 {
                    break
                }
                
            } catch {
                print("Speed Test Debug: Endpoint \(endpoint.absoluteString) failed: \(error)")
                continue
            }
        }
        
        guard successfulTests > 0, bestSpeed > 0 else {
            throw NetworkSpeedTestError.allEndpointsFailed
        }
        
        // Apply reasonable bounds
        let finalSpeed = min(max(bestSpeed, 0.1), 2000.0) // Cap between 0.1 and 2000 Mbps
        
        print("Speed Test Debug: Final speed: \(finalSpeed) Mbps (from \(successfulTests) successful tests)")
        
        return finalSpeed
    }
    
    private func measureUploadSpeed() async throws -> Double {
        // Test upload speed using POST requests with data
        let uploadEndpoints = [
            "https://httpbin.org/post", // Reliable HTTP testing service
            "https://postman-echo.com/post", // Alternative testing service
            "https://httpbingo.org/post" // Another testing service
        ]
        
        // Validate endpoints before use
        let validatedEndpoints = uploadEndpoints.compactMap { endpoint in
            validateAndSanitizeURL(endpoint)
        }
        
        guard !validatedEndpoints.isEmpty else {
            throw NetworkSpeedTestError.allEndpointsFailed
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // Increased for security
        configuration.timeoutIntervalForResource = 30
        configuration.urlCache = nil
        
        // Enhanced security settings
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.allowsCellularAccess = true
        configuration.waitsForConnectivity = false
        
        let session = URLSession(configuration: configuration, delegate: SecureURLSessionDelegate(), delegateQueue: nil)
        
        var bestSpeed: Double = 0.0
        var successfulTests = 0
        
        // Start with larger data size for better accuracy
        let testDataSize = 2_000_000 // 2MB test data
        
        // Create test data - use random data to prevent compression
        var testData = Data(count: testDataSize)
        testData.withUnsafeMutableBytes { bytes in
            arc4random_buf(bytes.baseAddress, testDataSize)
        }
        
        for (index, endpoint) in validatedEndpoints.enumerated() {
            guard !Task.isCancelled else { throw CancellationError() }
            
            do {
                print("Speed Test Debug: Testing upload to \(endpoint.absoluteString)")
                
                var request = URLRequest(url: endpoint)
                request.httpMethod = "POST"
                request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
                request.setValue("PulseBar/1.0", forHTTPHeaderField: "User-Agent")
                request.setValue("\(testDataSize)", forHTTPHeaderField: "Content-Length")
                request.httpBody = testData
                request.timeoutInterval = 30
                
                // Measure upload time more precisely - start timing just before upload
                let startTime = CFAbsoluteTimeGetCurrent()
                
                let (responseData, response) = try await session.data(for: request)
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let duration = endTime - startTime
                
                // Validate response
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                      duration > 0.2 else { // Minimum duration for meaningful measurement
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("Speed Test Debug: Upload to \(endpoint) - Invalid response, too fast, or failed (status: \(statusCode))")
                    continue
                }
                
                // Calculate upload speed - account for overhead more carefully
                // Subtract estimated network overhead (headers, TCP handshake, etc.)
                let networkOverheadEstimate = 0.1 // 100ms overhead estimate
                let adjustedDuration = max(duration - networkOverheadEstimate, duration * 0.8) // Use at least 80% of total time
                
                let bytesPerSecond = Double(testDataSize) / adjustedDuration
                let mbps = (bytesPerSecond * 8) / 1_000_000 // Convert to Mbps
                
                print("Speed Test Debug: Upload to \(endpoint.absoluteString) - Uploaded \(testDataSize) bytes in \(duration)s (adjusted: \(adjustedDuration)s) = \(mbps) Mbps, response size: \(responseData.count) bytes")
                
                bestSpeed = max(bestSpeed, mbps)
                successfulTests += 1
                
                // Update progress
                await MainActor.run {
                    let progress = 0.7 + (Double(index + 1) / Double(validatedEndpoints.count)) * 0.3
                    speedTestSubject.send(NetworkSpeedTest(isRunning: true, progress: progress))
                }
                
                // If we get a reasonable upload speed from the first endpoint, use it
                // Don't require high speeds since upload is typically much slower than download
                if mbps > 0.5 && endpoint.absoluteString.contains("httpbin") {
                    break
                }
                
            } catch {
                print("Speed Test Debug: Upload to \(endpoint.absoluteString) failed: \(error)")
                continue
            }
        }
        
        // Use the best upload speed, or 0 if all tests failed
        let finalSpeed = successfulTests > 0 ? bestSpeed : 0.0
        
        // Apply reasonable bounds for upload (typically much lower than download)
        // Most residential connections have upload speeds between 1-100 Mbps
        let boundedSpeed = min(max(finalSpeed, 0.0), 500.0) // Cap at 500 Mbps for upload
        
        print("Speed Test Debug: Final upload speed: \(boundedSpeed) Mbps (from \(successfulTests) successful tests)")
        
        return boundedSpeed
    }
    
    private func measureLatency() async throws -> Double {
        // Test latency with multiple endpoints and take the best result
        let latencyEndpoints = [
            "https://www.cloudflare.com",
            "https://www.google.com",
            "https://www.apple.com"
        ]
        
        // Validate endpoints before use
        let validatedEndpoints = latencyEndpoints.compactMap { endpoint in
            validateAndSanitizeURL(endpoint)
        }
        
        guard !validatedEndpoints.isEmpty else {
            throw NetworkSpeedTestError.allEndpointsFailed
        }
        
        // Create secure session configuration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        
        let session = URLSession(configuration: configuration, delegate: SecureURLSessionDelegate(), delegateQueue: nil)
        
        var bestLatency: Double = Double.infinity
        var successfulTests = 0
        
        for endpoint in validatedEndpoints {
            do {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Create a simple HEAD request to minimize data transfer
                var request = URLRequest(url: endpoint)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 10
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                request.setValue("PulseBar/1.0", forHTTPHeaderField: "User-Agent")
                
                let (_, response) = try await session.data(for: request)
                let endTime = CFAbsoluteTimeGetCurrent()
                
                if let httpResponse = response as? HTTPURLResponse, 
                   httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    let latency = (endTime - startTime) * 1000 // Convert to ms
                    print("Speed Test Debug: Latency to \(endpoint.absoluteString): \(latency) ms")
                    
                    bestLatency = min(bestLatency, latency)
                    successfulTests += 1
                    
                    // If we get a very good latency, we can stop early
                    if latency < 20.0 {
                        break
                    }
                }
            } catch {
                print("Speed Test Debug: Latency test to \(endpoint.absoluteString) failed: \(error)")
                continue
            }
        }
        
        // Use the best latency, or a reasonable default if all tests failed
        let finalLatency = successfulTests > 0 ? bestLatency : 50.0
        
        // Apply reasonable bounds (1ms to 2000ms)
        let boundedLatency = min(max(finalLatency, 1.0), 2000.0)
        
        print("Speed Test Debug: Final latency: \(boundedLatency) ms (from \(successfulTests) successful tests)")
        
        return boundedLatency
    }
    
    // MARK: - Security Helper Methods
    
    private func validateAndSanitizeURL(_ urlString: String) -> URL? {
        // Remove any dangerous characters
        let sanitized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
        
        // Validate URL format
        guard let url = URL(string: sanitized),
              let scheme = url.scheme?.lowercased(),
              scheme == "https", // Only allow HTTPS
              let host = url.host else {
            print("NetworkService: Invalid or insecure URL: \(urlString)")
            return nil
        }
        
        // Whitelist allowed domains
        let allowedDomains = [
            "speed.cloudflare.com",
            "www.google.com",
            "httpbin.org",
            "github.com",
            "postman-echo.com",
            "httpbingo.org",
            "www.cloudflare.com",
            "www.apple.com"
        ]
        
        guard allowedDomains.contains(host) else {
            print("NetworkService: Domain not in whitelist: \(host)")
            return nil
        }
        
        return url
    }
    
    private func performSecureDownload(session: URLSession, request: URLRequest, maxSize: Int) async throws -> (Data, URLResponse) {
        var downloadedData = Data()
        
        return try await withCheckedThrowingContinuation { continuation in
            var dataTask: URLSessionDataTask?
            
            dataTask = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let response = response else {
                    continuation.resume(throwing: NetworkSpeedTestError.allEndpointsFailed)
                    return
                }
                
                if let data = data {
                    downloadedData.append(data)
                    
                    // Check size limit
                    if downloadedData.count > maxSize {
                        dataTask?.cancel()
                        continuation.resume(throwing: NetworkSecurityError.responseSizeExceeded)
                        return
                    }
                }
                
                continuation.resume(returning: (downloadedData, response))
            }
            
            dataTask?.resume()
        }
    }
}

// MARK: - Security Classes and Extensions

class SecureURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Only allow server trust authentication
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Get server trust
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validate the certificate chain
        let policy = SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)
        SecTrustSetPolicies(serverTrust, policy)
        
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        
        // Check if the certificate is valid
        if isValid && error == nil {
            // Additional check for known good certificates
            if isKnownGoodCertificate(serverTrust: serverTrust, host: challenge.protectionSpace.host) {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            print("NetworkService: SSL certificate validation failed for host: \(challenge.protectionSpace.host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    private func isKnownGoodCertificate(serverTrust: SecTrust, host: String) -> Bool {
        // For production, you might want to implement certificate pinning here
        // For now, we rely on the system's certificate validation
        
        // Additional check: ensure the host matches what we expect
        let trustedHosts = [
            "speed.cloudflare.com",
            "www.google.com",
            "httpbin.org",
            "github.com",
            "postman-echo.com",
            "httpbingo.org",
            "www.cloudflare.com",
            "www.apple.com"
        ]
        
        return trustedHosts.contains(host)
    }
}

enum NetworkSpeedTestError: Error, LocalizedError {
    case allEndpointsFailed
    
    var errorDescription: String? {
        switch self {
        case .allEndpointsFailed:
            return "Unable to connect to speed test servers"
        }
    }
}

enum NetworkSecurityError: Error, LocalizedError {
    case responseSizeExceeded
    case untrustedDomain
    case insecureConnection
    
    var errorDescription: String? {
        switch self {
        case .responseSizeExceeded:
            return "Response size exceeded security limit"
        case .untrustedDomain:
            return "Domain not in trusted whitelist"
        case .insecureConnection:
            return "Insecure connection attempted"
        }
    }
}