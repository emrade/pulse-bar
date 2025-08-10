//
//  AppDelegate.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 09/08/2025.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    
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
        popover?.contentSize = NSSize(width: 360, height: 700)
        popover?.behavior = .semitransient
        popover?.contentViewController = NSHostingController(rootView: DashboardView())
        
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
}