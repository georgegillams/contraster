//
//  AppDelegate+Functions.swift
//  Contraster
//
//  Created by George Gillams on 02/09/2022.
//

import Cocoa
import SwiftUI
import CoreImage

extension AppDelegate {

    @objc func openAbout() {
        AboutWindowController.createWindow()
    }

    @objc func viewOnboarding() {
        showWelcomeTutorial()
    }

    @objc func openMenu() {
        let versionNsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject
        let version = versionNsObject as! String
        let menu = NSMenu()
        menu.addItem(withTitle: "About Contraster", action: #selector(openAbout), keyEquivalent: "")
        menu.addItem(withTitle: "Show tutorial", action: #selector(viewOnboarding), keyEquivalent: "")
        menu.addItem(withTitle: "Send me feedback", action: #selector(openFeedback), keyEquivalent: "")
        // menu.addItem(withTitle: "Buy me a coffee", action: #selector(openCoffee), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Contraster \(version)", action: nil, keyEquivalent: ""))
        menu.addItem(withTitle: "Quit Contraster", action: #selector(quit), keyEquivalent: "q")

        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
        statusBarItem.menu = nil
    }

    @objc func openFeedback() {
        if let url = URL(string: "https://www.georgegillams.co.uk/contraster-feedback") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func openCoffee() {
        if let url = URL(string: "https://www.georgegillams.co.uk/coffee") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func quit() {
        NSApp.terminate(self)
    }

    @objc func updateMouseTrapWindow() {
        if (self.appModel.pickingMode == .notPicking) {
            // Defer cleanup to next run loop to avoid removing monitors while they're executing
            DispatchQueue.main.async {
                self.removeMouseAndKeyboardObservers()
                self.mouseTrapWindow.setFrame(NSRect(x: 0, y: 0, width: 0, height: 0), display: true, animate: false)
            }
        } else {
            addMouseAndKeyboardObservers()
        }
    }

    func removeMouseAndKeyboardObservers() {
        if(mouseMoveMonitor != nil) {
            NSEvent.removeMonitor(mouseMoveMonitor!)
            mouseMoveMonitor = nil
        }
        if(mouseClickMonitor != nil) {
            NSEvent.removeMonitor(mouseClickMonitor!)
            mouseClickMonitor = nil
        }
        if(keyMonitor != nil) {
            NSEvent.removeMonitor(keyMonitor!)
            keyMonitor = nil
        }
        cleanupScreenshot()
    }
    
    func captureScreenshot() {
        // Capture screenshots for all screens
        capturedScreenshots = [:]
        screenshotScreenFrames = [:]
        
        for screen in NSScreen.screens {
            let displayID = screen.displayID
            let screenFrame = screen.frame
            
            // Capture the entire screen
            if let imageRef = CGDisplayCreateImage(displayID) {
                let screenshot = NSImage(cgImage: imageRef, size: screenFrame.size)
                capturedScreenshots[screen] = screenshot
                screenshotScreenFrames[screen] = screenFrame
            }
        }
        
        // Show overlay window with screenshot
        showScreenshotOverlay()
    }
    
    func showScreenshotOverlay() {
        // Clean up existing overlay if any
        if screenshotOverlayWindow != nil {
            screenshotOverlayWindow?.close()
            screenshotOverlayWindow = nil
        }
        
        // Find the screen with the mouse to position the overlay
        guard let currentScreen = ScreenHelper.getScreenWithMouse(),
              let screenshot = capturedScreenshots[currentScreen] else { return }
        
        let screenFrame = currentScreen.frame
        
        // Create overlay window
        screenshotOverlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        guard let overlayWindow = screenshotOverlayWindow else { return }
        
        overlayWindow.level = .normal - 1 // Below normal windows but above desktop
        //  overlayWindow.level = .screenSaver // On top of all other windows
        overlayWindow.backgroundColor = NSColor.clear
        overlayWindow.isOpaque = false
        overlayWindow.ignoresMouseEvents = true // Allow clicks to pass through
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
//        overlayWindow.canBecomeKey = false
//        overlayWindow.canBecomeMain = false
        
        // Create image view with screenshot
        let imageView = NSImageView(frame: NSRect(origin: .zero, size: screenFrame.size))
        
        // Apply green tint for debugging
        if let cgImage = screenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let ciImage = CIImage(cgImage: cgImage)
            let filter = CIFilter(name: "CIColorMatrix")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(CIVector(x: 0.9, y: 1.0, z: 0.9, w: 0), forKey: "inputRVector") // Reduce red slightly
            filter?.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector") // Keep green
            filter?.setValue(CIVector(x: 0.9, y: 1.0, z: 0.9, w: 0), forKey: "inputBVector") // Reduce blue slightly
            filter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector") // Keep alpha
            filter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
            
            if let outputImage = filter?.outputImage {
                let context = CIContext()
                if let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    imageView.image = NSImage(cgImage: outputCGImage, size: screenFrame.size)
                } else {
                    imageView.image = screenshot
                }
            } else {
                imageView.image = screenshot
            }
        } else {
            imageView.image = screenshot
        }
        
        imageView.imageScaling = .scaleAxesIndependently
        
        overlayWindow.contentView = imageView
        overlayWindow.setFrame(screenFrame, display: true)
        overlayWindow.makeKeyAndOrderFront(nil)
    }
    
    func cleanupScreenshot() {
        screenshotOverlayWindow?.close()
        screenshotOverlayWindow = nil
        capturedScreenshots = [:]
        screenshotScreenFrames = [:]
        appModel.currentScreenshot = nil
        appModel.currentScreenFrame = .zero
        appModel.currentMouseLocation = .zero
    }
    
    func getColorFromScreenshot(at screenPoint: NSPoint) -> NSColor? {
        guard let currentScreen = ScreenHelper.getScreenWithMouse(),
              let screenshot = capturedScreenshots[currentScreen],
              let screenFrame = screenshotScreenFrames[currentScreen] ?? Optional(currentScreen.frame) else {
            return nil
        }
        // print("getColorFromScreenshot: \(screenPoint)")
        // print("screenshot: \(screenshot)")
        // print("screenFrame: \(screenFrame)")
        // print("currentScreen: \(currentScreen)")
        // print("capturedScreenshots: \(capturedScreenshots)")
        // print("screenshotScreenFrames: \(screenshotScreenFrames)")

        // Convert screen point to image coordinates
        // Screen coordinates have origin at bottom-left, but image coordinates have origin at top-left
        let imageSize = screenshot.size
        let screenHeight = screenFrame.height
        
        // Calculate point relative to screen
        let relativeX = screenPoint.x - screenFrame.origin.x
        let relativeY = screenPoint.y - screenFrame.origin.y
        
        // Invert Y coordinate for image (screen Y is bottom-up, image Y is top-down)
        let imageY = screenHeight - relativeY
        
        // Convert to image coordinates (accounting for image size vs screen size)
        let imagePointX = (relativeX / screenFrame.width) * imageSize.width
        let imagePointY = (imageY / screenFrame.height) * imageSize.height
        
        // Ensure coordinates are within bounds
        guard imagePointX >= 0 && imagePointX < imageSize.width &&
              imagePointY >= 0 && imagePointY < imageSize.height else {
            return nil
        }
        
        // Get color from image at this point
        guard let cgImage = screenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        // Create a bitmap representation
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let color = bitmapRep.colorAt(x: Int(imagePointX), y: Int(imagePointY))
        
        return color
    }

    func addMouseAndKeyboardObservers() {
        if(mouseMoveMonitor != nil && mouseClickMonitor != nil && keyMonitor != nil) {
            // all monitors already exist, so nothing to do
            return
        } else if (mouseMoveMonitor == nil || mouseClickMonitor == nil || keyMonitor == nil) {
            // one of the monitors is nil, so we'll reset them all
            removeMouseAndKeyboardObservers()
        }

        // Capture screenshot when picking starts
        captureScreenshot()

        mouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
            // This shouldn't actually happen, as the monitor should be inactive when not picking.
            if (self.appModel.pickingMode == .notPicking) {
                return $0
            }

            var mouseLocation: NSPoint { NSEvent.mouseLocation }
            
            // Update mouse location and screenshot in AppModel
            self.appModel.currentMouseLocation = mouseLocation
            if let currentScreen = ScreenHelper.getScreenWithMouse(),
               let screenshot = self.capturedScreenshots[currentScreen] {
                self.appModel.currentScreenshot = screenshot
                self.appModel.currentScreenFrame = self.screenshotScreenFrames[currentScreen] ?? currentScreen.frame
            }

            // Update window size to accommodate magnification region (300x200) plus circles
            let windowWidth = max(InterfaceConstants.magnificationWidth, InterfaceConstants.mouseTrapRectSize.width)
            let windowHeight = max(InterfaceConstants.magnificationHeight, InterfaceConstants.mouseTrapRectSize.height)
            
            // Position window so that circles are at mouse cursor, with magnification above
            // The circles are at the bottom of the VStack (50px high), so center them on mouse
            // Window y coordinate is bottom-left, so position bottom at mouseY - circleHeight/2
            let circleHeight = InterfaceConstants.mouseTrapRectSize.height
            let mouseTrapFrame = NSRect(
                x: mouseLocation.x - windowWidth/2,
                y: mouseLocation.y - windowHeight/2,
                width: windowWidth,
                height: windowHeight
            )
            self.mouseTrapWindow.setFrame(mouseTrapFrame, display: true, animate: false)

            // Read color from screenshot instead of live screen
            // We read the pixel that is 2 pixels to the left of the mouse cursor to avoid reading the MouseTrap UI
            let colorPickingPoint = NSPoint(x: mouseLocation.x, y: mouseLocation.y)
            
            guard let nsColor = self.getColorFromScreenshot(at: colorPickingPoint) else {
                return $0
            }
            
            let cgColor = nsColor.cgColor
            
            if(self.appModel.pickingMode == .pickingFirstColor) {
                self.appModel.updateFirstColor(color: Color(cgColor: cgColor))
            } else if (self.appModel.pickingMode == .pickingSecondColor) {
                self.appModel.updateSecondColor(color: Color(cgColor: cgColor))
            }
            return $0
        }


        mouseClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { event in
            // This shouldn't actually happen, as the monitor should be inactive when not picking.
            if (self.appModel.pickingMode == .notPicking) {
                return event
            }
            if(event.type == .leftMouseUp) {
                return event
            }

            if(self.appModel.pickingMode == .pickingFirstColor) {
                self.appModel.captureFirstColor()
            } else if(self.appModel.pickingMode == .pickingSecondColor) {
                self.appModel.captureSecondColor()
            }

            // Defer window update to avoid removing monitors while handler is executing
            DispatchQueue.main.async {
                self.updateMouseTrapWindow()
            }

            return event
        }
        
        // Add ESC key monitor to cancel picking
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if (self.appModel.pickingMode == .notPicking) {
                return event
            }
            
            // Check if ESC key was pressed
            if event.keyCode == 53 { // ESC key code
                self.appModel.cancelPick()
                // Defer window update to avoid removing monitors while handler is executing
                DispatchQueue.main.async {
                    self.updateMouseTrapWindow()
                }
                return nil // Consume the event
            }
            
            return event
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        let event = NSApp.currentEvent!

        if event.type == NSEvent.EventType.leftMouseUp {

            if let sbutton = statusBarItem.button {

                // find the coordinates of the statusBarItem in screen space
                let buttonRect: NSRect = sbutton.convert(sbutton.bounds, to: nil)
                let screenRect: NSRect = sbutton.window!.convertToScreen(buttonRect)

                // calculate the bottom center position (10 is the half of the window width)
                let posX = screenRect.origin.x + (screenRect.width / 2) - 10
                let posY = screenRect.origin.y

                colourPickerWindow.setFrame(NSRect(x: posX, y: posY, width: 20, height: 5), display: true,animate: false)
                updateMouseTrapWindow()

                if popover.isShown {
                    popover.performClose(sender)
                    self.appModel.cancelPick()
                    updateMouseTrapWindow()
                } else {
                    colourPickerWindow.makeKeyAndOrderFront(self)
                    NSApplication.shared.presentationOptions = []
                    NSApp.activate(ignoringOtherApps: true)
                    popover.show(relativeTo: colourPickerWindow.contentView!.frame, of: colourPickerWindow.contentView!, preferredEdge: NSRectEdge.minY)
                }
            }
        } else if event.type == NSEvent.EventType.rightMouseUp {
            openMenu()
        }
    }
}
