# PulseBar Theming System

## Overview

PulseBar's theming system provides a comprehensive, modular approach to customizing the application's appearance. The system supports 4 built-in themes and allows users to create and import custom themes. Themes can modify colors, fonts, icons, visual effects, and even popover dimensions.

## Architecture

### Core Components

```
PulseBar/
├── Models/
│   ├── Theme.swift                    # Theme data models
│   └── ThemeConfiguration.swift       # Theme configuration helpers
├── Services/
│   └── ThemeManager.swift            # Theme management singleton
├── Resources/
│   └── Themes/                       # Built-in theme JSON files
│       ├── basic.json
│       ├── futuristic.json
│       ├── colorful.json
│       └── nature-glow.json
├── Views/
│   ├── Theming/
│   │   ├── ThemedView.swift          # Base themed view protocol
│   │   ├── ThemePreview.swift        # Theme preview component
│   │   └── ThemePicker.swift         # Theme selection UI
│   └── Components/
│       ├── ThemedCard.swift          # Themeable card component
│       ├── ThemedButton.swift        # Themeable button component
│       └── ThemedText.swift          # Themeable text component
└── Extensions/
    ├── Color+Theme.swift             # Theme color extensions
    ├── Font+Theme.swift              # Theme font extensions
    └── View+Theme.swift              # Theme view modifiers
```

### External Locations

```
~/Library/Application Support/PulseBar/
└── Themes/                           # User custom themes
    ├── my-custom-theme.json
    └── imported-theme.json
```

## Theme Data Structure

### Complete JSON Schema

```json
{
  "id": "futuristic",
  "name": "Futuristic",
  "description": "Dark theme with neon accents and blurred backgrounds",
  "version": "1.0.0",
  "author": "PulseBar Team",
  
  "popover": {
    "width": 380,
    "height": 620,
    "cornerRadius": 14,
    "shadow": {
      "enabled": true,
      "color": "#000000",
      "opacity": 0.3,
      "radius": 20,
      "offset": { "x": 0, "y": 10 }
    }
  },
  
  "layout": {
    "gridColumns": 2,
    "cardSpacing": 12,
    "sectionSpacing": 16,
    "padding": {
      "horizontal": 16,
      "vertical": 16
    }
  },
  
  "colors": {
    "background": "#0A0F1C",
    "secondaryBackground": "#1A1F2C",
    "cardBackground": "#252B3A",
    "primaryText": "#FFFFFF",
    "secondaryText": "#8A9BA8",
    "accent": "#00FFF5",
    "accentSecondary": "#FF6B9D",
    "success": "#00FF88",
    "warning": "#FFB800",
    "error": "#FF5555",
    "divider": "#3A4553",
    "gradient": {
      "primary": ["#00FFF5", "#FF6B9D"],
      "secondary": ["#1A1F2C", "#252B3A"],
      "accent": ["#00FFF5", "#0080FF"]
    }
  },
  
  "fonts": {
    "primary": {
      "family": "SF Pro Display",
      "weight": "medium",
      "size": {
        "small": 11,
        "regular": 13,
        "large": 16,
        "title": 18
      }
    },
    "monospace": {
      "family": "SF Mono",
      "weight": "regular",
      "size": {
        "small": 10,
        "regular": 12
      }
    }
  },
  
  "icons": {
    "style": "outline",
    "weight": "medium",
    "accentColor": "#00FFF5",
    "size": {
      "small": 14,
      "regular": 16,
      "large": 20
    },
    "customMappings": {
      "cpu": "cpu.fill",
      "memory": "memorychip.fill"
    }
  },
  
  "effects": {
    "backgroundBlur": {
      "enabled": true,
      "radius": 20,
      "saturation": 1.2
    },
    "cardBlur": {
      "enabled": true,
      "radius": 10
    },
    "animations": {
      "enabled": true,
      "duration": 0.25,
      "curve": "easeInOut"
    },
    "glowEffect": {
      "enabled": true,
      "color": "#00FFF5",
      "radius": 4,
      "opacity": 0.6
    }
  },
  
  "components": {
    "cards": {
      "style": "glass",
      "borderWidth": 1,
      "borderColor": "#3A4553",
      "cornerRadius": 12,
      "backgroundOpacity": 0.8,
      "hoverEffect": {
        "enabled": true,
        "scale": 1.02,
        "glowIntensity": 1.2
      }
    },
    "buttons": {
      "style": "gradient",
      "cornerRadius": 8,
      "borderWidth": 0,
      "hoverEffect": {
        "enabled": true,
        "brightness": 1.1
      }
    },
    "systemInfoCard": {
      "style": "featured",
      "height": 120,
      "backgroundGradient": ["#1A1F2C", "#252B3A"],
      "borderGlow": true
    }
  }
}
```

## Implementation Plan

### Phase 1: Core Theme System

#### 1.1 Theme Data Models

```swift
// Theme.swift
struct Theme: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let version: String
    let author: String?
    
    let popover: PopoverConfiguration
    let layout: LayoutConfiguration
    let colors: ColorConfiguration
    let fonts: FontConfiguration
    let icons: IconConfiguration
    let effects: EffectConfiguration
    let components: ComponentConfiguration
}

struct PopoverConfiguration: Codable {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let shadow: ShadowConfiguration?
}

struct ColorConfiguration: Codable {
    let background: String
    let secondaryBackground: String
    let cardBackground: String
    let primaryText: String
    let secondaryText: String
    let accent: String
    // ... other colors
    let gradient: GradientConfiguration?
}

// Additional configuration structs...
```

#### 1.2 ThemeManager Implementation

```swift
// ThemeManager.swift
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme
    @Published var availableThemes: [Theme] = []
    
    private let userDefaults = UserDefaults.standard
    private let builtInThemesPath = Bundle.main.path(forResource: "Themes", ofType: nil)
    private let userThemesPath = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                         in: .userDomainMask).first?
                                .appendingPathComponent("PulseBar/Themes")
    
    // Core methods
    func loadThemes()
    func applyTheme(_ theme: Theme)
    func saveCurrentTheme()
    func importCustomTheme(from url: URL) throws
    func validateTheme(_ theme: Theme) throws
    
    // Theme property getters for SwiftUI
    var colors: ColorConfiguration { currentTheme.colors }
    var fonts: FontConfiguration { currentTheme.fonts }
    var layout: LayoutConfiguration { currentTheme.layout }
    // ... other property getters
}
```

### Phase 2: SwiftUI Integration

#### 2.1 Environment Integration

```swift
// In App.swift or main view
.environmentObject(ThemeManager.shared)

// In views
@EnvironmentObject var themeManager: ThemeManager
```

#### 2.2 Theme Extensions

```swift
// Color+Theme.swift
extension Color {
    static func themed(_ keyPath: KeyPath<ColorConfiguration, String>) -> Color {
        return Color(hex: ThemeManager.shared.colors[keyPath: keyPath])
    }
    
    // Usage: Color.themed(\.accent)
}

// Font+Theme.swift
extension Font {
    static func themed(_ style: ThemedFontStyle, size: ThemedFontSize = .regular) -> Font {
        let themeManager = ThemeManager.shared
        let fontConfig = themeManager.fonts.primary
        
        return .custom(fontConfig.family, 
                      size: fontConfig.size.value(for: size))
               .weight(fontConfig.weight.swiftUIWeight)
    }
}
```

#### 2.3 Themed Components

```swift
// ThemedCard.swift
struct ThemedCard<Content: View>: View {
    let content: Content
    @EnvironmentObject var themeManager: ThemeManager
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: themeManager.components.cards.cornerRadius)
                    .fill(Color.themed(\.cardBackground))
                    .opacity(themeManager.components.cards.backgroundOpacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: themeManager.components.cards.cornerRadius)
                    .stroke(Color.themed(\.divider), 
                           lineWidth: themeManager.components.cards.borderWidth)
            )
            .themedGlow(enabled: themeManager.effects.glowEffect.enabled)
    }
}
```

### Phase 3: Modular Layout System

#### 3.1 Dynamic Grid Layout

```swift
// ThemedDashboardLayout.swift
struct ThemedDashboardLayout<Content: View>: View {
    let content: Content
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(minimum: 160)), 
                          count: themeManager.layout.gridColumns),
            spacing: themeManager.layout.cardSpacing
        ) {
            content
        }
        .padding(.horizontal, themeManager.layout.padding.horizontal)
    }
}
```

#### 3.2 Adaptive Component Sizing

```swift
// ThemedMetricCard.swift
struct ThemedMetricCard: View {
    let metric: MetricData
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: themedIcon(for: metric.type))
                        .font(.system(size: themeManager.icons.size.regular))
                        .foregroundColor(Color.themed(\.accent))
                    
                    Text(metric.title)
                        .font(.themed(.primary, size: .regular))
                        .foregroundColor(Color.themed(\.primaryText))
                    
                    Spacer()
                }
                
                // Adaptive content based on theme layout
                if themeManager.layout.gridColumns == 1 {
                    horizontalMetricLayout
                } else {
                    verticalMetricLayout
                }
            }
        }
        .frame(height: adaptiveCardHeight)
    }
    
    private var adaptiveCardHeight: CGFloat {
        themeManager.layout.gridColumns == 1 ? 60 : 80
    }
}
```

### Phase 4: Theme Picker UI

#### 4.1 Theme Preview Component

```swift
// ThemePreview.swift
struct ThemePreview: View {
    let theme: Theme
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Mini popover preview
            RoundedRectangle(cornerRadius: theme.popover.cornerRadius / 2)
                .fill(Color(hex: theme.colors.background))
                .frame(width: 120, height: 80)
                .overlay(
                    VStack(spacing: 4) {
                        // Sample header
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: theme.colors.cardBackground))
                            .frame(height: 12)
                        
                        // Sample cards
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: theme.colors.accent).opacity(0.3))
                                .frame(height: 20)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: theme.colors.cardBackground))
                                .frame(height: 20)
                        }
                    }
                    .padding(8)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
            
            Text(theme.name)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .onTapGesture {
            ThemeManager.shared.applyTheme(theme)
        }
    }
}
```

#### 4.2 Theme Picker View

```swift
// ThemePicker.swift
struct ThemePicker: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTheme: Theme
    
    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.currentTheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Built-in Themes")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), 
                     spacing: 16) {
                ForEach(themeManager.builtInThemes) { theme in
                    ThemePreview(
                        theme: theme,
                        isSelected: selectedTheme.id == theme.id
                    )
                }
            }
            
            if !themeManager.customThemes.isEmpty {
                Divider()
                
                sectionHeader("Custom Themes")
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), 
                         spacing: 16) {
                    ForEach(themeManager.customThemes) { theme in
                        ThemePreview(
                            theme: theme,
                            isSelected: selectedTheme.id == theme.id
                        )
                    }
                }
            }
            
            Spacer()
            
            // Import theme button
            Button("Import Custom Theme...") {
                importCustomTheme()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(.primary)
    }
}
```

### Phase 5: Built-in Themes

#### 5.1 Basic Theme (Default)
- Minimal, clean design
- System colors
- Standard spacing
- Default popover size: 360×580

#### 5.2 Futuristic Theme
- Dark background (#0A0F1C)
- Neon accents (#00FFF5, #FF6B9D)
- Blurred glass effects
- Larger popover: 380×620

#### 5.3 Colorful Theme (CleanMyMac-inspired)
- Vibrant gradients
- Bright accent colors
- Playful icons
- Dynamic card backgrounds

#### 5.4 Nature Glow Theme
- Green/gold color palette
- Soft gradients
- Rounded corners
- Warm glow effects

## Technical Considerations

### Performance

1. **Theme Caching**: Cache parsed themes to avoid repeated JSON parsing
2. **Lazy Loading**: Load custom themes on demand
3. **Memory Management**: Unload unused theme resources
4. **Smooth Transitions**: Animate theme changes smoothly

### Validation & Error Handling

```swift
enum ThemeError: LocalizedError {
    case invalidJSON
    case missingRequiredFields
    case invalidColorFormat
    case unsupportedVersion
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Theme file contains invalid JSON"
        case .missingRequiredFields:
            return "Theme is missing required fields"
        case .invalidColorFormat:
            return "Theme contains invalid color values"
        case .unsupportedVersion:
            return "Theme version is not supported"
        case .fileNotFound:
            return "Theme file could not be found"
        }
    }
}
```

### Backwards Compatibility

- Version checking for theme files
- Migration support for older theme formats
- Graceful degradation for unsupported features
- Default fallbacks for missing properties

### User Experience

1. **Live Preview**: Real-time theme preview while browsing
2. **Smooth Transitions**: Animated theme switching
3. **Theme Validation**: Clear error messages for invalid themes
4. **Reset Option**: Quick way to revert to default theme
5. **Export Current**: Allow users to export current theme settings

## File Organization

```
PulseBar/
├── Resources/
│   └── Themes/
│       ├── basic.json
│       ├── futuristic.json
│       ├── colorful.json
│       └── nature-glow.json
├── Models/
│   ├── Theme.swift
│   ├── ThemeConfiguration.swift
│   └── ThemeError.swift
├── Services/
│   └── ThemeManager.swift
├── Views/
│   ├── Theming/
│   │   ├── ThemedView.swift
│   │   ├── ThemePreview.swift
│   │   ├── ThemePicker.swift
│   │   └── ThemedComponents/
│   │       ├── ThemedCard.swift
│   │       ├── ThemedButton.swift
│   │       ├── ThemedText.swift
│   │       └── ThemedMetricCard.swift
│   └── Settings/
│       └── ThemeSettingsView.swift
└── Extensions/
    ├── Color+Theme.swift
    ├── Font+Theme.swift
    ├── View+Theme.swift
    └── Bundle+Theme.swift
```

## Testing Strategy

1. **Unit Tests**: Theme parsing, validation, and application
2. **UI Tests**: Theme switching and component rendering
3. **Performance Tests**: Memory usage and switching speed
4. **Integration Tests**: Custom theme loading and saving

## Future Enhancements

1. **Theme Editor**: In-app theme creation/editing
2. **Theme Sharing**: Export/share custom themes
3. **Dynamic Themes**: Time-based or system-responsive themes
4. **Advanced Animations**: Custom transition effects between themes
5. **Theme Store**: Community theme repository
6. **Accessibility**: High contrast and accessibility-focused themes

---

This comprehensive theming system will provide PulseBar with a flexible, extensible foundation for visual customization while maintaining code organization and performance.