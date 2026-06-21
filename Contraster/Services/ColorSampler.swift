//
//  ColorSampler.swift
//  Contraster
//

import AppKit
import SwiftUI

@MainActor
final class ColorSampler {
    private var cachedBitmapReps: [CGDirectDisplayID: NSBitmapImageRep] = [:]
    private var cachedGeneration = -1

    private let screenshotService: ScreenshotCaptureService
    private let pixelConverterWindow: NSWindow

    init(screenshotService: ScreenshotCaptureService, pixelConverterWindow: NSWindow) {
        self.screenshotService = screenshotService
        self.pixelConverterWindow = pixelConverterWindow
    }

    func invalidateCache() {
        cachedBitmapReps = [:]
        cachedGeneration = -1
    }

    func colorAtScreenPoint(_ screenPoint: NSPoint) -> NSColor? {
        if let color = colorFromScreenshot(at: screenPoint) {
            return color
        }
        gDebugPrint("getColorAtScreenPoint: screenshot path failed at \(screenPoint), falling back to live display capture")
        return colorFromDisplay(at: screenPoint)
    }

    private func colorFromScreenshot(at screenPoint: NSPoint) -> NSColor? {
        guard let currentScreen = ScreenHelper.getScreenWithMouse() else {
            return nil
        }

        let displayID = currentScreen.displayID
        guard let screenshot = screenshotService.screenshot(for: displayID) else {
            return nil
        }

        let screenFrame = screenshotService.screenFrame(for: displayID) ?? currentScreen.frame
        guard let cgImage = screenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let imagePoint = ScreenCoordinateMapper.imagePoint(
            for: screenPoint,
            screenFrame: screenFrame,
            pixelSize: pixelSize
        )

        guard ScreenCoordinateMapper.isPointInBounds(imagePoint, pixelSize: pixelSize) else {
            return nil
        }

        let bitmapRep = bitmapRep(for: cgImage, displayID: displayID)
        return bitmapRep.colorAt(x: Int(imagePoint.x), y: Int(imagePoint.y))
    }

    private func bitmapRep(for cgImage: CGImage, displayID: CGDirectDisplayID) -> NSBitmapImageRep {
        let generation = screenshotService.captureGeneration
        if generation != cachedGeneration {
            cachedBitmapReps = [:]
            cachedGeneration = generation
        }

        if let cached = cachedBitmapReps[displayID] {
            return cached
        }

        let rep = NSBitmapImageRep(cgImage: cgImage)
        cachedBitmapReps[displayID] = rep
        return rep
    }

    private func colorFromDisplay(at screenPoint: NSPoint) -> NSColor? {
        guard let currentScreen = ScreenHelper.getScreenWithMouse() else {
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
        let colourPickingPixelFrame = NSRect(
            x: max(0, mousePositionWithinScreen.x - 2),
            y: max(0, mousePositionWithinScreenInvertedY - 2),
            width: 1,
            height: 1
        )

        guard let imageRef = CGDisplayCreateImage(displayID, rect: colourPickingPixelFrame) else {
            return nil
        }

        return NSBitmapImageRep(cgImage: imageRef).colorAt(x: 0, y: 0)
    }
}
