# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PulseBar is a native macOS menu bar application for real-time system monitoring. Built with SwiftUI and Combine, it provides CPU, memory, disk, battery, network, and device monitoring with a sophisticated theming system.

**Bundle Identifier**: `com.emrade.PulseBar`
**Minimum macOS**: 12.0 (Monterey)
**Swift Version**: 5.0+

## Build & Development Commands

### Building
```bash
# Clean build (recommended for releases)
xcodebuild -project PulseBar.xcodeproj -scheme PulseBar -configuration Release -derivedDataPath ./DerivedData clean build

# Quick development build
xcodebuild -project PulseBar.xcodeproj -scheme PulseBar -configuration Debug build

# Open in Xcode
open PulseBar.xcodeproj
```

### Testing
```bash
# Run unit tests
xcodebuild test -project PulseBar.xcodeproj -scheme PulseBar -destination 'platform=macOS'

# Run specific test
xcodebuild test -project PulseBar.xcodeproj -scheme PulseBar -destination 'platform=macOS' -only-testing:PulseBarTests/ServiceTests
```

### Code Signing & Release
```bash
# Verify code signature
codesign -vv DerivedData/Build/Products/Release/PulseBar.app

# Create distribution ZIP
cd DerivedData/Build/Products/Release && zip -r PulseBar-v1.0.0.zip PulseBar.app
```

## Architecture Overview

### Core Pattern: Service-Oriented MVVM + Reactive Programming

**Data Flow**: Services → SystemMonitor → ViewModels → SwiftUI Views

1. **Service Layer** (`Services/`): Protocol-based system monitoring services
   - Each service publishes metrics via `@Published` properties
   - Services run on background queues with configurable polling intervals
   - All external process execution is secured with input validation and timeouts

2. **SystemMonitor** (`SystemMonitor.swift`): Central orchestrator
   - Singleton that coordinates all 12+ monitoring services
   - Manages service lifecycle and error handling
   - Publishers aggregate data for UI consumption

3. **Reactive UI** (`Views/`, `ViewModels/`): SwiftUI + Combine
   - ViewModels subscribe to SystemMonitor publishers
   - Views automatically update when data changes
   - Menu bar integration via NSStatusItem + NSPopover

### Security Architecture

The codebase implements comprehensive security measures:
- **Input Validation**: All external process arguments are sanitized
- **Timeout Protection**: 10-second timeouts on all external processes  
- **Environment Sanitization**: Controlled environment variables for external processes
- **SSL Validation**: Network requests use certificate validation and domain whitelisting
- **Centralized Logging**: Security events tracked via `PulseBarLogger` using `os.log`

### Theming System

Advanced JSON-based theming with runtime switching:
- **Theme Engine** (`ThemeManager.swift`): Validates and manages theme files
- **Built-in Themes** (`Resources/Themes/`): 5 pre-designed themes
- **Custom Fonts** (`Resources/Fonts/`): Variable fonts per theme
- **Security**: 1MB file size limits, injection pattern detection, comprehensive validation

## Key Technical Decisions

### Menu Bar Application Pattern
- **LSUIElement = true**: No dock icon, menu bar only
- **NSStatusItem + NSPopover**: Click menu bar → show SwiftUI interface
- **Background Operation**: Continuous monitoring with minimal resource usage (<5% CPU, <150MB RAM)

### System Integration Strategy
- **Native APIs**: Direct IOKit, Mach kernel, CoreWLAN integration
- **Graceful Degradation**: Works with limited permissions
- **Sandbox Compatible**: App Store ready with minimal entitlements

### Performance Optimization
- **Smart Polling**: Different intervals per metric type (1.5s CPU, 10s Battery)
- **Background Processing**: All system calls on background queues
- **Main Actor Protection**: UI updates isolated to main thread

### External Dependencies
- **Zero External Dependencies**: Pure Apple ecosystem (Foundation, SwiftUI, Combine, IOKit, CoreWLAN)
- **Font Assets**: Embedded variable fonts for theme consistency

## Development Guidelines

### Service Development
- All services must implement `ServiceProtocols.swift` protocols
- Use `@Published` properties for reactive data flow
- Background processing with `Task { await ... }`
- Comprehensive error handling with `PulseBarLogger`

### Security Requirements
- External process execution requires input sanitization via `sanitizeArguments()`
- Network requests must use `createSecureURLSession()` with SSL validation
- File operations need size limits and content validation
- All security events must be logged with appropriate severity levels

### UI Development
- Follow established SwiftUI + theme patterns in `Views/`
- Use `ThemedCard`, `ThemedMetricCard` for consistency
- Implement responsive design for different screen sizes
- Test theme switching for all new components

### Testing Strategy
- Protocol-based services enable easy mocking
- Unit tests should cover service protocols and core business logic
- Integration tests for SystemMonitor coordination
- UI tests for critical user workflows

## File Structure Notes

### Core Services (`Services/`)
- `SystemMonitor.swift`: Central coordinator and data aggregator
- `*Service.swift`: Individual monitoring services (CPU, Memory, etc.)
- `ServiceProtocols.swift`: Protocols defining service interfaces
- `ThemeManager.swift`: Theme loading and validation

### Security & Utilities (`Utilities/`)
- `Logger.swift`: Centralized logging with security event tracking
- `FormatterUtility.swift`: Data formatting with localization
- `MetricRemarkEngine.swift`: Contextual metric analysis

### Theme Resources (`Resources/`)
- `Themes/*.json`: Theme definitions with comprehensive validation
- `Fonts/*.ttf`: Variable fonts for theme typography

### Views Architecture (`Views/`)
- `DashboardView.swift`: Main interface
- `AdvancedViews/`: Detailed metric views
- `Theming/`: Theme-aware UI components
- `Components/`: Reusable UI elements

## Common Tasks

### Adding a New Metric
1. Create service implementing `ServiceProtocols.swift`
2. Add to `SystemMonitor.swift` initialization
3. Create corresponding view in `Views/AdvancedViews/`
4. Update `DashboardView.swift` to display new metric
5. Add appropriate logging and error handling

### Security Testing
- External process execution: Test argument injection protection
- Network requests: Verify SSL validation and timeout handling
- File operations: Test size limits and content validation
- Review security logs for suspicious activity patterns

### Theme Development
- Follow existing JSON schema in `Resources/Themes/`
- Test theme validation in `ThemeManager.swift`
- Ensure all UI components support new theme properties
- Validate font loading and fallback behavior