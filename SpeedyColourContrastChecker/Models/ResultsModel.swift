//
//  ResultModel.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 07/09/2022.
//

import SwiftUI
import Foundation

class ResultsModel: ObservableObject, Identifiable {
    init(color1: Color?, color2: Color?) {
        id = Int.random(in: 0..<10000)
        _color1 = color1
        _color2 = color2
        complianceLevelLgText = .pending
        complianceLevelSmText = .pending
        complianceLevelGraphical = .pending
        contrastRatio = nil
        recalculateCompliance()
    }
    
    var id: Int
    @Published var _color1: Color?
    var color1: Color? {
        set (newValue) {
           _color1 = newValue
            recalculateCompliance()
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
        }
        get {
            return _color2
        }
    }
    @Published var complianceLevelLgText: ComplianceLevel
    @Published var complianceLevelSmText: ComplianceLevel
    @Published var complianceLevelGraphical: ComplianceLevel
    @Published var contrastRatio: String?
    
    func recalculateCompliance() {
        // TODO: Implement actual colour contrast calculations
        if (color1 != nil && color2 != nil) {
            complianceLevelLgText = .passAAA
            complianceLevelSmText = .passAA
            complianceLevelGraphical = .fail
            contrastRatio = "21:1"
            return
        }
        complianceLevelLgText = .pending
        complianceLevelSmText = .pending
        complianceLevelGraphical = .pending
        contrastRatio = nil
    }
}
