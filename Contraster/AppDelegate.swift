//
//  AppDelegate.swift
//  Contraster
//

import Cocoa
import LaunchAtLogin
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, ContrasterAppActions {
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
    private var tutorialHostingController: NSHostingController<Tutorial>?

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
    private var popoverEscapeMonitor: Any?
    private let permissionMonitor = ScreenRecordingPermissionMonitor.shared

    func showWelcomeTutorial() {
        if tutorialWindow == nil {
            let window = NSWindow(
                contentRect: NSMakeRect(200, 200, 800, 500),
                styleMask: [.closable, .titled, .resizable],
                backing: .buffered,
                defer: false
            )
            window.contentView?.wantsLayer = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .visible
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.isReleasedWhenClosed = false
            window.delegate = self
            tutorialWindow = window
        }

        let tutorial = Tutorial(
            appModel: appModel,
            appActions: self,
            permissionMonitor: permissionMonitor
        )
        tutorialUI = tutorial

        tutorialWindow?.contentViewController = nil
        let hostingController = NSHostingController(rootView: tutorial)
        tutorialHostingController = hostingController
        tutorialWindow?.contentViewController = hostingController
        tutorialWindow?.makeKeyAndOrderFront(nil)
    }

    func hideTutorial() {
        tutorialWindow?.orderOut(nil)
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

        installPopoverEscapeMonitor()
        installSystemEventObservers()

        if isGDebugScheme {
            runDebugStartupSequence()
            showWelcomeTutorial()
        } else if appModel.isFirstWelcomeDone() {
            checkScreenRecordingPermissions()
        } else {
            showWelcomeTutorial()
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window === tutorialWindow else { return }
        tutorialWindow?.contentViewController = nil
        tutorialHostingController = nil
        tutorialUI = nil
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
                closePopover(sender: sender)
            } else {
                popoverController.show()
            }
        } else if event.type == .rightMouseUp {
            openMenu()
        }
    }

    private func closePopover(sender: AnyObject? = nil) {
        guard popoverController.isShown else { return }
        popoverController.close(sender: sender)
        appModel.cancelPick()
        updateMouseTrapWindow()
    }

    private func installPopoverEscapeMonitor() {
        popoverEscapeMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            guard event.keyCode == 53 else { return event }
            guard self.popoverController.isShown else { return event }
            guard self.appModel.pickingMode == .notPicking else { return event }
            self.closePopover()
            return nil
        }
    }

    private func installSystemEventObservers() {
        let workspace = NSWorkspace.shared
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSystemSleepOrLock(_:)),
            name: NSWorkspace.willSleepNotification,
            object: workspace
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSystemSleepOrLock(_:)),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
    }

    @objc private func handleSystemSleepOrLock(_ notification: Notification) {
        closePopover()
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
        menu.addItem(withTitle: "Clear picking history", action: #selector(clearPickingHistory), keyEquivalent: "")
        let launchAtLoginItem = menu.addItem(
            withTitle: "Launch at login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchAtLoginItem.state = LaunchAtLogin.isEnabled ? .on : .off
        launchAtLoginItem.target = self
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

    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled.toggle()
    }

    @objc func clearPickingHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear picking history?"
        alert.informativeText = "This will permanently delete all saved colour picks. This cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear history")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        appModel.clearPickingHistory()
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
