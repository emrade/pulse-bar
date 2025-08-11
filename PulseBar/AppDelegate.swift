//
//  AppDelegate.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private let themeManager = ThemeManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Configure the status item button
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "PulseBar")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // Create the popover
        popover = NSPopover()
        updatePopoverSize()
        popover?.behavior = .semitransient
        popover?.contentViewController = NSHostingController(
            rootView: DashboardView()
                .environmentObject(themeManager)
        )
        
        // Listen for theme changes to update popover size
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange(_:)),
            name: .themeDidChange,
            object: nil
        )
        
        // Hide the dock icon and main window
        NSApp.setActivationPolicy(.accessory)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                closePopover()
            } else {
                showPopover(relativeTo: button)
            }
        }
    }
    
    private func showPopover(relativeTo button: NSStatusBarButton) {
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        
        // Start monitoring for clicks outside the popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                // Check if click is outside the popover
                let clickLocation = event.locationInWindow
                if let popoverWindow = popover.contentViewController?.view.window {
                    let popoverFrame = popoverWindow.frame
                    let globalClickLocation = event.window?.convertPoint(toScreen: clickLocation) ?? clickLocation
                    
                    if !popoverFrame.contains(globalClickLocation) {
                        self?.closePopover()
                    }
                }
            }
        }
    }
    
    func closePopover() {
        popover?.performClose(nil)
        
        // Remove the event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    @objc private func themeDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updatePopoverSize()
        }
    }
    
    @MainActor
    private func updatePopoverSize() {
        let size = NSSize(
            width: themeManager.popover.width,
            height: themeManager.popover.height
        )
        popover?.contentSize = size
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}