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
        
        // Use system fonts for Basic theme
        if themeManager.currentTheme.id == "basic" {
            return systemFont(for: size, style: style)
        }
        
        let fontConfig: FontStyleConfiguration
        switch style {
        case .primary:
            fontConfig = themeManager.fonts.primary
        case .accent:
            fontConfig = themeManager.fonts.accent ?? themeManager.fonts.primary
        case .monospace:
            fontConfig = themeManager.fonts.monospace ?? themeManager.fonts.primary
        }
        
        let fontSize = fontConfig.size.value(for: size)
        let weight = fontConfig.swiftUIWeight
        
        // Use FontLoader to ensure bundled fonts are available
        let actualFamily = FontLoader.shared.getFontFamilyName(for: fontConfig.family)
        return .custom(actualFamily, size: fontSize).weight(weight)
    }
    
    @MainActor
    private static func systemFont(for size: ThemedFontSize, style: ThemedFontStyle) -> Font {
        switch size {
        case .extraSmall:
            if style == .monospace { return Font.system(size: 10, design: .monospaced) }
            if style == .accent { return .caption.weight(.semibold) }
            return .caption
        case .small:
            if style == .monospace { return Font.system(size: 11, design: .monospaced) }
            if style == .accent { return .caption2.weight(.semibold) }
            return .caption2
        case .regular:
            if style == .monospace { return Font.system(size: 13, design: .monospaced) }
            if style == .accent { return .subheadline.weight(.semibold) }
            return .subheadline
        case .large:
            if style == .monospace { return Font.system(size: 16, design: .monospaced) }
            if style == .accent { return .headline.weight(.bold) }
            return .headline
        case .title:
            if style == .monospace { return Font.system(size: 18, design: .monospaced) }
            if style == .accent { return .title.weight(.bold) }
            return .title
        }
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
    static var themedExtraSmall: Font {
        Font.themed(.primary, size: .extraSmall)
    }
    
    @MainActor
    static var themedMonoRegular: Font {
        Font.themed(.monospace, size: .regular)
    }
    
    @MainActor
    static var themedMonoSmall: Font {
        Font.themed(.monospace, size: .small)
    }
    
    @MainActor
    static var themedAccentTitle: Font {
        Font.themed(.accent, size: .title)
    }
    
    @MainActor
    static var themedAccentLarge: Font {
        Font.themed(.accent, size: .large)
    }
    
    @MainActor
    static var themedAccentRegular: Font {
        Font.themed(.accent, size: .regular)
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
    func themedExtraSmall() -> Text {
        return self.font(.themedExtraSmall)
    }
    
    @MainActor
    func themedMono(_ size: ThemedFontSize = .regular) -> Text {
        return self.font(.themed(.monospace, size: size))
    }
    
    @MainActor
    func themedAccent(_ size: ThemedFontSize = .regular) -> Text {
        return self.font(.themed(.accent, size: size))
    }
}

// MARK: - Weight Conversion Helpers

