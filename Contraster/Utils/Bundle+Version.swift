//
//  Bundle+Version.swift
//  Contraster
//

import Foundation

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }

    /// True for debug builds run from Xcode (distinct bundle ID and menu label).
    var isLocalDevelopment: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// Shown in the menu bar build line.
    var menuBuildLabel: String {
        isLocalDevelopment ? "local development" : appVersion
    }

    /// Name shown in System Settings → Screen Recording.
    var screenRecordingSettingsName: String {
        infoDictionary?["CFBundleName"] as? String ?? "Contraster"
    }
}
