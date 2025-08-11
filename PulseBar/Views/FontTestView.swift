//
//  FontTestView.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 11/08/2025.
//

import SwiftUI

struct FontTestView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Font Loading Test")
                .font(.title)
                .padding(.bottom, 8)
            
            Group {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Primary Font (Themed)")
                        .themedFont(.primary, size: .regular)
                        .themedSecondaryText()
                    
                    Text("This is the primary font for the current theme")
                        .themedFont(.primary, size: .large)
                        .themedPrimaryText()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accent Font (Themed)")
                        .themedFont(.accent, size: .regular)
                        .themedSecondaryText()
                    
                    Text("This is the accent font for titles and headers")
                        .themedFont(.accent, size: .large)
                        .themedPrimaryText()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monospace Font (Themed)")
                        .themedFont(.monospace, size: .regular)
                        .themedSecondaryText()
                    
                    Text("This is monospace: 1234567890")
                        .themedFont(.monospace, size: .regular)
                        .themedPrimaryText()
                }
            }
            
            Divider()
            
            // Direct font tests
            Group {
                Text("Direct Font Tests:")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("Rajdhani Font")
                    .font(.custom("Rajdhani", size: 16))
                
                Text("Orbitron Font")
                    .font(.custom("Orbitron", size: 16))
                
                Text("Nunito Sans Font")
                    .font(.custom("Nunito Sans", size: 16))
                
                Text("Baloo 2 Font")
                    .font(.custom("Baloo 2", size: 16))
                
                Text("Lato Font")
                    .font(.custom("Lato", size: 16))
                
                Text("Merriweather Sans Font")
                    .font(.custom("Merriweather Sans", size: 16))
            }
            
            Divider()
            
            // Font debugging info
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug Info:")
                    .font(.caption.weight(.semibold))
                
                Text("Current Theme: \(themeManager.currentTheme.name)")
                    .font(.caption)
                
                Text("Primary Font: \(themeManager.fonts.primary.family)")
                    .font(.caption)
                
                if let accentFont = themeManager.fonts.accent {
                    Text("Accent Font: \(accentFont.family)")
                        .font(.caption)
                } else {
                    Text("Accent Font: None (using primary)")
                        .font(.caption)
                }
                
                Text("Loaded Fonts: \(FontLoader.shared.loadedBundledFonts.count)")
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 600)
        .themedBackground()
    }
}

#Preview {
    FontTestView()
        .environmentObject(ThemeManager.shared)
}