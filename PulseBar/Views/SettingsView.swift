//
//  SettingsView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @EnvironmentObject var themeManager: ThemeManager
    let onBack: () -> Void
    
    @State private var showingExportAlert = false
    @State private var showingImportDialog = false
    @State private var exportedText = ""
    @State private var importText = ""
    @State private var showingResetConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .themedFont(.primary, size: .regular)
                        }
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text("Settings")
                        .themedFont(.primary, size: .large)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Invisible placeholder for alignment
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.subheadline.weight(.medium))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Performance Section
                    settingsSection(
                        title: "Performance",
                        icon: "speedometer",
                        iconColor: .blue
                    ) {
                        settingRow(
                            title: "Refresh Rate",
                            icon: "arrow.clockwise",
                            iconColor: .blue
                        ) {
                            Picker("Refresh Rate", selection: $settingsManager.settings.refreshInterval) {
                                ForEach(RefreshInterval.allCases, id: \.self) { interval in
                                    Text(interval.displayName).tag(interval)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(minWidth: 120)
                        }
                        .onChange(of: settingsManager.settings.refreshInterval) { _ in
                            settingsManager.saveSettings()
                        }
                    }
                    
                    // Display Section
                    settingsSection(
                        title: "Display",
                        icon: "display",
                        iconColor: .purple
                    ) {
                        settingRow(
                            title: "Temperature Unit",
                            icon: "thermometer",
                            iconColor: .orange
                        ) {
                            Picker("Temperature", selection: $settingsManager.settings.temperatureUnit) {
                                ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(minWidth: 140)
                        }
                        .onChange(of: settingsManager.settings.temperatureUnit) { _ in
                            settingsManager.saveSettings()
                        }
                        
                        settingRow(
                            title: "Memory Unit",
                            icon: "memorychip",
                            iconColor: .green
                        ) {
                            Picker("Memory Unit", selection: $settingsManager.settings.memoryUnit) {
                                ForEach(MemoryUnit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(minWidth: 180)
                        }
                        .onChange(of: settingsManager.settings.memoryUnit) { _ in
                            settingsManager.saveSettings()
                        }
                    }
                    
                    // Theme Section
                    settingsSection(
                        title: "Appearance",
                        icon: "paintpalette.fill",
                        iconColor: .pink
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Current Theme:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(themeManager.currentTheme.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                            }
                            
                            // Quick theme selection
                            if themeManager.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading themes...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .frame(height: 30)
                            } else {
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(4, themeManager.builtInThemes.count)),
                                    spacing: 8
                                ) {
                                    ForEach(Array(themeManager.builtInThemes.prefix(4))) { theme in
                                        QuickThemeButton(
                                            theme: theme,
                                            isSelected: themeManager.currentTheme.id == theme.id
                                        ) {
                                            themeManager.applyTheme(theme)
                                        }
                                    }
                                }
                            }
                            
                            // Full theme picker button
                            Button("More Themes...") {
                                // This could open a sheet with the full ThemePicker
                            }
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                    }
                    
                    // System Section
                    settingsSection(
                        title: "System",
                        icon: "macbook",
                        iconColor: .gray
                    ) {
                        settingToggleRow(
                            title: "Launch at Login",
                            subtitle: "Start PulseBar when you log in",
                            icon: "power",
                            iconColor: .green,
                            isOn: $settingsManager.settings.launchAtLogin
                        ) {
                            settingsManager.toggleLaunchAtLogin()
                        }
                        
                        settingToggleRow(
                            title: "Show Dock Icon",
                            subtitle: "Display app icon in the dock",
                            icon: "dock.rectangle",
                            iconColor: .blue,
                            isOn: $settingsManager.settings.showDockIcon
                        ) {
                            settingsManager.settings.showDockIcon.toggle()
                            settingsManager.saveSettings()
                            updateDockIconVisibility()
                        }
                    }
                    
                    // Network Section
                    settingsSection(
                        title: "Network",
                        icon: "wifi",
                        iconColor: .blue
                    ) {
                        settingToggleRow(
                            title: "Auto Reset Daily Data",
                            subtitle: "Reset data usage counters at midnight",
                            icon: "clock",
                            iconColor: .orange,
                            isOn: $settingsManager.settings.autoResetDailyData
                        ) {
                            settingsManager.settings.autoResetDailyData.toggle()
                            settingsManager.saveSettings()
                        }
                    }
                    
                    // Notifications Section
                    settingsSection(
                        title: "Alerts",
                        icon: "bell",
                        iconColor: .red
                    ) {
                        settingToggleRow(
                            title: "Enable Notifications",
                            subtitle: "Show alerts for high resource usage",
                            icon: "bell.badge",
                            iconColor: .red,
                            isOn: $settingsManager.settings.enableNotifications
                        ) {
                            settingsManager.settings.enableNotifications.toggle()
                            settingsManager.saveSettings()
                        }
                        
                        if settingsManager.settings.enableNotifications {
                            settingSliderRow(
                                title: "CPU Warning Threshold",
                                icon: "cpu",
                                iconColor: .blue,
                                value: $settingsManager.settings.cpuWarningThreshold,
                                range: 0.5...0.95,
                                formatter: { String(format: "%.0f%%", $0 * 100) }
                            )
                            .onChange(of: settingsManager.settings.cpuWarningThreshold) { _ in
                                settingsManager.saveSettings()
                            }
                            
                            settingSliderRow(
                                title: "Memory Warning Threshold",
                                icon: "memorychip",
                                iconColor: .green,
                                value: $settingsManager.settings.memoryWarningThreshold,
                                range: 0.5...0.95,
                                formatter: { String(format: "%.0f%%", $0 * 100) }
                            )
                            .onChange(of: settingsManager.settings.memoryWarningThreshold) { _ in
                                settingsManager.saveSettings()
                            }
                        }
                    }
                    
                    // Data Section
                    settingsSection(
                        title: "Data Management",
                        icon: "externaldrive",
                        iconColor: .purple
                    ) {
                        settingButtonRow(
                            title: "Export Settings",
                            subtitle: "Save current settings to file",
                            icon: "square.and.arrow.up",
                            iconColor: .blue,
                            buttonTitle: "Export",
                            buttonColor: .blue
                        ) {
                            exportedText = settingsManager.exportSettings()
                            showingExportAlert = true
                        }
                        
                        settingButtonRow(
                            title: "Reset to Defaults",
                            subtitle: "Restore all settings to default values",
                            icon: "arrow.counterclockwise",
                            iconColor: .red,
                            buttonTitle: "Reset",
                            buttonColor: .red
                        ) {
                            showingResetConfirmation = true
                        }
                    }
                }
                .padding(16)
            }
        }
        .standardWindowFrame()
        .alert("Settings Exported", isPresented: $showingExportAlert) {
            Button("Copy to Clipboard") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(exportedText, forType: .string)
            }
            Button("Done", role: .cancel) { }
        } message: {
            Text("Settings have been exported as JSON. You can copy them to the clipboard.")
        }
        .alert("Reset Settings", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                settingsManager.resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore all settings to their default values. This action cannot be undone.")
        }
    }
    
    private func updateDockIconVisibility() {
        let policy: NSApplication.ActivationPolicy = settingsManager.settings.showDockIcon ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
    }
}

// MARK: - Settings Section Views
extension SettingsView {
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.themedLarge)
                
                Text(title)
                    .themedFont(.primary, size: .large)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 0) {
                content()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func settingRow<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.themedRegular)
                .frame(width: 20)
            
            Text(title)
                .themedFont(.primary, size: .regular)
                .foregroundColor(.primary)
            
            Spacer()
            
            control()
        }
        .padding(.vertical, 8)
    }
    
    private func settingToggleRow(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isOn: Binding<Bool>,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.subheadline)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle())
                .onChange(of: isOn.wrappedValue) { _ in
                    action()
                }
        }
        .padding(.vertical, 8)
    }
    
    private func settingSliderRow(
        title: String,
        icon: String,
        iconColor: Color,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        formatter: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.subheadline)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formatter(value.wrappedValue))
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            
            Slider(value: value, in: range)
                .tint(.accentColor)
        }
        .padding(.vertical, 8)
    }
    
    private func settingButtonRow(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        buttonTitle: String,
        buttonColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.subheadline)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(buttonColor)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Theme Button

struct QuickThemeButton: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: theme.colors.background))
                .frame(height: 30)
                .overlay(
                    VStack(spacing: 1) {
                        Circle()
                            .fill(Color(hex: theme.colors.accent))
                            .frame(width: 4, height: 4)
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: theme.colors.primaryText))
                            .frame(width: 12, height: 2)
                        
                        HStack(spacing: 1) {
                            Circle()
                                .fill(Color(hex: theme.colors.accent).opacity(0.6))
                                .frame(width: 2, height: 2)
                            
                            Circle()
                                .fill(Color(hex: theme.colors.cardBackground))
                                .frame(width: 2, height: 2)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(theme.name)
    }
}

#Preview {
    SettingsView(onBack: {})
        .environmentObject(ThemeManager.shared)
}