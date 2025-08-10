# Simulated Data in Advanced Views

This document lists all the simulated or hardcoded data used in the advanced views of the PulseBar application.

## AdvancedBatteryView.swift

1. **Battery Health Simulation**:
   - In `batteryHealthColor` function: Simulated health based on cycle count
   - In `batteryCondition` function: Condition determined by simulated cycle count values

2. **Charging Time Estimation**:
   - In `estimatedChargeTime` function: Rough estimation using ~1.5% per minute

## AdvancedCPUView.swift

1. **CPU Usage History**:
   - In `cpuHistoryData` property: Simulated CPU usage history with random variations

2. **CPU Core Data**:
   - In `cpuCoreData` property: Simulated temperature and frequency values for each core

3. **CPU Information**:
   - In `cpuStatsSection`: 
     - Architecture: "Apple Silicon" (simulated)
     - Base Frequency: "3.2 GHz" (simulated)
     - Max Frequency: "3.8 GHz" (simulated)

## AdvancedDeviceView.swift

1. **Connected Devices**:
   - In `categorizedDevices` property: All device data is simulated including:
     - USB Devices: Magic Keyboard, Magic Mouse, External SSD, Webcam
     - Thunderbolt Devices: Studio Display, Audio Interface
     - Bluetooth Devices: AirPods Pro, iPhone

2. **System Information**:
   - In `systemInfoSection`:
     - USB Controller: "USB 3.2 Gen 2" (simulated)
     - Thunderbolt Version: "Thunderbolt 4" (simulated)
     - Bluetooth Version: "5.3" (simulated)
     - Available USB Ports: "2" (simulated)
     - Available TB Ports: "4" (simulated)
     - Power Delivery: "Supported" (simulated)

## AdvancedMemoryView.swift

1. **Memory Breakdown**:
   - In `memoryBreakdown` property: Simulated memory breakdown percentages:
     - App Memory: 60%
     - Wired Memory: 25%
     - Compressed Memory: 15%

2. **Memory Usage Categories**:
   - In `memoryUsageCategoriesSection`: Estimated percentages for memory usage categories:
     - App Memory: 60% estimate
     - Wired Memory: 25% estimate
     - Compressed: 15% estimate

3. **Swap Usage**:
   - In `memoryStatsSection`: "Swap Used": "0 bytes" (simulated)

## AdvancedNetworkUsageView.swift

1. **Peak Hour Calculation**:
   - In `getPeakHour()` function: Logic for determining peak usage hour

## AdvancedStorageView.swift

1. **Disk Health Status**:
   - **IMPLEMENTED**: Real SMART status using IOKit instead of simulated data based on usage percentage
   - IOKit.framework was already linked in the project

2. **Disk Temperature**:
   - **IMPLEMENTED**: Real temperature data from SMART when available, with fallback to simulated data
   - Uses actual SMART temperature attributes when accessible

## Preview Data

All advanced views use simulated data in their Preview sections for demonstration purposes:

1. **AdvancedBatteryView**: Battery metrics with 85% charge, charging status, etc.
2. **AdvancedCPUView**: CPU metrics with 45% overall usage, 8 core usage values
3. **AdvancedDeviceView**: Empty device metrics (no real devices)
4. **AdvancedMemoryView**: Memory metrics with 16GB total, 12GB used, etc.
5. **AdvancedNetworkUsageView**: Network usage metrics with 2.5GB downloaded, 500MB uploaded
6. **AdvancedNetworkView**: WiFi metrics with -45dBm signal strength
7. **AdvancedStorageView**: Disk metrics with 500GB total capacity, 150GB free space

## Implementation Details

### SMART Status (AdvancedStorageView)

The SMART status implementation has been completed using IOKit:

1. **IOKit Framework**: Already linked in the project
2. **Real SMART Data**: Access actual S.M.A.R.T. attributes from storage devices
3. **Implementation Details**:
   - Added SMARTStatus struct to hold SMART data including health, temperature, and other attributes
   - Extended VolumeInfo to include SMARTStatus
   - Implemented IOKit-based SMART data retrieval in DiskService
   - Updated AdvancedStorageView to display real SMART status and temperature
   - Added fallback to simulated data when SMART data is not available

### Features Implemented:
- Real SMART health status ("Verified", "Failing", "Unknown")
- Actual drive temperature from SMART data
- Fallback to simulated data when SMART is not available
- Proper error handling for external drives and inaccessible SMART data

## Remaining Simulated Data

Some of these simulated values are used as placeholders until real data can be fetched from system APIs, while others are estimations based on typical system behavior. The goal is to provide a realistic user interface even when actual data is not available or during development.

The SMART status implementation has been completed and is now using real data from IOKit instead of simulation.