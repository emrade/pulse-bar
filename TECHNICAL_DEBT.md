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

---

## UI Layout Improvements (COMPLETED - August 11, 2025)

**Status:** Completed ✅  
**Priority:** High (user experience)  
**Files affected:**
- `PulseBar/Views/DashboardView.swift` - Grid layout implementation
- `PulseBar/Utils/WindowSizing.swift` - Centralized sizing system
- All `PulseBar/Views/AdvancedViews/*.swift` - Updated to use centralized sizing
- `PulseBar/Views/SettingsView.swift` - Updated sizing
- `PulseBar/Views/AboutView.swift` - Updated sizing

### Issue Description (RESOLVED)
The main dashboard had a long vertical stack of 7 metric items that made the window quite tall. User requested a grid layout with items side by side to reduce vertical space usage.

### Implementation Completed
1. **Grid Layout**: Converted the vertical VStack to a LazyVGrid with 2 flexible columns
2. **Icon Alignment**: Fixed alignment issues between icons and titles in grid cards  
3. **Header/Footer**: Ensured proper visibility of header (PulseBar title) and footer (Settings/About/Quit buttons)
4. **Centralized Sizing**: Created `WindowSizing.swift` utility for consistent sizing across all views
5. **Window Optimization**: Changed main window size from 360×700 to 400×550 for better proportions

### Key Changes Made
- Created `TappableMetricCardView` for grid layout with proper alignment
- Window size standardized to 400×600 pixels across all views (adjusted from initial 550px)
- All advanced views now use `.standardWindowFrame()` modifier
- Improved spacing and padding for better visual balance
- Fixed alignment from `.top` to `.center` for icon-title pairs

### Benefits Achieved
- **Optimized Height**: Window height decreased from 700px to 600px with proper header/footer visibility
- **Better Proportions**: Improved width-to-height ratio for modern displays
- **Consistent Sizing**: All views now use centralized sizing system
- **Enhanced UX**: Grid layout reduces scrolling and provides better visual organization
- **Maintainability**: Future size changes can be made in one place (`WindowSizing.swift`)
- **System Overview**: Added full-width system information card showing computer name, chip, memory, model, and macOS version

### Additional Features Added
- **SystemInfoService**: Centralized service for retrieving system information
- **SystemInfoCardView**: Full-width card at top of dashboard displaying:
  - Computer name (e.g., "My MacBook Pro")
  - Chip information (e.g., "Apple M4 Max")
  - Memory size (e.g., "36GB")
  - Device model (e.g., "MacBook Pro M3 Max")
  - macOS version (e.g., "macOS 15.5.0")

---

## Speed Test Accuracy - Upload Speed Measurement

**Status:** Active (as of August 11, 2025)  
**Priority:** Medium (affects user experience and accuracy)  
**Files affected:**
- `PulseBar/Services/NetworkService.swift` - Upload speed measurement logic

### Issue Description
The current upload speed test, while improved, may still not provide optimal accuracy due to limitations in the HTTP-based approach. Upload speeds often appear lower than expected, even accounting for typical ISP asymmetry.

### Root Cause
**Current Implementation Limitations:**
1. **HTTP Overhead:** POST request headers, response processing, and server-side handling add significant overhead
2. **Server Processing Time:** Test servers (httpbin.org, etc.) may have variable processing delays
3. **Single-threaded Approach:** Only one upload stream, doesn't test maximum bandwidth utilization  
4. **Fixed Data Size:** 2MB may be too small for fast connections or too large for slow ones
5. **Network Stack Overhead:** URLSession abstracts away low-level networking optimizations

### Impact
- **User Experience:** Upload speeds may appear significantly lower than actual capability
- **Comparison:** Results may not match commercial speed test tools (Speedtest.net, Fast.com)
- **Trust:** Users may question accuracy when speeds seem unreasonably low

### Current Implementation
```swift
// Current: HTTP POST with fixed 2MB payload
let testDataSize = 2_000_000 // 2MB test data
var testData = Data(count: testDataSize)
// ... POST to httpbin.org/post
```

### Potential Solutions (for future implementation)

#### Option 1: Multi-threaded Upload Testing
```swift
// Multiple concurrent upload streams for better bandwidth utilization
let concurrentStreams = 3
await withTaskGroup(of: Double.self) { group in
    for stream in 0..<concurrentStreams {
        group.addTask {
            return try await uploadSingleStream(streamId: stream)
        }
    }
    // Aggregate results from all streams
}
```
**Pros:** Better utilizes available bandwidth, more accurate for high-speed connections  
**Cons:** More complex implementation, higher resource usage

#### Option 2: Dynamic Data Size Based on Connection Speed
```swift
// Adaptive data size based on initial connection assessment
let estimatedConnectionSpeed = try await quickSpeedEstimate()
let optimalDataSize = calculateOptimalDataSize(for: estimatedConnectionSpeed)
let testData = generateTestData(size: optimalDataSize)
```
**Pros:** Optimizes test duration and accuracy for different connection speeds  
**Cons:** Requires initial speed estimation, more complex logic

#### Option 3: Raw Socket Implementation
```swift
// Use lower-level networking for more precise measurement
import Network
let connection = NWConnection(to: endpoint, using: .tcp)
// Direct TCP upload with precise timing
```
**Pros:** Eliminates HTTP overhead, more precise timing, better control  
**Cons:** Significantly more complex, requires test server infrastructure

#### Option 4: Integration with Dedicated Speed Test Services
```swift
// Use APIs from established speed test providers
let speedTestAPI = SpeedTestAPI(provider: .cloudflare) // or .ookla, .netflix
let result = try await speedTestAPI.runUploadTest()
```
**Pros:** Leverages professional speed test infrastructure, highly accurate  
**Cons:** External dependencies, potential costs, API rate limits

#### Option 5: WebRTC-based P2P Testing
```swift
// Use WebRTC for peer-to-peer speed testing
let webRTCSpeedTest = WebRTCSpeedTest()
let uploadSpeed = try await webRTCSpeedTest.measureUploadSpeed()
```
**Pros:** No server dependency, can test true peer-to-peer speeds  
**Cons:** Very complex implementation, requires WebRTC integration

### Recommended Approach
**Phase 1 (Quick Wins):**
1. **Option 2** - Implement dynamic data sizing based on connection speed
2. Improve timing precision by measuring only data transfer (exclude server processing)
3. Add multiple test endpoints with geographic diversity

**Phase 2 (Major Improvement):**
1. **Option 1** - Implement multi-threaded upload testing
2. Add bandwidth saturation detection (increase concurrent streams until no improvement)

**Phase 3 (Professional Grade):**
1. **Option 4** - Integrate with established speed test APIs for comparison/validation
2. Implement caching and offline fallbacks

### Alternative Considerations
- **User Education:** Add tooltips explaining why upload speeds are typically lower than download
- **Calibration:** Compare results with known speed test tools and apply correction factors
- **Transparency:** Show detailed breakdown of test phases and timing for debugging

### Related Files
- `PulseBar/Services/NetworkService.swift` - Main implementation
- `PulseBar/Models/Metrics.swift` - Speed test data structures
- `PulseBar/Views/AdvancedViews/AdvancedNetworkView.swift` - UI display

### Notes
- Upload speed accuracy is inherently challenging due to network asymmetry
- Consider implementing a "calibration mode" that compares with established speed tests
- Professional speed test tools use sophisticated techniques (multiple streams, adaptive sizing, etc.)
- May want to research how Speedtest CLI, Fast.com, and similar tools implement upload testing