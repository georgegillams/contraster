//
//  PopoverController.swift
//  Contraster
//

import AppKit

@MainActor
final class PopoverController {
    private let popover: NSPopover
    private let statusBarItem: NSStatusItem
    private let colourPickerWindow: NSWindow
    private let onBeforeShow: () -> Void

    init(
        popover: NSPopover,
        statusBarItem: NSStatusItem,
        colourPickerWindow: NSWindow,
        onBeforeShow: @escaping () -> Void
    ) {
        self.popover = popover
        self.statusBarItem = statusBarItem
        self.colourPickerWindow = colourPickerWindow
        self.onBeforeShow = onBeforeShow
    }

    var isShown: Bool { popover.isShown }

    func configureContentView(_ view: NSView) {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    func configureSurface() {
        guard let contentView = popover.contentViewController?.view else { return }

        configureContentView(contentView)

        if let frameView = contentView.superview {
            frameView.wantsLayer = true
            frameView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }

        if let window = contentView.window {
            window.backgroundColor = NSColor.windowBackgroundColor
            window.isOpaque = true
        }
    }

    func updateContentSize() {
        guard popover.isShown,
              let view = popover.contentViewController?.view else { return }

        view.layoutSubtreeIfNeeded()
        let fittingHeight = ceil(view.fittingSize.height)
        let height = min(
            max(fittingHeight, InterfaceConstants.popoverMinHeight),
            InterfaceConstants.popoverMaxHeight
        )
        popover.contentSize = NSSize(width: InterfaceConstants.popoverWidth, height: height)
    }

    func show() {
        guard let sbutton = statusBarItem.button,
              let contentView = colourPickerWindow.contentView,
              let buttonWindow = sbutton.window else { return }

        let buttonRect = sbutton.convert(sbutton.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)

        let posX = screenRect.origin.x + (screenRect.width / 2) - 10
        let posY = screenRect.origin.y

        colourPickerWindow.setFrame(NSRect(x: posX, y: posY, width: 20, height: 5), display: true, animate: false)
        onBeforeShow()

        guard !popover.isShown else { return }

        colourPickerWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.presentationOptions = []
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: contentView.frame, of: contentView, preferredEdge: .minY)
        DispatchQueue.main.async {
            self.configureSurface()
            self.updateContentSize()
        }
    }

    func close(sender: AnyObject?) {
        popover.performClose(sender)
    }
}
