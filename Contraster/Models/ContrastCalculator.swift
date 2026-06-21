//
//  ContrastCalculator.swift
//  Contraster
//

import SwiftUI

struct ContrastComplianceResult {
    let contrastRatio: Double
    let contrastRatioLabel: String
    let complianceLevelLgText: ComplianceLevel
    let complianceLevelSmText: ComplianceLevel
    let complianceLevelGraphical: ComplianceLevel
}

enum ContrastCalculator {
    static func calculateComponent(sRGB: CGFloat) -> CGFloat {
        if sRGB < 0.03928 {
            return sRGB / 12.92
        }
        return pow((sRGB + 0.055) / 1.055, 2.4)
    }

    static func calculateLuminance(color: Color) -> CGFloat {
        guard let components = color.sRGBAComponents else { return 0 }
        let componentR = calculateComponent(sRGB: components.red)
        let componentG = calculateComponent(sRGB: components.green)
        let componentB = calculateComponent(sRGB: components.blue)
        return 0.2126 * componentR + 0.7152 * componentG + 0.0722 * componentB
    }

    static func calculateContrastRatio(color1: Color, color2: Color) -> Double {
        let luminance1 = calculateLuminance(color: color1)
        let luminance2 = calculateLuminance(color: color2)
        let luminanceHigh = max(luminance1, luminance2)
        let luminanceLow = min(luminance1, luminance2)
        let contrastRatioValueUnrounded = (luminanceHigh + 0.05) / (luminanceLow + 0.05)
        return Double(round(100 * contrastRatioValueUnrounded) / 100)
    }

    static func compliance(for contrastRatioValue: Double) -> ContrastComplianceResult {
        let lgText: ComplianceLevel
        if contrastRatioValue > 4.5 {
            lgText = .passAAA
        } else if contrastRatioValue > 3 {
            lgText = .passAA
        } else {
            lgText = .fail
        }

        let smText: ComplianceLevel
        if contrastRatioValue > 7 {
            smText = .passAAA
        } else if contrastRatioValue > 4.5 {
            smText = .passAA
        } else {
            smText = .fail
        }

        return ContrastComplianceResult(
            contrastRatio: contrastRatioValue,
            contrastRatioLabel: "\(contrastRatioValue):1",
            complianceLevelLgText: lgText,
            complianceLevelSmText: smText,
            complianceLevelGraphical: lgText
        )
    }

    static func pendingCompliance() -> ContrastComplianceResult {
        ContrastComplianceResult(
            contrastRatio: 0,
            contrastRatioLabel: "",
            complianceLevelLgText: .pending,
            complianceLevelSmText: .pending,
            complianceLevelGraphical: .pending
        )
    }

    static func calculateAccessibleForegroundColour(
        forBackground: Color,
        closestTo: Color
    ) -> Color {
        var lighterAcceptableColor = closestTo
        var darkerAcceptableColor = closestTo
        var contrastLighter = calculateContrastRatio(color1: forBackground, color2: lighterAcceptableColor)
        var contrastDarker = calculateContrastRatio(color1: forBackground, color2: darkerAcceptableColor)

        var iterations = 0
        while contrastLighter < 6 && contrastDarker < 6 && iterations < 20 {
            let previousContrastLighter = contrastLighter
            let previousContrastDarker = contrastDarker

            lighterAcceptableColor = lighterAcceptableColor.lighter(by: 10) ?? lighterAcceptableColor
            darkerAcceptableColor = darkerAcceptableColor.darker(by: 10) ?? darkerAcceptableColor
            contrastLighter = calculateContrastRatio(color1: forBackground, color2: lighterAcceptableColor)
            contrastDarker = calculateContrastRatio(color1: forBackground, color2: darkerAcceptableColor)

            if contrastLighter == previousContrastLighter && contrastDarker == previousContrastDarker {
                break
            }

            iterations += 1
        }

        if contrastLighter >= 6 {
            return lighterAcceptableColor
        }
        return darkerAcceptableColor
    }
}
