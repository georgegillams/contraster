//
//  AppDelegate.swift
//  Contraster
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate, ContrasterAppActions {
    let colourPickerWindow = NSWindow(
        contentRect: NSMakeRect(0, 0, 50, 50),
        styleMask: .borderless,
        backing: .buffered,
        defer: false
    )
    let mouseTrapWindow = NSWindow(
        contentRect: NSMakeRect(0, 0, 0, 0),
        styleMask: .borderless,
        backing: .buffered,
        defer: false
    )
    let pixelConverterWindow = NSWindow(
        contentRect: NSMakeRect(0, 0, 0, 0),
        styleMask: .borderless,
        backing: .buffered,
        defer: false
    )
    var tutorialWindow: NSWindow?

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var mainUI: Main?
    var tutorialUI: Tutorial?
    var mouseTrapUI: MouseTrap?
    var appModel = AppModel()

    private lazy var screenshotService = ScreenshotCaptureService()
    private lazy var colorSampler = ColorSampler(
        screenshotService: screenshotService,
        pixelConverterWindow: pixelConverterWindow
    )
    private lazy var pickingCoordinator = ColorPickingCoordinator(
        appModel: appModel,
        screenshotService: screenshotService,
        colorSampler: colorSampler,
        mouseTrapWindow: mouseTrapWindow
    )
    private var popoverController: PopoverController!
    private let permissionMonitor = ScreenRecordingPermissionMonitor.shared

    func showWelcomeTutorial() {
        tutorialUI = Tutorial(appModel: appModel, appActions: self)
        tutorialWindow = NSWindow(
            contentRect: NSMakeRect(200, 200, 800, 500),
            styleMask: [.closable, .titled, .resizable],
            backing: .buffered,
            defer: false
        )
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

    func hasScreenRecordingPermissions() -> Bool {
        permissionMonitor.refresh()
        return permissionMonitor.hasPermissions
    }

    func checkScreenRecordingPermissions() {
        permissionMonitor.refresh()

        if !permissionMonitor.hasPermissions {
            gDebugPrint("checkScreenRecordingPermissions: permission not granted, showing dialog")
            permissionMonitor.requestPermissionIfNeeded()
            permissionMonitor.scheduleBackgroundRecheck { [weak self] in
                self?.checkScreenRecordingPermissions()
            }
            return
        }

        gDebugPrint("checkScreenRecordingPermissions: permission granted")
    }

    func openScreenRecordingPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mainUI = Main(appModel: appModel, appActions: self)
        mouseTrapUI = MouseTrap(appModel: appModel)

        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        colourPickerWindow.level = .floating
        colourPickerWindow.alphaValue = 0

        mouseTrapWindow.contentViewController = NSHostingController(rootView: mouseTrapUI)
        configureMouseTrapWindow()

        let popover = NSPopover()
        popover.behavior = .applicationDefined
        let hostingController = NSHostingController(rootView: mainUI)
        if #available(macOS 13.0, *) {
            hostingController.sizingOptions = [.intrinsicContentSize]
        }
        popoverController = PopoverController(
            popover: popover,
            statusBarItem: statusBarItem,
            colourPickerWindow: colourPickerWindow,
            onBeforeShow: { [weak self] in
                self?.updateMouseTrapWindow()
            }
        )
        popoverController.configureContentView(hostingController.view)
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(
            width: InterfaceConstants.popoverWidth,
            height: InterfaceConstants.popoverMaxHeight
        )
        self.popover = popover
        self.popover.contentViewController?.view.window?.becomeKey()

        pickingCoordinator.onPickingEnded = { [weak self] in
            guard let self else { return }
            self.appModel.currentScreenshot = nil
            self.appModel.currentScreenFrame = .zero
            self.appModel.currentMouseLocation = .zero
        }
        pickingCoordinator.onPermissionNeeded = { [weak self] in
            self?.checkScreenRecordingPermissions()
        }
        pickingCoordinator.onPickStateChanged = { [weak self] in
            self?.updateMouseTrapWindow()
        }

        if let button = statusBarItem.button {
            button.image = NSImage(named: NSImage.Name("menu-icon"))
            button.imagePosition = .imageOnly
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12.0, weight: .light)
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        if isGDebugScheme {
            runDebugStartupSequence()
        } else if appModel.isFirstWelcomeDone() {
            checkScreenRecordingPermissions()
        } else {
            showWelcomeTutorial()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {}

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    private func configureMouseTrapWindow() {
        mouseTrapWindow.level = .screenSaver
        mouseTrapWindow.backgroundColor = NSColor.clear
        mouseTrapWindow.contentView?.wantsLayer = true
        mouseTrapWindow.contentView?.layer?.cornerRadius = 8
        mouseTrapWindow.contentView?.layer?.masksToBounds = true
        WindowAnimationHelper.disableImplicitAnimations(mouseTrapWindow)
        mouseTrapWindow.orderOut(nil)
    }

    @objc func updateMouseTrapWindow() {
        gDebugPrint("updateMouseTrapWindow: mode=\(appModel.pickingMode)")
        if appModel.pickingMode == .notPicking {
            DispatchQueue.main.async { [weak self] in
                self?.pickingCoordinator.stopPicking()
                self?.pickingCoordinator.hideMouseTrap()
            }
        } else {
            pickingCoordinator.startPicking()
        }
    }

    func updatePopoverContentSize() {
        popoverController.updateContentSize()
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .leftMouseUp {
            if event.modifierFlags.contains(.option) {
                openPopoverAndStartPick()
            } else if popoverController.isShown {
                popoverController.close(sender: sender)
                appModel.cancelPick()
                updateMouseTrapWindow()
            } else {
                popoverController.show()
            }
        } else if event.type == .rightMouseUp {
            openMenu()
        }
    }

    @objc func openAbout() {
        AboutWindowController.createWindow(appActions: self)
    }

    @objc func viewOnboarding() {
        showWelcomeTutorial()
    }

    @objc func openMenu() {
        let version = Bundle.main.appVersion
        let menu = NSMenu()
        menu.addItem(withTitle: "About Contraster", action: #selector(openAbout), keyEquivalent: "")
        menu.addItem(withTitle: "Show tutorial", action: #selector(viewOnboarding), keyEquivalent: "")
        menu.addItem(withTitle: "Send me feedback", action: #selector(openFeedback), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Contraster \(version)", action: nil, keyEquivalent: ""))
        menu.addItem(withTitle: "Quit Contraster", action: #selector(quit), keyEquivalent: "q")

        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
        statusBarItem.menu = nil
    }

    @objc func openFeedback() {
        AppURLs.openFeedback()
    }

    @objc func quit() {
        NSApp.terminate(self)
    }

    private static let popoverAndPickPopoverDelay: TimeInterval = 0.5
    private static let popoverAndPickPickDelay: TimeInterval = 0.5

    func openPopoverAndStartPick() {
        let popoverDelay = Self.popoverAndPickPopoverDelay
        let pickDelay = Self.popoverAndPickPickDelay

        DispatchQueue.main.asyncAfter(deadline: .now() + popoverDelay) { [weak self] in
            guard let self else { return }
            self.checkScreenRecordingPermissions()
            self.popoverController.show()

            DispatchQueue.main.asyncAfter(deadline: .now() + pickDelay) { [weak self] in
                guard let self else { return }
                self.appModel.createNewPick()
                self.updateMouseTrapWindow()
            }
        }
    }

    private func runDebugStartupSequence() {
        openPopoverAndStartPick()
    }
}
