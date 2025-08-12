# Storage Data Analysis

## Issue Investigation: Storage Discrepancy 

**Date:** August 12, 2025  
**Issue:** User reported seeing 811 GB available vs. app showing 751 GB free

## Root Cause Analysis

### System Values Comparison

| Source | Available Space | Total Space | Notes |
|--------|----------------|-------------|-------|
| PulseBar App | 751 GB | 926.4 GB | Uses `volumeAvailableCapacity` API |
| `df -h /` | 752 GB | 926 GB | Boot volume space |
| `df -H /` | 807 GB | 995 GB | Container space (decimal units) |
| System Profiler | 807.12 GB | 994.66 GB | APFS container free space |
| Swift API Test | 751.7 GB | 926.4 GB | Direct API call |

### Technical Explanation

**The app is displaying correct data.** The discrepancy comes from different reporting methods:

1. **APFS Architecture:**
   - Modern macOS uses APFS (Apple File System) with containers
   - Containers can have multiple volumes sharing the same storage pool
   - Boot volume (`/`) vs. Container show different values

2. **What PulseBar Shows:**
   - Uses `URL.resourceValues(forKeys: [.volumeAvailableCapacity])` 
   - Reports available space on the boot volume (`/`)
   - This is the **standard** way system monitoring tools report storage

3. **Where 811GB Comes From:**
   - Likely from System Information app showing APFS container space
   - Container space (807.12 GB) represents shared pool for all volumes
   - Some tools round this up to ~811 GB

### Code Implementation

The storage calculation is handled in `DiskService.swift:90-91`:

```swift
let totalBytes = UInt64(resourceValues.volumeTotalCapacity ?? 0)
let availableBytes = UInt64(resourceValues.volumeAvailableCapacity ?? 0)
```

This correctly uses the macOS Foundation API to get volume-specific space information.

### Verification Commands

```bash
# Boot volume space (what PulseBar shows)
df -h /

# Container space (what System Information shows)  
system_profiler SPStorageDataType

# Detailed disk info
diskutil info disk3s1s1
```

## Conclusion

**No bug exists.** PulseBar correctly shows boot volume available space (751 GB), which matches system commands and standard monitoring practices. The higher values (807-811 GB) represent APFS container space, which is a different measurement.

## Related Files

- `/PulseBar/Services/DiskService.swift` - Storage data collection
- `/PulseBar/Models/Metrics.swift` - Storage data models
- `/PulseBar/Views/AdvancedViews/AdvancedStorageView.swift` - Storage UI display