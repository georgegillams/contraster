//
//  AppDelegate+Functions.swift
//  Contraster
//
//  Created by George Gillams on 02/09/2022.
//

import Cocoa
import SwiftUI
import CoreImage
import ScreenCaptureKit

extension AppDelegate {

    private func debugPickingModeLabel(_ mode: PickingMode) -> String {
        switch mode {
        case .notPicking: return "notPicking"
        case .pickingFirstColor: return "pickingFirstColor"
        case .pickingSecondColor: return "pickingSecondColor"
        }
    }

    func configureMouseTrapWindow() {
        mouseTrapWindow.level = .screenSaver
        mouseTrapWindow.backgroundColor = NSColor.clear
        mouseTrapWindow.contentView?.wantsLayer = true
        mouseTrapWindow.contentView?.layer?.cornerRadius = 8
        mouseTrapWindow.contentView?.layer?.masksToBounds = true
        disableImplicitWindowAnimations(mouseTrapWindow)
        mouseTrapWindow.orderOut(nil)
    }

    private func disableImplicitWindowAnimations(_ window: NSWindow) {
        window.contentView?.layer?.actions = [
            "bounds": NSNull(),
            "position": NSNull(),
            "frame": NSNull(),
            "onOrderIn": NSNull(),
            "onOrderOut": NSNull(),
        ]
    }

    private func positionMouseTrapWindow(_ frame: NSRect) {
        guard appModel.pickingMode != .notPicking else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            mouseTrapWindow.setFrame(frame, display: true)
        }

        if !mouseTrapWindow.isVisible {
            mouseTrapWindow.orderFrontRegardless()
        }
    }

    private func hideMouseTrapWindow() {
        gDebugPrint("hideMouseTrapWindow")
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
        }
        mouseTrapWindow.orderOut(nil)
    }

    private func dismissScreenshotOverlayWindow() {
        guard screenshotOverlayWindow != nil else { return }
        gDebugPrint("dismissScreenshotOverlayWindow")
        screenshotOverlayWindow?.orderOut(nil)
        screenshotOverlayWindow?.contentView = nil
        screenshotOverlayWindow = nil
    }

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
        gDebugPrint("updateMouseTrapWindow: mode=\(debugPickingModeLabel(appModel.pickingMode))")
        if (self.appModel.pickingMode == .notPicking) {
            // Defer cleanup to next run loop to avoid removing monitors while they're executing
            DispatchQueue.main.async {
                self.removeMouseAndKeyboardObservers()
                self.hideMouseTrapWindow()
            }
        } else {
            addMouseAndKeyboardObservers()
        }
    }

    func removeMouseAndKeyboardObservers() {
        gDebugPrint("removeMouseAndKeyboardObservers")
        let moveMonitor = mouseMoveMonitor
        let clickMonitor = mouseClickMonitor
        let escMonitor = keyMonitor
        mouseMoveMonitor = nil
        mouseClickMonitor = nil
        keyMonitor = nil

        if let moveMonitor {
            NSEvent.removeMonitor(moveMonitor)
        }
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
        }
        if let escMonitor {
            NSEvent.removeMonitor(escMonitor)
        }
        cleanupScreenshot()
    }
    
    func captureScreenshot() {
        screenshotCaptureGeneration += 1
        let generation = screenshotCaptureGeneration

        gDebugPrint("captureScreenshot: generation=\(generation) screenRecordingPermission=\(hasScreenRecordingPermissions())")
        captureScreenshotsSynchronously()
        gDebugPrint("captureScreenshot: synchronous capture stored \(capturedScreenshots.count) screen(s)")
        showScreenshotOverlay()

        if !hasScreenRecordingPermissions() {
            gDebugPrint("captureScreenshot: requesting screen recording permission")
            triggerSystemPermissionDialog()
        } else if #available(macOS 14.0, *) {
            gDebugPrint("captureScreenshot: refreshing screenshots via ScreenCaptureKit")
            Task { @MainActor in
                guard generation == self.screenshotCaptureGeneration else {
                    gDebugPrint("captureScreenshot: skipping stale ScreenCaptureKit refresh (generation \(generation))")
                    return
                }
                guard self.appModel.pickingMode != .notPicking else {
                    gDebugPrint("captureScreenshot: skipping ScreenCaptureKit refresh because picking ended")
                    return
                }
                await self.captureScreenshotsWithScreenCaptureKit(generation: generation)
                guard generation == self.screenshotCaptureGeneration else { return }
                guard self.appModel.pickingMode != .notPicking else { return }
                gDebugPrint("captureScreenshot: ScreenCaptureKit refresh stored \(self.capturedScreenshots.count) screen(s)")
                self.showScreenshotOverlay()
            }
        }
    }

    private func captureScreenshotsSynchronously() {
        capturedScreenshots = [:]
        screenshotScreenFrames = [:]

        for screen in NSScreen.screens {
            let screenFrame = screen.frame
            if let imageRef = CGDisplayCreateImage(screen.displayID) {
                let screenshot = NSImage(cgImage: imageRef, size: screenFrame.size)
                capturedScreenshots[screen.displayID] = screenshot
                screenshotScreenFrames[screen.displayID] = screenFrame
                gDebugPrint("captureScreenshotsSynchronously: displayID=\(screen.displayID) size=\(screenFrame.size) pixels=\(imageRef.width)x\(imageRef.height)")
            } else {
                gDebugPrint("captureScreenshotsSynchronously: CGDisplayCreateImage failed for displayID=\(screen.displayID)")
            }
        }
    }

    @available(macOS 14.0, *)
    private func captureScreenshotsWithScreenCaptureKit(generation: Int) async {
        guard generation == screenshotCaptureGeneration else { return }

        var refreshedScreenshots: [CGDirectDisplayID: NSImage] = [:]
        var refreshedScreenFrames: [CGDirectDisplayID: NSRect] = [:]

        for screen in NSScreen.screens {
            let screenFrame = screen.frame

            do {
                let imageRef = try await captureDisplayImage(for: screen, frame: screenFrame)
                guard generation == screenshotCaptureGeneration else { return }
                let screenshot = NSImage(cgImage: imageRef, size: screenFrame.size)
                refreshedScreenshots[screen.displayID] = screenshot
                refreshedScreenFrames[screen.displayID] = screenFrame
                gDebugPrint("captureScreenshotsWithScreenCaptureKit: displayID=\(screen.displayID) size=\(screenFrame.size) pixels=\(imageRef.width)x\(imageRef.height)")
            } catch {
                gDebugPrint("captureScreenshotsWithScreenCaptureKit: ScreenCaptureKit failed for displayID=\(screen.displayID): \(error.localizedDescription)")
                if let imageRef = CGDisplayCreateImage(screen.displayID) {
                    let screenshot = NSImage(cgImage: imageRef, size: screenFrame.size)
                    refreshedScreenshots[screen.displayID] = screenshot
                    refreshedScreenFrames[screen.displayID] = screenFrame
                    gDebugPrint("captureScreenshotsWithScreenCaptureKit: fallback CGDisplayCreateImage succeeded for displayID=\(screen.displayID)")
                } else {
                    gDebugPrint("captureScreenshotsWithScreenCaptureKit: fallback CGDisplayCreateImage failed for displayID=\(screen.displayID)")
                }
            }
        }

        guard generation == screenshotCaptureGeneration else { return }
        capturedScreenshots = refreshedScreenshots
        screenshotScreenFrames = refreshedScreenFrames
    }

    @available(macOS 14.0, *)
    private func captureDisplayImage(for screen: NSScreen, frame: NSRect) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == screen.displayID }) else {
            throw NSError(domain: "Contraster", code: 1, userInfo: [NSLocalizedDescriptionKey: "Display not found"])
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        let scale = screen.backingScaleFactor
        config.width = Int(frame.width * scale)
        config.height = Int(frame.height * scale)
        config.showsCursor = false

        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }
    
    func showScreenshotOverlay() {
        dismissScreenshotOverlayWindow()
        
        // Find the screen with the mouse to position the overlay
        guard let currentScreen = ScreenHelper.getScreenWithMouse(),
              let screenshot = capturedScreenshots[currentScreen.displayID] else {
            gDebugPrint("showScreenshotOverlay: no screenshot for current screen (capturedScreenshots.count=\(capturedScreenshots.count))")
            return
        }
        
        let screenFrame = screenshotScreenFrames[currentScreen.displayID] ?? currentScreen.frame
        
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
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            overlayWindow.setFrame(screenFrame, display: true)
        }
        overlayWindow.orderFront(nil)
        gDebugPrint("showScreenshotOverlay: overlay shown for screen frame=\(screenFrame)")
    }
    
    func cleanupScreenshot() {
        gDebugPrint("cleanupScreenshot")
        screenshotCaptureGeneration += 1
        dismissScreenshotOverlayWindow()
        capturedScreenshots = [:]
        screenshotScreenFrames = [:]
        appModel.currentScreenshot = nil
        appModel.currentScreenFrame = .zero
        appModel.currentMouseLocation = .zero
    }
    
    func getColorAtScreenPoint(_ screenPoint: NSPoint) -> NSColor? {
        if let color = getColorFromScreenshot(at: screenPoint) {
            return color
        }
        gDebugPrint("getColorAtScreenPoint: screenshot path failed at \(screenPoint), falling back to live display capture")
        return getColorFromDisplay(at: screenPoint)
    }

    func getColorFromScreenshot(at screenPoint: NSPoint) -> NSColor? {
        guard let currentScreen = ScreenHelper.getScreenWithMouse() else {
            gDebugPrint("getColorFromScreenshot: no screen contains mouse at \(screenPoint)")
            return nil
        }
        let displayID = currentScreen.displayID
        guard let screenshot = capturedScreenshots[displayID] else {
            gDebugPrint("getColorFromScreenshot: no captured screenshot for displayID=\(displayID)")
            return nil
        }
        guard let screenFrame = screenshotScreenFrames[displayID] ?? Optional(currentScreen.frame) else {
            gDebugPrint("getColorFromScreenshot: no screen frame for displayID=\(displayID)")
            return nil
        }
        guard let cgImage = screenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            gDebugPrint("getColorFromScreenshot: could not get CGImage from screenshot")
            return nil
        }

        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)
        let screenHeight = screenFrame.height

        let relativeX = screenPoint.x - screenFrame.origin.x
        let relativeY = screenPoint.y - screenFrame.origin.y
        let imageY = screenHeight - relativeY

        let imagePointX = (relativeX / screenFrame.width) * pixelWidth
        let imagePointY = (imageY / screenFrame.height) * pixelHeight

        guard imagePointX >= 0 && imagePointX < pixelWidth &&
              imagePointY >= 0 && imagePointY < pixelHeight else {
            gDebugPrint("getColorFromScreenshot: point out of bounds image=(\(Int(imagePointX)), \(Int(imagePointY))) pixels=\(Int(pixelWidth))x\(Int(pixelHeight)) screenPoint=\(screenPoint)")
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.colorAt(x: Int(imagePointX), y: Int(imagePointY))
    }

    func getColorFromDisplay(at screenPoint: NSPoint) -> NSColor? {
        guard let currentScreen = ScreenHelper.getScreenWithMouse() else {
            gDebugPrint("getColorFromDisplay: no screen contains mouse at \(screenPoint)")
            return nil
        }

        let displayID = currentScreen.displayID
        let screenHeight = currentScreen.frame.size.height

        if pixelConverterWindow.frame != currentScreen.frame {
            pixelConverterWindow.setFrameOrigin(currentScreen.frame.origin)
            pixelConverterWindow.setContentSize(currentScreen.frame.size)
        }

        let mousePositionWithinScreen = pixelConverterWindow.convertPoint(fromScreen: screenPoint)
        let mousePositionWithinScreenInvertedY = screenHeight - mousePositionWithinScreen.y
        // Offset by 2px to avoid reading the MouseTrap UI — see Comment AD+F_102 / MT_21
        let colourPickingPixelFrame = NSRect(
            x: max(0, mousePositionWithinScreen.x - 2),
            y: max(0, mousePositionWithinScreenInvertedY - 2),
            width: 1,
            height: 1
        )

        guard let imageRef = CGDisplayCreateImage(displayID, rect: colourPickingPixelFrame) else {
            gDebugPrint("getColorFromDisplay: CGDisplayCreateImage failed displayID=\(displayID) rect=\(colourPickingPixelFrame)")
            return nil
        }

        let color = NSBitmapImageRep(cgImage: imageRef).colorAt(x: 0, y: 0)
        gDebugPrint("getColorFromDisplay: sampled \(color?.description ?? "nil") at screenPoint=\(screenPoint) rect=\(colourPickingPixelFrame)")
        return color
    }

    func addMouseAndKeyboardObservers() {
        if(mouseMoveMonitor != nil && mouseClickMonitor != nil && keyMonitor != nil) {
            gDebugPrint("addMouseAndKeyboardObservers: monitors already installed")
            // all monitors already exist, so nothing to do
            return
        } else if (mouseMoveMonitor == nil || mouseClickMonitor == nil || keyMonitor == nil) {
            // one of the monitors is nil, so we'll reset them all
            removeMouseAndKeyboardObservers()
        }

        captureScreenshot()
        installMouseAndKeyboardMonitors()
        gDebugPrint("addMouseAndKeyboardObservers: monitors installed for mode=\(debugPickingModeLabel(appModel.pickingMode))")
    }

    private func installMouseAndKeyboardMonitors() {
        gDebugPrint("installMouseAndKeyboardMonitors")
        mouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
            // This shouldn't actually happen, as the monitor should be inactive when not picking.
            if (self.appModel.pickingMode == .notPicking) {
                return $0
            }

            var mouseLocation: NSPoint { NSEvent.mouseLocation }
            
            // Update mouse location and screenshot in AppModel
            self.appModel.currentMouseLocation = mouseLocation
            if let currentScreen = ScreenHelper.getScreenWithMouse(),
               let screenshot = self.capturedScreenshots[currentScreen.displayID] {
                self.appModel.currentScreenshot = screenshot
                self.appModel.currentScreenFrame = self.screenshotScreenFrames[currentScreen.displayID] ?? currentScreen.frame
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
            self.positionMouseTrapWindow(mouseTrapFrame)

            // Read color from screenshot instead of live screen
            // We read the pixel that is 2 pixels to the left of the mouse cursor to avoid reading the MouseTrap UI
            let colorPickingPoint = NSPoint(x: mouseLocation.x, y: mouseLocation.y)
            
            guard let nsColor = self.getColorAtScreenPoint(colorPickingPoint) else {
                gDebugPrint("mouseMoveMonitor: failed to read color at \(colorPickingPoint)")
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

            let pickingMode = self.appModel.pickingMode
            let clickLocation = NSEvent.mouseLocation
            let capturedColorHex = self.appModel.currentPickerColor?.hexString

            // Defer capture and cleanup so SwiftUI/Core Data updates and monitor removal
            // never run inside the event monitor callback (fixes EXC_BAD_ACCESS on 2nd colour).
            DispatchQueue.main.async {
                guard self.appModel.pickingMode == pickingMode else { return }

                if pickingMode == .pickingFirstColor {
                    gDebugPrint("mouseClickMonitor: capturing first color at \(clickLocation) color=\(capturedColorHex ?? "nil")")
                    self.appModel.captureFirstColor()
                } else if pickingMode == .pickingSecondColor {
                    gDebugPrint("mouseClickMonitor: capturing second color at \(clickLocation) color=\(capturedColorHex ?? "nil")")
                    self.appModel.captureSecondColor()
                }

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
                gDebugPrint("keyMonitor: ESC pressed, cancelling pick")
                DispatchQueue.main.async {
                    self.appModel.cancelPick()
                    self.updateMouseTrapWindow()
                }
                return nil // Consume the event
            }
            
            return event
        }
    }

    private static let popoverAndPickPopoverDelay: TimeInterval = 0.5
    private static let popoverAndPickPickDelay: TimeInterval = 0.5

    func openPopoverAndStartPick() {
        let popoverDelay = Self.popoverAndPickPopoverDelay
        let pickDelay = Self.popoverAndPickPickDelay

        gDebugPrint("openPopoverAndStartPick: waiting \(popoverDelay)s before opening popover")
        DispatchQueue.main.asyncAfter(deadline: .now() + popoverDelay) {
            self.checkScreenRecordingPermissions()
            gDebugPrint("openPopoverAndStartPick: opening popover")
            self.showPopover()

            gDebugPrint("openPopoverAndStartPick: waiting \(pickDelay)s before starting pick")
            DispatchQueue.main.asyncAfter(deadline: .now() + pickDelay) {
                gDebugPrint("openPopoverAndStartPick: starting pick")
                self.appModel.createNewPick()
                self.updateMouseTrapWindow()
            }
        }
    }

    func showPopover() {
        guard let sbutton = statusBarItem.button,
              let contentView = colourPickerWindow.contentView else { return }

        let buttonRect: NSRect = sbutton.convert(sbutton.bounds, to: nil)
        let screenRect: NSRect = sbutton.window!.convertToScreen(buttonRect)

        let posX = screenRect.origin.x + (screenRect.width / 2) - 10
        let posY = screenRect.origin.y

        colourPickerWindow.setFrame(NSRect(x: posX, y: posY, width: 20, height: 5), display: true, animate: false)
        updateMouseTrapWindow()

        guard !popover.isShown else { return }

        colourPickerWindow.makeKeyAndOrderFront(self)
        NSApplication.shared.presentationOptions = []
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: contentView.frame, of: contentView, preferredEdge: NSRectEdge.minY)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        let event = NSApp.currentEvent!

        if event.type == NSEvent.EventType.leftMouseUp {
            if event.modifierFlags.contains(.option) {
                openPopoverAndStartPick()
            } else if popover.isShown {
                popover.performClose(sender)
                self.appModel.cancelPick()
                updateMouseTrapWindow()
            } else {
                showPopover()
            }
        } else if event.type == NSEvent.EventType.rightMouseUp {
            openMenu()
        }
    }
}
