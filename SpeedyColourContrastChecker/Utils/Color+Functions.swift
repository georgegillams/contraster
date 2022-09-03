//
//  Color+Functions.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 02/09/2022.
//

import SwiftUI

extension Color {
    var hexString: String {
        let colorRef = cgColor?.components
        let r = colorRef?[0] ?? 0
        let g = colorRef?[1] ?? 0
        let b = ((colorRef?.count ?? 0) > 2 ? colorRef?[2] : g) ?? 0
        let a = cgColor?.alpha

        var color = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )
        if a ?? 0 < 1 {
            color += String(format: "%02lX", lroundf(Float(a ?? 0)))
        }
        return color
    }
}
