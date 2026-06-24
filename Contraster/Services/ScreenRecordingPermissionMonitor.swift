//
//  ScreenRecordingPermissionMonitor.swift
//  Contraster
//

import AppKit
import Combine
import CoreGraphics
import Foundation

@MainActor
final class ScreenRecordingPermissionMonitor: ObservableObject {
    static let shared = ScreenRecordingPermissionMonitor()

    @Published private(set) var hasPermissions = false

    private var pollingTimer: Timer?
    private var activationObserver: NSObjectProtocol?
    private let pollInterval: TimeInterval = 2.0

    private init() {
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func refresh() {
        hasPermissions = CGPreflightScreenCaptureAccess()
        gDebugPrint("ScreenRecordingPermissionMonitor.refresh: \(hasPermissions)")
    }

    func startPolling() {
        refresh()
        pollingTimer?.invalidate()
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollingTimer = timer
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    func requestPermissionIfNeeded() {
        if !hasPermissions {
            CGRequestScreenCaptureAccess()
        }
    }

    func scheduleBackgroundRecheck(after interval: TimeInterval = 10.0, handler: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: handler)
    }
}
