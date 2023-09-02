//
//  Color+Functions.swift
//  Contraster
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

    func lighter(by percentage: CGFloat = 30.0) -> Color? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> Color? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> Color? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0

        NSColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return Color(red: min(red + percentage/100, 1.0),
                     green: min(green + percentage/100, 1.0),
                     blue: min(blue + percentage/100, 1.0))

    }
}
