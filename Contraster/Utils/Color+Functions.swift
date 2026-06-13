//
//  Color+Functions.swift
//  Contraster
//
//  Created by George Gillams on 02/09/2022.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

extension Color {
    var sRGBAComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        if let cgColor,
           let rgbColor = cgColor.converted(
               to: CGColorSpaceCreateDeviceRGB(),
               intent: .defaultIntent,
               options: nil
           ),
           let components = rgbColor.components,
           components.count >= 3 {
            let alpha = components.count > 3 ? components[3] : 1
            return (components[0], components[1], components[2], alpha)
        }

        #if os(macOS)
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
        #else
        return nil
        #endif
    }

    var hexString: String {
        guard let components = sRGBAComponents else { return "#000000" }

        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(components.red * 255)),
            lroundf(Float(components.green * 255)),
            lroundf(Float(components.blue * 255))
        )
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
        guard let components = sRGBAComponents else { return nil }

        return Color(
            red: max(0, min(components.red + percentage / 100, 1.0)),
            green: max(0, min(components.green + percentage / 100, 1.0)),
            blue: max(0, min(components.blue + percentage / 100, 1.0))
        )
    }
}
