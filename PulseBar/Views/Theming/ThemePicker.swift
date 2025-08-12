//
//  ThemePicker.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ThemePicker: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTheme: Theme
    @State private var showingFileImporter = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    let onClose: (() -> Void)?
    
    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
        _selectedTheme = State(initialValue: ThemeManager.shared.currentTheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme Selection")
                        .font(.title2.weight(.semibold))
                        .themedSurfaceText()
                    
                    Text("Choose a theme to customize PulseBar's appearance")
                        .font(.caption)
                        .themedSurfaceVariantText()
                }
                
                Spacer()
                
                if let onClose = onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .themedSurfaceVariantText()
                    }
                    .buttonStyle(.plain)
                    .help("Close")
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Built-in Themes
                    themeSection(
                        title: "Built-in Themes",
                        icon: "paintpalette.fill",
                        themes: themeManager.builtInThemes
                    )
                    
                    // Custom Themes (if any)
                    if !themeManager.customThemes.isEmpty {
                        themeSection(
                            title: "Custom Themes",
                            icon: "folder.fill",
                            themes: themeManager.customThemes
                        )
                    }
                }
                .padding(.bottom, 20)
            }
            
            Spacer()
            
            // Import and actions section
            VStack(spacing: 16) {
                Divider()
                
                HStack(spacing: 16) {
                    // Import Theme Button
                    Button(action: {
                        showingFileImporter = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14))
                            Text("Import Theme...")
                                .font(.subheadline.weight(.medium))
                        }
                        .themedHighContrastText()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Reset to Default Button
                    Button(action: {
                        themeManager.resetToDefault()
                        selectedTheme = themeManager.currentTheme
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("Reset")
                                .font(.caption.weight(.medium))
                        }
                        .themedSurfaceVariantText()
                    }
                    .buttonStyle(.plain)
                }
                
                // Loading indicator
                if themeManager.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading themes...")
                            .font(.caption)
                            .themedSurfaceVariantText()
                    }
                }
                
                // Error display
                if let error = themeManager.lastError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .themedSurfaceVariantText()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .themedSurface()
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Theme Import Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(themeManager.$currentTheme) { newTheme in
            selectedTheme = newTheme
        }
    }
    
    @ViewBuilder
    private func themeSection(title: String, icon: String, themes: [Theme]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .font(.headline)
                
                Text(title)
                    .font(.headline.weight(.semibold))
                    .themedSurfaceText()
                
                Text("(\(themes.count))")
                    .font(.caption)
                    .themedSurfaceVariantText()
            }
            
            // Theme grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
                spacing: 16
            ) {
                ForEach(themes) { theme in
                    ThemePreview(
                        theme: theme,
                        isSelected: selectedTheme.id == theme.id,
                        onSelect: {
                            selectTheme(theme)
                        }
                    )
                    .contextMenu {
                        if themeManager.customThemes.contains(where: { $0.id == theme.id }) {
                            Button("Export Theme...") {
                                exportTheme(theme)
                            }
                            
                            Button("Delete Theme", role: .destructive) {
                                deleteCustomTheme(theme)
                            }
                        }
                        
                        Button("Duplicate Theme") {
                            duplicateTheme(theme)
                        }
                    }
                }
            }
        }
    }
    
    private func selectTheme(_ theme: Theme) {
        selectedTheme = theme
        themeManager.applyTheme(theme)
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    try await themeManager.importCustomTheme(from: url)
                } catch let error as ThemeError {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showingErrorAlert = true
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to import theme: \(error.localizedDescription)"
                        showingErrorAlert = true
                    }
                }
            }
            
        case .failure(let error):
            errorMessage = "File import failed: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    private func exportTheme(_ theme: Theme) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "\(theme.name.lowercased().replacingOccurrences(of: " ", with: "-")).json"
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                do {
                    try themeManager.exportTheme(theme, to: url)
                } catch {
                    errorMessage = "Failed to export theme: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func deleteCustomTheme(_ theme: Theme) {
        Task {
            do {
                try await themeManager.deleteCustomTheme(theme)
            } catch let error as ThemeError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete theme: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func duplicateTheme(_ theme: Theme) {
        // Create a duplicate with modified ID and name
        let duplicatedTheme = Theme(
            id: "\(theme.id)-copy",
            name: "\(theme.name) Copy",
            description: "\(theme.description) (Copy)",
            version: theme.version,
            author: "User",
            popover: theme.popover,
            layout: theme.layout,
            colors: theme.colors,
            fonts: theme.fonts,
            icons: theme.icons,
            effects: theme.effects,
            components: theme.components
        )
        
        Task {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(duplicatedTheme)
                
                // Create a temporary file URL
                let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("\(duplicatedTheme.id).json")
                
                try data.write(to: tempURL)
                try await themeManager.importCustomTheme(from: tempURL)
                
                // Clean up temporary file
                try? FileManager.default.removeItem(at: tempURL)
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to duplicate theme: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ThemePicker(onClose: {})
        .environmentObject(ThemeManager.shared)
        .frame(width: 400, height: 600)
}