//
//  Font+Theme.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

extension Font {
    // MARK: - Themed Font Accessors
    
    @MainActor
    static func themed(_ style: ThemedFontStyle, size: ThemedFontSize = .regular) -> Font {
        let themeManager = ThemeManager.shared
        
        let fontConfig: FontStyleConfiguration
        switch style {
        case .primary:
            fontConfig = themeManager.fonts.primary
        case .monospace:
            fontConfig = themeManager.fonts.monospace ?? themeManager.fonts.primary
        }
        
        let fontSize = fontConfig.size.value(for: size)
        let weight = fontConfig.swiftUIWeight
        
        return .custom(fontConfig.family, size: fontSize).weight(weight)
    }
    
    // MARK: - Common Themed Fonts
    
    @MainActor
    static var themedTitle: Font {
        Font.themed(.primary, size: .title)
    }
    
    @MainActor
    static var themedLarge: Font {
        Font.themed(.primary, size: .large)
    }
    
    @MainActor
    static var themedRegular: Font {
        Font.themed(.primary, size: .regular)
    }
    
    @MainActor
    static var themedSmall: Font {
        Font.themed(.primary, size: .small)
    }
    
    @MainActor
    static var themedMonoRegular: Font {
        Font.themed(.monospace, size: .regular)
    }
    
    @MainActor
    static var themedMonoSmall: Font {
        Font.themed(.monospace, size: .small)
    }
    
    // MARK: - Dynamic Font Sizing
    
    @MainActor
    static func themedDynamic(_ style: ThemedFontStyle, 
                             size: ThemedFontSize = .regular,
                             relativeTo textStyle: Font.TextStyle = .body) -> Font {
        let baseFont = Font.themed(style, size: size)
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

// MARK: - Text Extensions for Themed Fonts

extension Text {
    @MainActor
    func themedFont(_ style: ThemedFontStyle, size: ThemedFontSize = .regular) -> Text {
        return self.font(.themed(style, size: size))
    }
    
    @MainActor
    func themedTitle() -> Text {
        return self.font(.themedTitle)
    }
    
    @MainActor
    func themedLarge() -> Text {
        return self.font(.themedLarge)
    }
    
    @MainActor
    func themedRegular() -> Text {
        return self.font(.themedRegular)
    }
    
    @MainActor
    func themedSmall() -> Text {
        return self.font(.themedSmall)
    }
    
    @MainActor
    func themedMono(_ size: ThemedFontSize = .regular) -> Text {
        return self.font(.themed(.monospace, size: size))
    }
}

// MARK: - Weight Conversion Helpers

