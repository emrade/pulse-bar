# PulseBar - macOS System Monitor

A native macOS menu-bar application providing lightweight, real-time system monitoring for power users and developers.

## Overview

PulseBar displays essential system metrics (CPU, memory, storage, battery, Wi-Fi, connected devices) in a compact, performant, and privacy-respecting UI directly in the macOS menu bar.

**Target Users:** Power users, developers, system administrators, macOS enthusiasts  
**Performance Goals:** <5% CPU usage while idle, <150MB memory footprint  
**Minimum macOS:** 12.0+
**License:** Open Source (MIT)

## Download & Installation

### For Users
1. **Download:** Get the latest `PulseBar-v1.0.0.zip` from [GitHub Releases](https://github.com/[username]/PulseBar/releases)
2. **Extract:** Double-click the ZIP file to extract `PulseBar.app`
3. **Install:** Drag `PulseBar.app` to your Applications folder
4. **Launch:** Open PulseBar from Applications or Spotlight
5. **First Run:** macOS will verify the app (may take a few seconds)
6. **Permissions:** Grant required permissions when prompted (see [Permissions](#permissions))

### For Developers
1. **Clone:** `git clone https://github.com/[username]/PulseBar.git`
2. **Build:** Open `PulseBar.xcodeproj` in Xcode 14+
3. **Run:** Build and run (⌘R) for development

## Distribution Model

**Open Source Development:** Full source code available on GitHub  
**Direct Distribution:** Pre-built, signed & notarized releases for easy installation  
**No App Store:** Distributed directly to avoid App Store limitations on system monitoring APIs

## Development Todo List

This comprehensive todo list is organized by development phases, following the PRD specifications. Each task includes implementation details, files to create/modify, and acceptance criteria.

### Phase 1: Project Setup & Foundation ✅ COMPLETED

#### 1.1. Repository & Project Setup
- [x] **Create public GitHub repository** ✅
  - ✅ Initialize with .gitignore for Xcode/Swift
  - ✅ Add MIT license for open source distribution
  - ✅ Setup repository description and topics
  - [ ] Configure GitHub Pages for project website (optional)
  - ✅ Create initial project structure

- [x] **Create Xcode project** ✅
  - ✅ File: `PulseBar.xcodeproj`
  - ✅ Target: macOS App
  - ✅ Minimum deployment: macOS 12.0
  - ✅ Language: Swift, Framework: SwiftUI

- [x] **Add required frameworks** ✅
  - ✅ Link: `CoreWLAN.framework`, `IOKit.framework`
  - ✅ Add App Sandbox entitlement (permissive initially)
  - ✅ Configure build settings for menu bar app

- [x] **Setup project structure** ✅
  ```
  PulseBar/
  ├─ PulseBarApp.swift ✅
  ├─ AppDelegate.swift ✅
  ├─ Models/ ✅
  ├─ Services/ ✅
  ├─ ViewModels/ ✅
  ├─ Views/ ✅
  │  ├─ DashboardView.swift ✅
  │  └─ MetricRowView.swift ✅
  ├─ Utilities/ ✅
  ├─ Resources/
  └─ Tests/
  ```

### Phase 2: Core App Shell & Menu Bar Integration ✅ COMPLETED

#### 2.1. App Delegate & Status Item
- [x] **Implement AppDelegate** ✅
  - ✅ File: `AppDelegate.swift`
  - ✅ Create `NSStatusItem` with variable length
  - ✅ Add SF Symbol icon: "waveform.path.ecg"
  - ✅ Handle left-click (open popover) and right-click (context menu)
  - ✅ **Acceptance:** Status item appears in menu bar on launch

- [x] **Create NSPopover integration** ✅
  - ✅ Use `NSHostingController` with SwiftUI `DashboardView`
  - ✅ Set popover behavior to `.transient`
  - ✅ Handle popover positioning and dismissal
  - ✅ **Acceptance:** Clicking status item opens/closes popover

#### 2.2. Dashboard Foundation
- [x] **Create DashboardView stub** ✅
  - ✅ File: `Views/DashboardView.swift`
  - ✅ Single column layout with placeholder rows
  - ✅ SF Symbol icons for each metric type
  - ✅ Footer with Settings and About links
  - ✅ **Acceptance:** Popover shows structured placeholder UI

- [x] **Create MetricRowView component** ✅
  - ✅ File: `Views/MetricRowView.swift`
  - ✅ Reusable row: [icon] [label] [value] [visual indicator]
  - ✅ Support for progress bars and sparklines
  - ✅ **Acceptance:** Consistent metric display format

### Phase 3: Data Models & Core Architecture ✅ COMPLETED

#### 3.1. Data Models
- [x] **Define core data models** ✅
  - ✅ File: `Models/Metrics.swift`
  - ✅ `MetricsSnapshot` struct containing all metric data
  - ✅ Individual models: `CPUMetrics`, `MemoryMetrics`, `DiskMetrics`, `BatteryMetrics`, `WiFiMetrics`, `DeviceMetrics`
  - ✅ **Acceptance:** Type-safe data structures for all metrics

#### 3.2. SystemMonitor Orchestrator
- [x] **Create SystemMonitor** ✅
  - ✅ File: `Services/SystemMonitor.swift`
  - ✅ Singleton pattern with reactive architecture
  - ✅ `@Published var snapshot: MetricsSnapshot`
  - ✅ Coordinate all service polling intervals
  - ✅ Combine publishers for real-time updates
  - ✅ **Acceptance:** Central point for all system metric data

#### 3.3. Service Architecture
- [x] **Implement service protocols** ✅
  - ✅ File: `Services/ServiceProtocols.swift`
  - ✅ Protocol-based architecture for testability
  - ✅ Async/await support with Combine publishers
  - ✅ **Acceptance:** Clean separation of concerns

#### 3.4. Real CPU Monitoring
- [x] **Implement CPUService with macOS APIs** ✅
  - ✅ File: `Services/CPUService.swift`
  - ✅ Real Mach kernel API integration (`host_processor_info`)
  - ✅ Per-core and overall CPU usage calculation
  - ✅ Thread-safe with proper memory management
  - ✅ **Acceptance:** Real CPU data updating every 1.5 seconds

### Phase 4: System Metric Services Implementation ✅ COMPLETED

#### 4.1. CPU Monitoring Service ✅ COMPLETED
- [x] **Implement CPUService** ✅
  - ✅ File: `Services/CPUService.swift`
  - ✅ Use Mach APIs: `host_processor_info`
  - ✅ Calculate CPU percentage from tick deltas
  - ✅ Thread-safe implementation with NSLock
  - ✅ Proper memory management and error handling
  - ✅ Default polling: 1.5 seconds
  - ✅ **Acceptance:** Real CPU usage data displaying correctly

- [ ] **Add CPU service tests**
  - File: `Tests/CPUServiceTests.swift`
  - Mock tick counter scenarios
  - Test percentage calculation accuracy
  - **Acceptance:** Unit tests pass with synthetic data

#### 4.2. Memory Monitoring Service ✅ COMPLETED
- [x] **Implement MemoryService** ✅
  - ✅ File: `Services/MemoryService.swift`
  - ✅ Use `host_statistics64` with `vm_statistics64_data_t`
  - ✅ Calculate used, free, cached memory with proper page calculations
  - ✅ Use `sysctlbyname("hw.memsize")` for total physical memory
  - ✅ Format with `ByteCountFormatter` showing used and available memory
  - ✅ Thread-safe async implementation
  - ✅ Default polling: 2 seconds
  - ✅ **Acceptance:** Real memory data displaying correctly

- [ ] **Add Memory service tests**
  - File: `Tests/MemoryServiceTests.swift`
  - Mock vm statistics structures
  - Test memory calculations and formatting

#### 4.2.1. UI Improvements ✅ COMPLETED
- [x] **Enhanced metric display layout** ✅
  - ✅ Two-row design prevents text truncation
  - ✅ Better visual hierarchy with proper spacing
  - ✅ Wider popover (360px) for improved readability
  - ✅ Displays "used • available" memory format
  - ✅ **Acceptance:** All text fully visible, no truncation

#### 4.3. Storage Monitoring Service ✅ COMPLETED
- [x] **Implement DiskService** ✅
  - ✅ File: `Services/DiskService.swift`
  - ✅ Use `FileManager.mountedVolumeURLs` and `resourceValues`
  - ✅ Monitor boot volume and external drives
  - ✅ Filter volumes >1GB, sort boot volume first
  - ✅ Default polling: 10 seconds
  - ✅ **Acceptance:** Disk usage accurate, external drives detected

- [ ] **Add Disk service tests**
  - File: `Tests/DiskServiceTests.swift`
  - Mock filesystem attributes
  - Test space calculations and formatting

#### 4.4. Battery Monitoring Service ✅ COMPLETED
- [x] **Implement BatteryService** ✅
  - ✅ File: `Services/BatteryService.swift`
  - ✅ Use `pmset -g batt` command for reliable battery data
  - ✅ Track percentage, charging state, time remaining
  - ✅ Proper AC power vs battery detection
  - ✅ Default polling: 10 seconds
  - ✅ **Acceptance:** Battery data accurate on MacBook, no crashes

- [ ] **Add Battery service tests**
  - File: `Tests/BatteryServiceTests.swift`
  - Mock power source descriptions
  - Test state parsing and formatting

#### 4.5. Wi-Fi Monitoring Service ✅ COMPLETED
- [x] **Implement WiFiService** ✅
  - ✅ File: `Services/WiFiService.swift`
  - ✅ Use CoreWLAN: `CWWiFiClient.shared().interface()`
  - ✅ Track SSID, BSSID, RSSI, link speed
  - ✅ Handle WiFi power state and connection status
  - ✅ Default polling: 5 seconds
  - ✅ **Acceptance:** Wi-Fi data updates and displays correctly

- [ ] **Add Wi-Fi service tests**
  - File: `Tests/WiFiServiceTests.swift`
  - Mock CoreWLAN interface data
  - Test signal strength calculations

#### 4.6. Connected Devices Service ✅ COMPLETED
- [x] **Implement DeviceService** ✅
  - ✅ File: `Services/DeviceService.swift`
  - ✅ Parse `system_profiler SPUSBDataType -json` for USB devices
  - ✅ Use `FileManager.mountedVolumeURLs` for mounted volumes
  - ✅ Device filtering (remove hubs/controllers) and deduplication
  - ✅ Device metadata: name, type, vendor/product ID, mount points
  - ✅ **Acceptance:** USB and storage devices display correctly

- [ ] **Add Device service tests**
  - File: `Tests/DeviceServiceTests.swift`
  - Mock system_profiler output
  - Test device parsing and change detection

#### 4.7. Network Speed Test Service
- [ ] **Implement NetworkService**
  - File: `Services/NetworkService.swift`
  - Manual-trigger only (no auto-testing)
  - Timed download test (5-10MB file)
  - Calculate Mbps: `(bytes * 8) / seconds / 1e6`
  - Include progress reporting and cancellation
  - **Acceptance:** Speed test runs and produces reasonable results

- [ ] **Add Network service tests**
  - File: `Tests/NetworkServiceTests.swift`
  - Mock network responses
  - Test speed calculations and cancellation

### Phase 5: ViewModels & UI Integration

#### 5.1. Dashboard ViewModel
- [ ] **Implement DashboardViewModel**
  - File: `ViewModels/DashboardViewModel.swift`
  - Subscribe to `SystemMonitor.snapshot`
  - Expose formatted data for views
  - Handle UI state management
  - **Acceptance:** UI updates reactively with system data

#### 5.2. Complete Dashboard Views
- [ ] **Enhance DashboardView**
  - File: `Views/DashboardView.swift`
  - Wire to `DashboardViewModel`
  - Implement all metric rows with real data
  - Add "Run Speed Test" button with progress
  - **Acceptance:** All metrics display with live data

- [ ] **Create SettingsView**
  - File: `Views/SettingsView.swift`
  - Polling interval controls
  - Auto-launch at login toggle
  - Metric enable/disable toggles
  - Reset to defaults button
  - **Acceptance:** Settings persist via UserDefaults

### Phase 6: Advanced Features & Polish

#### 6.1. Performance Optimization
- [ ] **Implement polling optimization**
  - Background queue processing
  - UI update coalescing (100-200ms batching)
  - Low Power Mode detection
  - **Acceptance:** CPU usage <5% while idle

- [ ] **Add performance profiling**
  - Use Instruments (Time Profiler & Allocations)
  - Identify and fix performance bottlenecks
  - **Acceptance:** Memory usage <150MB

#### 6.2. Error Handling & Permissions
- [ ] **Implement permission handling**
  - Clear UI messages for missing permissions
  - Step-by-step permission grant instructions
  - Graceful fallbacks when access denied
  - **Acceptance:** App works with limited permissions

- [ ] **Add comprehensive error handling**
  - Service failure recovery
  - Network timeout handling
  - API permission error handling
  - **Acceptance:** App never crashes from permission issues

#### 6.3. Settings & Preferences
- [ ] **Complete settings implementation**
  - File: `Views/SettingsView.swift`
  - All configurable options from PRD
  - UserDefaults persistence
  - Settings validation and safe ranges
  - **Acceptance:** All settings work and persist

### Phase 7: Testing & Quality Assurance

#### 7.1. Unit Testing
- [ ] **Complete service unit tests**
  - All services have protocol interfaces
  - Mock implementations for testing
  - Edge case coverage
  - **Acceptance:** >80% code coverage on services

- [ ] **Add integration tests**
  - Real hardware testing on dev machines
  - Cross-validation with system tools
  - **Acceptance:** Metrics match system tools within tolerance

#### 7.2. UI Testing
- [ ] **Implement UI tests**
  - File: `Tests/UITests.swift`
  - Popover open/close behavior
  - Settings interaction
  - Speed test run/cancel
  - **Acceptance:** All UI interactions work reliably

#### 7.3. Manual QA Checklist
- [ ] **Core functionality testing**
  - [ ] Popover opens/closes reliably
  - [ ] All metrics display and update correctly
  - [ ] Speed test runs and cancels properly
  - [ ] Settings save and load correctly
  - [ ] Device connect/disconnect detected
  - [ ] App responsive under load

- [ ] **Permission scenarios**
  - [ ] App works without Full Disk Access
  - [ ] Wi-Fi permission handling
  - [ ] Graceful degradation when permissions denied

- [ ] **Performance validation**
  - [ ] CPU usage <5% while idle
  - [ ] Memory usage <150MB
  - [ ] UI remains responsive during polling

### Phase 8: Packaging & Distribution

#### 8.1. Code Signing & Notarization
- [ ] **Setup code signing for distribution**
  - For GitHub distribution: Use ad-hoc signing (no Apple Developer Program needed)
  - Alternative: Apple Developer Program ($99/year) for Developer ID signing (recommended for wider distribution)
  - Configure signing in Xcode build settings
  - **Acceptance:** App builds and runs on other Macs

- [ ] **Optional: Implement notarization** (requires Apple Developer Program)
  - Only needed for automatic Gatekeeper approval
  - Without notarization: Users see "unidentified developer" warning but can still install
  - `xcrun notarytool` integration if pursuing notarization
  - **Acceptance:** App installs smoothly or shows manageable security warning

#### 8.2. Auto-Update System
- [ ] **Integrate Sparkle framework**
  - Sparkle v2 implementation
  - Secure update packages
  - Update check scheduling
  - **Acceptance:** Auto-update works with signed packages

#### 8.3. Distribution Preparation
- [ ] **Create distribution build**
  - Archive build configuration for Release
  - Create signed & notarized .app bundle
  - Test app launches correctly from build
  - **Acceptance:** Signed app bundle ready for packaging

- [ ] **ZIP packaging for distribution**
  - Create ZIP archive: `PulseBar-v1.0.0.zip` containing `PulseBar.app`
  - Preserve app bundle structure and permissions
  - Test ZIP extraction and app launch
  - Verify code signature remains valid after ZIP/unzip
  - **Acceptance:** ZIP file installs and runs correctly

- [ ] **Setup GitHub Releases automation**
  - Configure GitHub Actions workflow for releases
  - Automated ZIP creation from signed app
  - Release notes generation from git commits/PRs
  - Asset upload with proper naming: `PulseBar-v{version}.zip`
  - Version tagging strategy (semantic versioning)
  - **Acceptance:** Push tag creates GitHub release with ZIP

- [ ] **Installation testing**
  - Test complete user flow: download ZIP → extract → drag to Applications → launch
  - Verify on clean macOS system without Xcode
  - Test Gatekeeper behavior (with/without Developer ID signing)
  - Document installation steps for users if security warnings appear
  - **Acceptance:** Users can install with clear instructions for any security prompts

### Phase 9: Documentation & Release

#### 9.1. Documentation
- [ ] **Complete README for users**
  - Clear download and installation instructions
  - Permission setup guide with screenshots
  - Feature overview with visual examples
  - Troubleshooting common issues
  - **Acceptance:** Non-technical users can install easily

- [ ] **Create developer documentation**
  - Build and development setup
  - Architecture overview
  - Contributing guidelines
  - Code style guide
  - **Acceptance:** Developers can contribute effectively

- [ ] **Add project metadata**
  - LICENSE file (MIT)
  - CONTRIBUTING.md guidelines
  - Issue templates for GitHub
  - Pull request template
  - **Acceptance:** Professional open source project setup

#### 9.2. Release Preparation
- [ ] **Final testing checklist**
  - All acceptance criteria met
  - Performance benchmarks passed
  - No critical bugs
  - Testing on multiple macOS versions
  - **Acceptance:** Ready for public release

- [ ] **Release pipeline setup**
  - GitHub Actions for automated builds
  - Automated signing and notarization
  - ZIP packaging and upload to GitHub Releases
  - Version bumping and tagging automation
  - Example workflow: `git tag v1.0.0 && git push --tags` → automatic release
  - **Acceptance:** Push-to-release workflow creates downloadable ZIP

- [ ] **Community preparation**
  - Setup GitHub Discussions
  - Create issue labels and templates
  - Draft announcement for social media
  - Prepare project website/landing page
  - **Acceptance:** Ready for community engagement

## Success Metrics

- **Performance:** <5% CPU usage idle, <150MB memory
- **Accuracy:** Metrics within 2% of Activity Monitor
- **Reliability:** <0.1% crash rate
- **Responsiveness:** UI updates within polling intervals

## Architecture Overview

**Pattern:** MVVM + Services  
**Reactive:** Combine Publishers for data flow  
**Testing:** Protocol-based services for mockability  
**UI Framework:** SwiftUI with AppKit integration

## Development Guidelines

1. **Follow PRD specifications exactly**
2. **Test each service individually before integration**
3. **Use Instruments for performance validation**
4. **Implement error handling for all system APIs**
5. **Keep UI responsive with background processing**
6. **Validate with real hardware scenarios**

## Permissions

PulseBar requires minimal permissions to function:

- **Basic Metrics:** No permissions needed for CPU, memory, and storage
- **Wi-Fi Information:** Location permission may be required on newer macOS versions
- **Battery Details:** No additional permissions needed
- **Connected Devices:** No Full Disk Access required for basic device listing

The app is designed to work gracefully with limited permissions, showing clear instructions when additional access is needed.

## Contributing

This is an open source project welcoming contributions:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Next Steps

1. **Phase 1:** Complete project setup and GitHub repository
2. **Phase 2-3:** Implement core architecture and first metric (CPU)
3. **Phase 4:** Complete all system metric services
4. **Phase 5:** Full UI integration and polish
5. **Phases 6-9:** Testing, optimization, and automated release setup

Each phase should be completed and tested before moving to the next. Use this todo list to track progress and ensure all PRD requirements are met for successful open source distribution.