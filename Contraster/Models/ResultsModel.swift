//
//  ResultsModel.swift
//  Contraster
//

import SwiftUI

enum PickingColorSlot {
    case first
    case second
}

class ResultsModel: ObservableObject, Identifiable {
    var id: String { pickId }

    convenience init(color1: Color?, color2: Color?) {
        self.init(pickId: nil, color1: color1, color2: color2)
    }

    init(pickId: String?, color1: Color?, color2: Color?) {
        self.pickId = pickId ?? UUID().uuidString
        _color1 = color1
        _color2 = color2
        complianceLevelLgText = .pending
        complianceLevelSmText = .pending
        complianceLevelGraphical = .pending
        contrastRatio = nil
        commitCalculations()
    }

    let pickId: String
    @Published var _color1: Color?
    var color1: Color? {
        get { _color1 }
        set {
            _color1 = newValue
            commitCalculations()
        }
    }

    @Published var _color2: Color?
    var color2: Color? {
        get { _color2 }
        set {
            _color2 = newValue
            commitCalculations()
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

    func setPreviewColor(_ color: Color, slot: PickingColorSlot) {
        switch slot {
        case .first:
            _color1 = color
        case .second:
            _color2 = color
        }
    }

    func commitCalculations() {
        recalculateCompliance()
        recalculateForegroundColors()
    }

    func recalculateCompliance() {
        guard let color1, let color2 else {
            complianceLevelLgText = .pending
            complianceLevelSmText = .pending
            complianceLevelGraphical = .pending
            contrastRatio = nil
            return
        }

        let result = ContrastCalculator.compliance(
            for: ContrastCalculator.calculateContrastRatio(color1: color1, color2: color2)
        )
        complianceLevelLgText = result.complianceLevelLgText
        complianceLevelSmText = result.complianceLevelSmText
        complianceLevelGraphical = result.complianceLevelGraphical
        contrastRatio = result.contrastRatioLabel
    }

    func recalculateForegroundColors() {
        if let color1 {
            color1Foreground = ContrastCalculator.calculateAccessibleForegroundColour(
                forBackground: color1,
                closestTo: color2 ?? Color(white: 0.5)
            )
        } else {
            color1Foreground = Color.black
        }

        if let color2 {
            color2Foreground = ContrastCalculator.calculateAccessibleForegroundColour(
                forBackground: color2,
                closestTo: color1 ?? Color(white: 0.5)
            )
        } else {
            color2Foreground = Color.black
        }
    }
}
