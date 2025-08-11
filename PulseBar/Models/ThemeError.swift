//
//  ThemeError.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import Foundation

enum ThemeError: LocalizedError {
    case invalidJSON(String)
    case missingRequiredFields([String])
    case invalidColorFormat(String)
    case unsupportedVersion(String)
    case fileNotFound(String)
    case invalidThemeStructure(String)
    case customThemeDirectoryCreationFailed
    case themeValidationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON(let details):
            return "Theme file contains invalid JSON: \(details)"
        case .missingRequiredFields(let fields):
            return "Theme is missing required fields: \(fields.joined(separator: ", "))"
        case .invalidColorFormat(let color):
            return "Invalid color format: \(color). Expected hex format like #FFFFFF"
        case .unsupportedVersion(let version):
            return "Theme version \(version) is not supported"
        case .fileNotFound(let filename):
            return "Theme file '\(filename)' could not be found"
        case .invalidThemeStructure(let details):
            return "Theme structure is invalid: \(details)"
        case .customThemeDirectoryCreationFailed:
            return "Could not create custom theme directory"
        case .themeValidationFailed(let reason):
            return "Theme validation failed: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidJSON:
            return "Check the JSON syntax and ensure it's properly formatted."
        case .missingRequiredFields:
            return "Add the missing required fields to the theme file."
        case .invalidColorFormat:
            return "Use hex color format (e.g., #FFFFFF for white, #000000 for black)."
        case .unsupportedVersion:
            return "Update the theme to a supported version or use a different theme."
        case .fileNotFound:
            return "Ensure the theme file exists in the correct location."
        case .invalidThemeStructure:
            return "Review the theme structure and ensure it matches the expected format."
        case .customThemeDirectoryCreationFailed:
            return "Check file system permissions for the Application Support directory."
        case .themeValidationFailed:
            return "Review the theme file for any invalid values or missing properties."
        }
    }
}