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

        let color = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )
        return color
    }
    
    public init?(hex: String) {
        let hexWAlph="\(hex)FF"
        let r, g, b: CGFloat

        if hexWAlph.hasPrefix("#") {
            let start = hexWAlph.index(hexWAlph.startIndex, offsetBy: 1)
            let hexColor = String(hexWAlph[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255

                    self.init(red: r, green: g, blue: b)
                    return
                }
            }
        }

        return nil
    }
}
