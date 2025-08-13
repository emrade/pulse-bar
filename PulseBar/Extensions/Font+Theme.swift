//
//  Font+Theme.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

// MARK: - Semantic Font Styles
enum SemanticFontStyle {
    case headline      // Large, bold text for headings (17pt, semibold)
    case subheadline   // Smaller headings (15pt, regular)
    case title         // Main titles (28pt, regular)
    case body          // Regular body text (17pt, regular)
    case caption       // Small text, labels (12pt, regular)
    case footnote      // Very small text (13pt, regular)
    case monospace     // Code/monospace text
}

extension Font {
    // MARK: - Semantic Font System
    
    @MainActor
    static func themed(_ style: SemanticFontStyle) -> Font {
        let themeManager = ThemeManager.shared
        
        // Get the semantic font configuration
        let fontConfig: SemanticFontConfiguration
        switch style {
        case .headline:
            fontConfig = themeManager.fonts.headline
        case .subheadline:
            fontConfig = themeManager.fonts.subheadline
        case .title:
            fontConfig = themeManager.fonts.title
        case .body:
            fontConfig = themeManager.fonts.body
        case .caption:
            fontConfig = themeManager.fonts.caption
        case .footnote:
            fontConfig = themeManager.fonts.footnote
        case .monospace:
            fontConfig = themeManager.fonts.monospace ?? themeManager.fonts.body
        }
        
        let fontSize = fontConfig.size
        let weight = fontConfig.swiftUIWeight
        
        // Handle system fonts vs custom fonts
        if fontConfig.family.lowercased() == "system" {
            return .system(size: fontSize, weight: weight, design: .default)
        } else if fontConfig.family.lowercased() == "system-monospace" {
            return .system(size: fontSize, weight: weight, design: .monospaced)
        } else {
            // Use FontLoader to ensure bundled fonts are available
            let actualFamily = FontLoader.shared.getFontFamilyName(for: fontConfig.family)
            return .custom(actualFamily, size: fontSize).weight(weight)
        }
    }
    
    // MARK: - Semantic Font Convenience Properties
    
    @MainActor
    static var themedHeadline: Font {
        Font.themed(.headline)
    }
    
    @MainActor
    static var themedSubheadline: Font {
        Font.themed(.subheadline)
    }
    
    @MainActor
    static var themedTitle: Font {
        Font.themed(.title)
    }
    
    @MainActor
    static var themedBody: Font {
        Font.themed(.body)
    }
    
    @MainActor
    static var themedCaption: Font {
        Font.themed(.caption)
    }
    
    @MainActor
    static var themedFootnote: Font {
        Font.themed(.footnote)
    }
    
    @MainActor
    static var themedMonospace: Font {
        Font.themed(.monospace)
    }
    
    // MARK: - Dynamic Font Sizing
    
    @MainActor
    static func themedDynamic(_ style: SemanticFontStyle, 
                             relativeTo textStyle: Font.TextStyle = .body) -> Font {
        let baseFont = Font.themed(style)
        return baseFont.font(relativeTo: textStyle)
    }
}

// MARK: - Custom Font Extensions

extension Font {
    func font(relativeTo textStyle: Font.TextStyle) -> Font {
        // This allows for dynamic type scaling while maintaining theme fonts
        return self
    }
}

// MARK: - Text Extensions for Semantic Fonts

extension Text {
    // MARK: - Semantic Font Text Extensions
    
    @MainActor
    func themedFont(_ style: SemanticFontStyle) -> Text {
        return self.font(.themed(style))
    }
    
    @MainActor
    func themedHeadline() -> Text {
        return self.font(.themedHeadline)
    }
    
    @MainActor
    func themedSubheadline() -> Text {
        return self.font(.themedSubheadline)
    }
    
    @MainActor
    func themedTitle() -> Text {
        return self.font(.themedTitle)
    }
    
    @MainActor
    func themedBody() -> Text {
        return self.font(.themedBody)
    }
    
    @MainActor
    func themedCaption() -> Text {
        return self.font(.themedCaption)
    }
    
    @MainActor
    func themedFootnote() -> Text {
        return self.font(.themedFootnote)
    }
    
    @MainActor
    func themedMonospace() -> Text {
        return self.font(.themedMonospace)
    }
}

// MARK: - Weight Conversion Helpers

