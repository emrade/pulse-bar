# Technical Debt

This document tracks known technical debt in the PulseBar project that should be addressed in future development cycles.

## Swift Concurrency - Main Actor Isolation Warnings

**Status:** Active (as of August 11, 2025)  
**Priority:** Low (does not affect functionality)  
**Files affected:** 
- `PulseBar/Utilities/FormatterUtility.swift:18:31`
- `PulseBar/Utilities/FormatterUtility.swift:19:32`

### Issue Description
The compiler generates main actor isolation warnings when `FormatterUtility` accesses settings through `SettingsAccessor.getCurrentSettings()`. The warnings are:

1. "Call to main actor-isolated initializer 'init()' in a synchronous nonisolated context"
2. "Main actor-isolated property 'settings' can not be referenced from a nonisolated context"

### Root Cause
Swift's concurrency system is being overly conservative about actor isolation because:
- `SettingsManager` is marked as `@MainActor` 
- `AppSettings()` initializer is inferred as main actor-isolated due to proximity to `SettingsManager`
- `FormatterUtility` is not actor-isolated, creating a mismatch

### Impact
- **Runtime:** None - code functions correctly
- **Build:** Project builds successfully despite warnings
- **Development:** Compiler warnings visible during build process

### Current Workaround
Warnings are suppressed/ignored as they don't affect functionality. UserDefaults access is thread-safe, and struct creation is safe from any context.

### Potential Solutions (for future implementation)

#### Option 1: Make FormatterUtility MainActor-isolated
```swift
@MainActor
final class FormatterUtility {
    // All methods become main actor-isolated
}
```
**Pros:** Clean, follows UI utility patterns  
**Cons:** Requires all callers to be main actor-isolated or use async/await

#### Option 2: Strategic nonisolated annotations
```swift
struct SettingsAccessor {
    nonisolated static func getCurrentSettings() -> AppSettings {
        // Mark method as safe for any context
    }
}
```
**Pros:** Minimal changes, explicit about thread safety  
**Cons:** Requires careful analysis of thread safety

#### Option 3: Async formatting methods
```swift
final class FormatterUtility {
    @MainActor
    func formatTemperature(_ celsius: Double) async -> String {
        // Async version for main actor access
    }
}
```
**Pros:** Future-proof, follows Swift Concurrency patterns  
**Cons:** More invasive changes required

### Recommended Approach
When addressing this debt:
1. Start with Option 2 (nonisolated annotations) as it requires minimal changes
2. If that doesn't resolve all warnings, consider Option 1 (MainActor class)
3. Ensure all unit tests pass after changes
4. Verify UI performance is not impacted

### Related Files
- `PulseBar/Models/AppSettings.swift` - Contains SettingsManager and SettingsAccessor
- `PulseBar/Services/TemperatureService.swift` - Uses FormatterUtility
- `PulseBar/Models/Metrics.swift` - Uses FormatterUtility for various formatting

### Notes
- This is a common issue when migrating to Swift 6 strict concurrency
- Similar patterns may exist elsewhere in the codebase
- Consider addressing as part of a broader Swift Concurrency audit