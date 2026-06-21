//
//  ContrasterAppActions.swift
//  Contraster
//

import AppKit

@MainActor
protocol ContrasterAppActions: AnyObject {
    func togglePopover(_ sender: AnyObject?)
    func openMenu()
    func updateMouseTrapWindow()
    func showWelcomeTutorial()
    func hideTutorial()
    func hasScreenRecordingPermissions() -> Bool
    func checkScreenRecordingPermissions()
    func openScreenRecordingPreferences()
    func updatePopoverContentSize()
}

extension ContrasterAppActions where Self: AppDelegate {
    static var current: ContrasterAppActions? {
        NSApp.delegate as? ContrasterAppActions
    }
}
