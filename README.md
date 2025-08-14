# PulseBar 📊

**A lightweight, native macOS system monitor for your menu bar**

<div align="center">
  <img src="https://img.shields.io/badge/macOS-12.0%2B-blue?logo=apple&logoColor=white" alt="macOS 12.0+"/>
  <img src="https://img.shields.io/github/license/emrade/pulse-bar" alt="MIT License"/>
  <img src="https://img.shields.io/github/v/release/emrade/pulse-bar" alt="Latest Release"/>
  <img src="https://img.shields.io/badge/Swift-5.0-orange?logo=swift&logoColor=white" alt="Swift 5.0"/>
</div>

PulseBar brings essential system metrics directly to your macOS menu bar with a clean, efficient interface. Monitor CPU usage, memory consumption, disk space, battery status, network activity, and connected devices—all in real-time with minimal resource overhead.

## ✨ Features

### 📈 Real-Time System Monitoring
- **CPU Usage**: Per-core and overall CPU utilization
- **Memory**: RAM usage with available/used breakdown  
- **Storage**: Disk space for all mounted volumes
- **Battery**: Charge level, power source, and time remaining
- **Network**: WiFi/Ethernet status with speed testing
- **Devices**: Connected USB devices and mounted drives

### 🎨 Beautiful Themes
- **5+ Built-in Themes**: Basic, Light, Futuristic, Colorful, Nature Glow
- **Custom Fonts**: Each theme uses carefully selected typography
- **Adaptive Colors**: High contrast text for perfect readability
- **Smooth Animations**: Polished transitions and hover effects

### ⚡ Performance First
- **<5% CPU usage** while running
- **<150MB memory footprint**
- **Efficient polling** with smart intervals
- **Native SwiftUI** for smooth performance

### 🔒 Privacy Focused
- **Local monitoring only** - no data collection
- **Minimal permissions** required
- **Sandbox compatible** for security
- **Open source** - audit the code yourself

## 🚀 Installation

### Quick Install

1. **[Download PulseBar-v1.0.0.zip](https://github.com/emrade/pulse-bar/releases/latest)**
2. **Extract** the ZIP file by double-clicking it
3. **Drag PulseBar.app** to your Applications folder
4. **Launch** PulseBar from Applications or Spotlight

### First Launch Security Warning ⚠️

**Important**: Since PulseBar is distributed outside the App Store, macOS will show a security warning. This is normal for open source apps that aren't notarized by Apple.

**If you see "Apple could not verify PulseBar.app is free of malware" or only "Done/Move to Trash" options:**

**Method 1 (Most Reliable):**
1. Try to open the app normally (it will be blocked)
2. Click **"Done"** (don't move to trash)
3. Go to **System Settings → Privacy & Security → Security** (or **System Preferences → Security & Privacy → General** on older macOS)
4. Look for a message about PulseBar being blocked 
5. Click **"Open Anyway"** button next to the PulseBar warning
6. Confirm by clicking **"Open"** in the new dialog

**Method 2 (Right-click):**
1. **Right-click** on `PulseBar.app` → Select **"Open"**
2. Click **"Open"** in the security dialog (if this option appears)
3. The app will launch and be trusted for future use

**Method 3 (Advanced - Terminal):**
If neither method works, you can remove the quarantine flag:
```bash
# Navigate to Applications folder
cd /Applications

# Remove quarantine flag
sudo xattr -rd com.apple.quarantine PulseBar.app

# Open the app
open PulseBar.app
```

**After successful launch:**
- Grant permissions when prompted:
  - Location access (for WiFi network names)
  - Network access (for speed tests)

The app will appear in your menu bar with a waveform icon 📊.

## 🖱️ Usage

- **Left-click** the menu bar icon to open the system dashboard
- **Right-click** for quick actions and settings
- **Hover** over metrics for detailed information
- **Click "Test Speed"** to measure network performance
- **Access Settings** to customize polling intervals and appearance

### 🎯 Key Metrics Explained

| Metric | What It Shows | Update Frequency |
|--------|---------------|------------------|
| **CPU** | Current processor usage across all cores | 1.5 seconds |
| **Memory** | Physical RAM usage (used • available) | 2 seconds |
| **Storage** | Disk space for boot and external drives | 10 seconds |
| **Battery** | Charge level, power source, time remaining | 10 seconds |
| **Network** | Connection type, WiFi signal, data usage | 5 seconds |
| **Devices** | Connected USB devices and volumes | 10 seconds |

## ⚙️ Configuration

Access **Settings** from the dashboard to customize:

- **Refresh rates** for each metric type
- **Temperature units** (Celsius/Fahrenheit)
- **Memory units** (GB/GiB)
- **Launch at login**
- **Dock icon visibility**
- **Daily data usage reset**
- **Alert thresholds** for high resource usage

## 🎨 Themes

PulseBar includes 5 carefully crafted themes:

- **Basic**: Clean system fonts with macOS native styling
- **Light**: Minimal light theme with high contrast
- **Futuristic**: Orbitron + Rajdhani for a sci-fi aesthetic  
- **Colorful**: Baloo 2 + Nunito Sans with vibrant accents
- **Nature Glow**: Merriweather Sans + Lato with earthy tones

Switch themes instantly from the Settings page.

## 🛠️ System Requirements

- **macOS 12.0** or later (Monterey, Ventura, Sonoma, Sequoia)
- **Apple Silicon** (M1/M2/M3/M4) or Intel Mac
- **~10MB** disk space
- **Network connection** for speed testing (optional)

## 🔧 Troubleshooting

### App Won't Open / Security Warning
- **"Cannot verify PulseBar.app is free of malware"**: This is normal for open source apps
- **Solution**: Try to open normally, click "Done", then go to **System Settings → Privacy & Security → Security** 
- **Look for**: "Open Anyway" button next to PulseBar warning
- **Alternative**: **Right-click → Open** (may not always work)
- **Still blocked?**: Ensure you're running **macOS 12.0+** and try restarting your Mac

### Missing Data
- Grant **Location permission** for WiFi network names
- Allow **Network access** for internet speed tests
- Check **System Preferences → Privacy** settings

### Performance Issues
- Increase **polling intervals** in Settings for slower systems
- Disable **unused metrics** to reduce resource usage
- Restart PulseBar if memory usage seems high

## 🚧 Development

Want to contribute or build from source?

```bash
# Clone the repository
git clone https://github.com/emrade/pulse-bar.git
cd pulse-bar

# Open in Xcode
open PulseBar.xcodeproj

# Build and run (⌘R)
```

### Architecture
- **SwiftUI** for modern, declarative UI
- **Combine** for reactive data flow
- **MVVM pattern** for clean separation
- **Protocol-based services** for testability

## 📝 License

PulseBar is open source software licensed under the [MIT License](LICENSE).

## 🙋‍♂️ Support

- **🐛 Bug Reports**: [Create an Issue](https://github.com/emrade/pulse-bar/issues)
- **💡 Feature Requests**: [Start a Discussion](https://github.com/emrade/pulse-bar/discussions)
- **📖 Documentation**: Check the [Wiki](https://github.com/emrade/pulse-bar/wiki)

---

<div align="center">
  <strong>Made with ❤️ for the macOS community</strong><br/>
  <em>PulseBar - System monitoring, simplified.</em>
</div>