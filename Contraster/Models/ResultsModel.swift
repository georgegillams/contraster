//
//  ResultModel.swift
//  Contraster
//
//  Created by George Gillams on 07/09/2022.
//

import SwiftUI
import Foundation

class ResultsModel: ObservableObject, Identifiable {
    convenience init(color1: Color?, color2: Color?) {
        self.init(pickId: nil, color1: color1, color2: color2)
    }
    
    init(pickId: String?, color1: Color?, color2: Color?) {
        if let givenPickId = pickId {
            self.pickId = givenPickId
        } else {
            self.pickId = "\(Int.random(in: 0..<10000))"
        }
        _color1 = color1
        _color2 = color2
        complianceLevelLgText = .pending
        complianceLevelSmText = .pending
        complianceLevelGraphical = .pending
        contrastRatio = nil
        recalculateCompliance()
        recalculateForegroundColors()
    }
    
    var pickId: String
    @Published var _color1: Color?
    var color1: Color? {
        set (newValue) {
            _color1 = newValue
            recalculateCompliance()
            recalculateForegroundColors()
        }
        get {
            return _color1
        }
    }
    @Published var _color2: Color?
    var color2: Color? {
        set (newValue) {
            _color2 = newValue
            recalculateCompliance()
            recalculateForegroundColors()
        }
        get {
            return _color2
        }
    }
    @Published var color1Foreground: Color?
    @Published var color2Foreground: Color?
    @Published var color1Captured = false
    @Published var color2Captured = false
    @Published var complianceLevelLgText: ComplianceLevel
    @Published var complianceLevelSmText: ComplianceLevel
    @Published var complianceLevelGraphical: ComplianceLevel
    @Published var contrastRatio: String?
    
    func calculateComponent(sRGB: CGFloat) -> CGFloat {
        // if GsRGB <= 0.03928 then G = GsRGB/12.92 else G = ((GsRGB+0.055)/1.055) ^ 2.4
        if (sRGB < 0.03928) {
            return sRGB/12.92
        }
        return pow((sRGB + 0.055)/1.055, 2.4)
    }
    
    func calculateLuminance(color: Color) -> CGFloat {
        // L = 0.2126 * R + 0.7152 * G + 0.0722 * B
        let components = color.cgColor?.components
        let componentR = calculateComponent(sRGB: components?[0] ?? 0)
        let componentG = calculateComponent(sRGB: components?[1] ?? 0)
        let componentB = calculateComponent(sRGB: components?[2] ?? 0)
        
        return 0.2126 * componentR + 0.7152 * componentG + 0.0722 * componentB
    }

    func calculateContrastRatio(color1: Color, color2: Color) -> Double {
        let luminance1 = calculateLuminance(color: color1)
        let luminance2 = calculateLuminance(color: color2)
        let luminanceHigh = max(luminance1, luminance2)
        let luminanceLow = min(luminance1, luminance2)
        let contrastRatioValueUnrounded = (luminanceHigh + 0.05) / (luminanceLow + 0.05)
        let contrastRatioValue = Double(round(100 * contrastRatioValueUnrounded)/100)
        return contrastRatioValue
    }
    
    func recalculateCompliance() {
        if (color1 != nil && color2 != nil) {
            let contrastRatioValue = calculateContrastRatio(color1:color1!, color2:color2!)
            
            // large text and graphical
            if(contrastRatioValue > 4.5) {
                complianceLevelLgText = .passAAA
            } else if(contrastRatioValue > 3) {
                complianceLevelLgText = .passAA
            } else {
                complianceLevelLgText = .fail
            }
            
            // small text
            if(contrastRatioValue > 7) {
                complianceLevelSmText = .passAAA
            } else if(contrastRatioValue > 4.5) {
                complianceLevelSmText = .passAA
            } else {
                complianceLevelSmText = .fail
            }
            
            // graphical elements
            complianceLevelGraphical = complianceLevelLgText
            
            contrastRatio = "\(contrastRatioValue):1"
            return
        }
        complianceLevelLgText = .pending
        complianceLevelSmText = .pending
        complianceLevelGraphical = .pending
        contrastRatio = nil
    }

    func recalculateForegroundColors() {
        if(color1 != nil){
            color1Foreground = calculateAccessibleForegroundColour(forBackground: color1!, closestTo:color2 ?? Color.gray)
        } else {
            color2Foreground = Color.black
        }
        if(color2 != nil){
            color2Foreground = calculateAccessibleForegroundColour(forBackground: color2!, closestTo:color1 ?? Color.gray)
        } else {
            color2Foreground = Color.black
        }
    }

    func calculateAccessibleForegroundColour(forBackground: Color, closestTo: Color) -> Color {
        var lighterAcceptableColor = closestTo
        var darkerAcceptableColor = closestTo
        var contrastLighter = calculateContrastRatio(color1: forBackground, color2: lighterAcceptableColor)
        var contrastDarker = calculateContrastRatio(color1: forBackground, color2: darkerAcceptableColor)
        while(contrastLighter < 6 && contrastDarker < 6) {
            lighterAcceptableColor = lighterAcceptableColor.lighter(by:10)!
            darkerAcceptableColor = darkerAcceptableColor.darker(by:10)!
            contrastLighter = calculateContrastRatio(color1: forBackground, color2: lighterAcceptableColor)
            contrastDarker = calculateContrastRatio(color1: forBackground, color2: darkerAcceptableColor)
        }

        if(contrastLighter>=6){
            return lighterAcceptableColor
        }
        return darkerAcceptableColor

    }

}
