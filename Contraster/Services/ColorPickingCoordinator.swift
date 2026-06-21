//
//  ColorPickingCoordinator.swift
//  Contraster
//

import AppKit
import SwiftUI

@MainActor
final class ColorPickingCoordinator {
    private weak var appModel: AppModel?
    private let screenshotService: ScreenshotCaptureService
    private let colorSampler: ColorSampler
    private let mouseTrapWindow: NSWindow

    private var mouseMoveMonitor: Any?
    private var mouseClickMonitor: Any?
    private var scrollMonitor: Any?
    private var keyMonitor: Any?
    private var scrollWheelAccumulator: CGFloat = 0

    var onPickingEnded: (() -> Void)?
    var onPermissionNeeded: (() -> Void)?
    var onPickStateChanged: (() -> Void)?

    init(
        appModel: AppModel,
        screenshotService: ScreenshotCaptureService,
        colorSampler: ColorSampler,
        mouseTrapWindow: NSWindow
    ) {
        self.appModel = appModel
        self.screenshotService = screenshotService
        self.colorSampler = colorSampler
        self.mouseTrapWindow = mouseTrapWindow
    }

    func startPicking() {
        guard let appModel else { return }

        if mouseMoveMonitor != nil && mouseClickMonitor != nil && scrollMonitor != nil && keyMonitor != nil {
            return
        } else if mouseMoveMonitor == nil || mouseClickMonitor == nil || scrollMonitor == nil || keyMonitor == nil {
            stopPicking()
        }

        screenshotService.captureScreenshot(onPermissionNeeded: { [weak self] in
            self?.onPermissionNeeded?()
        })
        installMonitors()
        gDebugPrint("ColorPickingCoordinator: monitors installed for mode=\(appModel.pickingMode)")
    }

    func stopPicking() {
        gDebugPrint("ColorPickingCoordinator: stopPicking")
        let moveMonitor = mouseMoveMonitor
        let clickMonitor = mouseClickMonitor
        let scrollWheelMonitor = scrollMonitor
        let escMonitor = keyMonitor
        mouseMoveMonitor = nil
        mouseClickMonitor = nil
        scrollMonitor = nil
        keyMonitor = nil
        scrollWheelAccumulator = 0

        [moveMonitor, clickMonitor, scrollWheelMonitor, escMonitor].compactMap { $0 }.forEach {
            NSEvent.removeMonitor($0)
        }

        colorSampler.invalidateCache()
        screenshotService.cleanup()
        onPickingEnded?()
    }

    func positionMouseTrap(at mouseLocation: NSPoint) {
        guard appModel?.pickingMode != .notPicking else { return }

        let windowWidth = max(InterfaceConstants.magnificationWidth, InterfaceConstants.mouseTrapRectSize.width)
        let windowHeight = max(InterfaceConstants.magnificationHeight, InterfaceConstants.mouseTrapRectSize.height)

        let mouseTrapFrame = NSRect(
            x: mouseLocation.x - windowWidth / 2,
            y: mouseLocation.y - windowHeight / 2,
            width: windowWidth,
            height: windowHeight
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            mouseTrapWindow.setFrame(mouseTrapFrame, display: true)
        }

        if !mouseTrapWindow.isVisible {
            mouseTrapWindow.orderFrontRegardless()
        }
    }

    func hideMouseTrap() {
        mouseTrapWindow.orderOut(nil)
    }

    private func installMonitors() {
        mouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            guard let self, let appModel = self.appModel else { return event }
            if appModel.pickingMode == .notPicking { return event }

            let mouseLocation = NSEvent.mouseLocation
            appModel.currentMouseLocation = mouseLocation

            if let currentScreen = ScreenHelper.getScreenWithMouse(),
               let screenshot = self.screenshotService.screenshot(for: currentScreen.displayID) {
                appModel.currentScreenshot = screenshot
                appModel.currentScreenFrame = self.screenshotService.screenFrame(for: currentScreen.displayID) ?? currentScreen.frame
            }

            self.positionMouseTrap(at: mouseLocation)

            guard let nsColor = self.colorSampler.colorAtScreenPoint(mouseLocation) else {
                return event
            }

            let color = Color(cgColor: nsColor.cgColor)
            switch appModel.pickingMode {
            case .pickingFirstColor:
                appModel.updatePreviewColor(color, slot: .first)
            case .pickingSecondColor:
                appModel.updatePreviewColor(color, slot: .second)
            case .notPicking:
                break
            }

            return event
        }

        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            guard let self, let appModel = self.appModel else { return event }
            if appModel.pickingMode == .notPicking { return event }
            self.handleMagnificationScroll(event)
            return nil
        }

        mouseClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { [weak self] event in
            guard let self, let appModel = self.appModel else { return event }
            if appModel.pickingMode == .notPicking { return event }
            if event.type == .leftMouseUp { return event }

            let pickingMode = appModel.pickingMode

            DispatchQueue.main.async { [weak self] in
                guard appModel.pickingMode == pickingMode else { return }

                if pickingMode == .pickingFirstColor {
                    appModel.captureFirstColor()
                } else if pickingMode == .pickingSecondColor {
                    appModel.captureSecondColor()
                }

                self?.onPickStateChanged?()
            }

            return event
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, let appModel = self.appModel else { return event }
            if appModel.pickingMode == .notPicking { return event }

            if event.keyCode == 53 {
                DispatchQueue.main.async { [weak self] in
                    appModel.cancelPick()
                    self?.onPickStateChanged?()
                }
                return nil
            }

            return event
        }
    }

    private func handleMagnificationScroll(_ event: NSEvent) {
        guard let appModel else { return }
        let delta = event.scrollingDeltaY
        guard delta != 0 else { return }

        scrollWheelAccumulator += delta
        let scrollThreshold = event.hasPreciseScrollingDeltas
            ? InterfaceConstants.magnificationScrollThresholdPrecise
            : InterfaceConstants.magnificationScrollThresholdDiscrete

        while scrollWheelAccumulator >= scrollThreshold {
            appModel.adjustMagnificationScale(by: 1)
            scrollWheelAccumulator -= scrollThreshold
        }
        while scrollWheelAccumulator <= -scrollThreshold {
            appModel.adjustMagnificationScale(by: -1)
            scrollWheelAccumulator += scrollThreshold
        }
    }
}
