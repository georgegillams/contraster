//
//  ScreenRecordingPermissionMonitor.swift
//  Contraster
//

import Combine
import CoreGraphics
import Foundation

@MainActor
final class ScreenRecordingPermissionMonitor: ObservableObject {
    static let shared = ScreenRecordingPermissionMonitor()

    @Published private(set) var hasPermissions = false

    private var pollingTimer: Timer?
    private let pollInterval: TimeInterval = 2.0

    private init() {}

    func refresh() {
        hasPermissions = CGPreflightScreenCaptureAccess()
        gDebugPrint("ScreenRecordingPermissionMonitor.refresh: \(hasPermissions)")
    }

    func startPolling() {
        refresh()
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
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
