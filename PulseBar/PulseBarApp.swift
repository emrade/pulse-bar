//
//  PulseBarApp.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import SwiftUI

@main
struct PulseBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView(onBack: {
                // Close settings window when back is pressed
                NSApplication.shared.keyWindow?.close()
            })
        }
    }
}
