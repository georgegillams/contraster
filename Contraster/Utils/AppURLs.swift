//
//  AppURLs.swift
//  Contraster
//

import AppKit

enum AppURLs {
    static let feedback = URL(string: "https://www.georgegillams.co.uk/contraster-feedback")!
    static let author = URL(string: "https://www.georgegillams.co.uk/")!

    static func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    static func openFeedback() {
        open(feedback)
    }
}
