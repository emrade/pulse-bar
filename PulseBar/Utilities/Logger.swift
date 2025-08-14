//
//  Logger.swift
//  PulseBar
//
//  Created by Claude on 14/08/2025.
//

import Foundation
import os

/// Centralized logging system for PulseBar using os.log
final class PulseBarLogger {
    
    // MARK: - Static Properties
    
    static let shared = PulseBarLogger()
    
    // MARK: - Log Categories
    
    private let networkLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pulseBar", category: "Network")
    private let themeLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pulseBar", category: "Theme")
    private let securityLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pulseBar", category: "Security")
    private let systemLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pulseBar", category: "System")
    private let uiLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pulseBar", category: "UI")
    
    // MARK: - Private Init
    
    private init() {}
    
    // MARK: - Network Logging
    
    func logNetworkInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        networkLogger.info("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logNetworkWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        networkLogger.warning("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logNetworkError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorDescription = error?.localizedDescription ?? "No error details"
        networkLogger.error("\(self.extractFileName(from: file)):\(line) \(function) - \(message). Error: \(errorDescription)")
    }
    
    // MARK: - Theme Logging
    
    func logThemeInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        themeLogger.info("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logThemeWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        themeLogger.warning("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logThemeError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorDescription = error?.localizedDescription ?? "No error details"
        themeLogger.error("\(self.extractFileName(from: file)):\(line) \(function) - \(message). Error: \(errorDescription)")
    }
    
    // MARK: - Security Logging
    
    func logSecurityInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        securityLogger.info("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logSecurityWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        securityLogger.warning("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logSecurityError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorDescription = error?.localizedDescription ?? "No error details"
        securityLogger.error("\(self.extractFileName(from: file)):\(line) \(function) - \(message). Error: \(errorDescription)")
    }
    
    // MARK: - System Logging
    
    func logSystemInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        systemLogger.info("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logSystemWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        systemLogger.warning("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logSystemError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorDescription = error?.localizedDescription ?? "No error details"
        systemLogger.error("\(self.extractFileName(from: file)):\(line) \(function) - \(message). Error: \(errorDescription)")
    }
    
    // MARK: - UI Logging
    
    func logUIInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        uiLogger.info("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logUIWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        uiLogger.warning("\(self.extractFileName(from: file)):\(line) \(function) - \(message)")
    }
    
    func logUIError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorDescription = error?.localizedDescription ?? "No error details"
        uiLogger.error("\(self.extractFileName(from: file)):\(line) \(function) - \(message). Error: \(errorDescription)")
    }
    
    // MARK: - Security Event Logging
    
    /// Log security-related events with structured data
    func logSecurityEvent(_ event: SecurityEvent, details: [String: Any] = [:]) {
        let eventData = details.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let message = "Security Event: \(event.rawValue). Details: \(eventData)"
        
        switch event.severity {
        case .info:
            logSecurityInfo(message)
        case .warning:
            logSecurityWarning(message)
        case .error:
            logSecurityError(message)
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractFileName(from filePath: String) -> String {
        return (filePath as NSString).lastPathComponent
    }
}

// MARK: - Security Event Model

enum SecurityEvent: String, CaseIterable {
    case fileAccessAttempt = "FILE_ACCESS_ATTEMPT"
    case invalidFileSize = "INVALID_FILE_SIZE"
    case invalidFileFormat = "INVALID_FILE_FORMAT"
    case networkInterfaceEnumeration = "NETWORK_INTERFACE_ENUMERATION"
    case networkInterfaceAccessFailure = "NETWORK_INTERFACE_ACCESS_FAILURE"
    case themeImportAttempt = "THEME_IMPORT_ATTEMPT"
    case themeValidationFailure = "THEME_VALIDATION_FAILURE"
    case unauthorizedDataAccess = "UNAUTHORIZED_DATA_ACCESS"
    case inputValidationFailure = "INPUT_VALIDATION_FAILURE"
    
    var severity: SecurityEventSeverity {
        switch self {
        case .fileAccessAttempt, .themeImportAttempt, .networkInterfaceEnumeration:
            return .info
        case .invalidFileSize, .invalidFileFormat, .inputValidationFailure:
            return .warning
        case .networkInterfaceAccessFailure, .themeValidationFailure, .unauthorizedDataAccess:
            return .error
        }
    }
}

enum SecurityEventSeverity {
    case info
    case warning
    case error
}

// MARK: - Convenience Extensions

extension PulseBarLogger {
    
    /// Log network interface access with bounds checking validation
    func logNetworkInterfaceAccess(interfaceName: String?, success: Bool, bytesIn: UInt64?, bytesOut: UInt64?) {
        let details: [String: Any] = [
            "interface": interfaceName ?? "unknown",
            "success": success,
            "bytesIn": bytesIn ?? 0,
            "bytesOut": bytesOut ?? 0
        ]
        
        if success {
            logSecurityEvent(.networkInterfaceEnumeration, details: details)
        } else {
            logSecurityEvent(.networkInterfaceAccessFailure, details: details)
        }
    }
    
    /// Log theme file operations with size and validation checks
    func logThemeFileOperation(operation: String, fileName: String, fileSize: Int64?, success: Bool, validationErrors: [String] = []) {
        let details: [String: Any] = [
            "operation": operation,
            "fileName": fileName,
            "fileSize": fileSize ?? 0,
            "success": success,
            "validationErrors": validationErrors.joined(separator: ", ")
        ]
        
        if !success && !validationErrors.isEmpty {
            logSecurityEvent(.themeValidationFailure, details: details)
        } else if let size = fileSize, size > 1_048_576 { // 1MB limit
            logSecurityEvent(.invalidFileSize, details: details)
        } else {
            logSecurityEvent(.themeImportAttempt, details: details)
        }
    }
}