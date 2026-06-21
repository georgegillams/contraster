//
//  Bundle+Version.swift
//  Contraster
//

import Foundation

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }
}
