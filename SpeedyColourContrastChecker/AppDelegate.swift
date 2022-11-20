//
//  AppDelegate.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 02/09/2022.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let colourPickerWindow = NSWindow(contentRect: NSMakeRect(0, 0, 50, 50), styleMask: .borderless, backing: .buffered, defer: false)
    let mouseTrapWindow = NSWindow(contentRect: NSMakeRect(0, 0, 0, 0), styleMask: .borderless, backing: .buffered, defer: false)
    let pixelConverterWindow = NSWindow(contentRect: NSMakeRect(0, 0, 0, 0), styleMask: .borderless, backing: .buffered, defer: false)
    var tutorialWindow: NSWindow? = nil
    
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var mainUI: Main? = nil
    var tutorialUI: Tutorial? = nil
    var mouseTrapUI: MouseTrap? = nil
    var mouseMoveMonitor: Any?
    var mouseClickMonitor: Any?
    var appModel = AppModel()
    
    func showWelcomeTutorial() {
        tutorialUI = Tutorial(appModel: appModel)
        tutorialWindow = NSWindow(contentRect: NSMakeRect(200, 200, 800, 500), styleMask: [.closable, .titled, .resizable], backing: .buffered, defer: false)
        if let window = tutorialWindow {
            
            window.contentView?.wantsLayer = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .visible
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.makeKeyAndOrderFront(tutorialWindow)
            window.level = .floating
            window.contentViewController = NSHostingController(rootView: tutorialUI)
        }
    }
    
    func hideTutorial() {
        tutorialWindow?.close()
    }
   
    func triggerSystemPermissionDialog() {
        CGDisplayCreateImage(NSScreen.main?.displayID ?? 0, rect: NSRect(x: 50, y: 50, width: 1, height: 1))
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mainUI = Main(appModel: appModel)
        mouseTrapUI = MouseTrap(appModel: appModel)
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        colourPickerWindow.level = .floating
        colourPickerWindow.alphaValue = 0
        
        mouseTrapWindow.contentView?.wantsLayer = true
        mouseTrapWindow.level = .floating
        mouseTrapWindow.backgroundColor = NSColor.clear
        mouseTrapWindow.contentView?.layer?.cornerRadius = 25
        mouseTrapWindow.contentView?.layer?.masksToBounds = true
        mouseTrapWindow.makeKeyAndOrderFront(mouseTrapWindow)
        
        mouseTrapWindow.contentViewController = NSHostingController(rootView: mouseTrapUI)
        
        
        // Create a popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 300)
        popover.behavior = .applicationDefined
        // Embed our SwiftUI view into the popover
        popover.contentViewController = NSHostingController(rootView: mainUI)
        // Register it
        self.popover = popover
        self.popover.contentViewController?.view.window?.becomeKey()
        
        if let button = statusBarItem.button {
            // Set menubar icon
            button.image = NSImage(systemSymbolName: "eyedropper.halffull", accessibilityDescription: "Speedy Colour Contrast Picker")
            // Re-arrange status bar icon position
            button.imagePosition = NSControl.ImagePosition.imageOnly
            // Set font
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12.0, weight: NSFont.Weight.light)
            // Register click action
            // See Functions file
            button.action = #selector(togglePopover(_:))
            // Dispatch click states
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        if(!appModel.isFirstWelcomeDone()) {
            showWelcomeTutorial()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    
}

