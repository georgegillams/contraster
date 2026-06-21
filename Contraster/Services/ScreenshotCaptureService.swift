//
//  ScreenshotCaptureService.swift
//  Contraster
//

import AppKit
import CoreImage
import ScreenCaptureKit

@MainActor
final class ScreenshotCaptureService {
    private(set) var capturedScreenshots: [CGDirectDisplayID: NSImage] = [:]
    private(set) var screenshotScreenFrames: [CGDirectDisplayID: NSRect] = [:]
    private(set) var captureGeneration = 0

    var overlayWindow: NSWindow?

    func captureScreenshot(onPermissionNeeded: () -> Void) {
        captureGeneration += 1
        let generation = captureGeneration

        gDebugPrint("captureScreenshot: generation=\(generation) screenRecordingPermission=\(CGPreflightScreenCaptureAccess())")
        captureScreenshotsSynchronously()
        gDebugPrint("captureScreenshot: synchronous capture stored \(capturedScreenshots.count) screen(s)")
        showScreenshotOverlay()

        if !CGPreflightScreenCaptureAccess() {
            gDebugPrint("captureScreenshot: requesting screen recording permission")
            onPermissionNeeded()
        } else if #available(macOS 14.0, *) {
            gDebugPrint("captureScreenshot: refreshing screenshots via ScreenCaptureKit")
            Task { @MainActor in
                guard generation == self.captureGeneration else {
                    gDebugPrint("captureScreenshot: skipping stale ScreenCaptureKit refresh (generation \(generation))")
                    return
                }
                await self.captureScreenshotsWithScreenCaptureKit(generation: generation)
                guard generation == self.captureGeneration else { return }
                gDebugPrint("captureScreenshot: ScreenCaptureKit refresh stored \(self.capturedScreenshots.count) screen(s)")
                self.showScreenshotOverlay()
            }
        }
    }

    func cleanup() {
        gDebugPrint("cleanupScreenshot")
        captureGeneration += 1
        dismissOverlay()
        capturedScreenshots = [:]
        screenshotScreenFrames = [:]
    }

    func screenshot(for displayID: CGDirectDisplayID) -> NSImage? {
        capturedScreenshots[displayID]
    }

    func screenFrame(for displayID: CGDirectDisplayID) -> NSRect? {
        screenshotScreenFrames[displayID]
    }

    private func captureScreenshotsSynchronously() {
        capturedScreenshots = [:]
        screenshotScreenFrames = [:]

        for screen in NSScreen.screens {
            storeScreenshot(from: screen)
        }
    }

    @available(macOS 14.0, *)
    private func captureScreenshotsWithScreenCaptureKit(generation: Int) async {
        guard generation == captureGeneration else { return }

        var refreshedScreenshots: [CGDirectDisplayID: NSImage] = [:]
        var refreshedScreenFrames: [CGDirectDisplayID: NSRect] = [:]

        for screen in NSScreen.screens {
            let screenFrame = screen.frame

            do {
                let imageRef = try await captureDisplayImage(for: screen, frame: screenFrame)
                guard generation == captureGeneration else { return }
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
                }
            }
        }

        guard generation == captureGeneration else { return }
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

    private func storeScreenshot(from screen: NSScreen) {
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

    private func screenshotOverlayDisplayImage(from screenshot: NSImage, screenFrame: NSRect) -> NSImage {
        guard isGDebugScheme,
              let cgImage = screenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return screenshot
        }

        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIColorMatrix")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(x: 0.9, y: 1.0, z: 0.9, w: 0), forKey: "inputRVector")
        filter?.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        filter?.setValue(CIVector(x: 0.9, y: 1.0, z: 0.9, w: 0), forKey: "inputBVector")
        filter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

        guard let outputImage = filter?.outputImage else { return screenshot }

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return screenshot
        }

        return NSImage(cgImage: outputCGImage, size: screenFrame.size)
    }

    func showScreenshotOverlay() {
        guard let currentScreen = ScreenHelper.getScreenWithMouse(),
              let screenshot = capturedScreenshots[currentScreen.displayID] else {
            gDebugPrint("showScreenshotOverlay: no screenshot for current screen (capturedScreenshots.count=\(capturedScreenshots.count))")
            return
        }

        let screenFrame = screenshotScreenFrames[currentScreen.displayID] ?? currentScreen.frame
        let displayImage = screenshotOverlayDisplayImage(from: screenshot, screenFrame: screenFrame)

        if let overlayWindow,
           let imageView = overlayWindow.contentView as? NSImageView,
           overlayWindow.frame == screenFrame {
            imageView.animates = false
            imageView.image = displayImage
            return
        }

        dismissOverlay()

        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = .normal - 1
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.animationBehavior = .none
        WindowAnimationHelper.disableImplicitAnimations(window)

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: screenFrame.size))
        imageView.frame = NSRect(origin: .zero, size: screenFrame.size)
        imageView.imageScaling = .scaleNone
        imageView.imageAlignment = .alignCenter
        imageView.animates = false
        imageView.image = displayImage

        window.contentView = imageView
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            window.setFrame(screenFrame, display: true)
        }
        window.orderFront(nil)
        overlayWindow = window
    }

    private func dismissOverlay() {
        guard overlayWindow != nil else { return }
        overlayWindow?.orderOut(nil)
        overlayWindow?.contentView = nil
        overlayWindow = nil
    }
}

enum WindowAnimationHelper {
    static func disableImplicitAnimations(_ window: NSWindow) {
        window.contentView?.layer?.actions = [
            "bounds": NSNull(),
            "position": NSNull(),
            "frame": NSNull(),
            "onOrderIn": NSNull(),
            "onOrderOut": NSNull(),
        ]
    }
}
