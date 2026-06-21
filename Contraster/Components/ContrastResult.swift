//
//  ContrastResult.swift
//  Contraster
//

import SwiftUI

enum ContrastResultHelpers {
    static func textForElementType(elementType: ElementType) -> String {
        switch elementType {
        case .largeText:
            return "Lg"
        case .smallText:
            return "Sm"
        case .graphical:
            return "Gfx"
        }
    }

    static func textForComplianceLevel(complianceLevel: ComplianceLevel) -> String {
        switch complianceLevel {
        case .passAAA:
            return "AAA"
        case .passAA:
            return "AA"
        case .fail:
            return "Fail"
        case .pending:
            return "…"
        }
    }

    static func colorForComplianceLevel(complianceLevel: ComplianceLevel) -> Color {
        switch complianceLevel {
        case .passAAA, .passAA:
            return Color("PositiveColor")
        case .fail:
            return Color("DangerColor")
        case .pending:
            return Color.primary
        }
    }
}

struct ContrastResult: View {
    var elementType: ElementType
    var level: ComplianceLevel

    var body: some View {
        HStack(spacing: 4) {
            if elementType == .graphical {
                Image(systemName: "theatermask.and.paintbrush")
                    .font(InterfaceConstants.popoverResultFont)
            } else {
                Text(ContrastResultHelpers.textForElementType(elementType: elementType))
                    .font(InterfaceConstants.popoverResultFont)
                    .lineLimit(1)
            }
            if level == .fail {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(InterfaceConstants.popoverResultFont)
                    .foregroundColor(ContrastResultHelpers.colorForComplianceLevel(complianceLevel: level))
            } else {
                Text(ContrastResultHelpers.textForComplianceLevel(complianceLevel: level))
                    .font(InterfaceConstants.popoverResultFont)
                    .foregroundColor(ContrastResultHelpers.colorForComplianceLevel(complianceLevel: level))
                    .fontWeight(.bold)
                    .lineLimit(1)
            }
        }
    }
}

struct ContrastResult_Previews: PreviewProvider {
    static var previews: some View {
        ContrastResult(elementType: .largeText, level: .pending)
        ContrastResult(elementType: .largeText, level: .passAAA)
        ContrastResult(elementType: .smallText, level: .passAA)
        ContrastResult(elementType: .graphical, level: .fail)
    }
}
