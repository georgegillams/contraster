//
//  ContrastResult.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 03/09/2022.
//

import SwiftUI

enum ElementType {
    case largeText
    case smallText
    case graphical
}

enum ComplianceLevel {
    case passAAA
    case passAA
    case fail
    case pending
}

class ContrastResultHelpers {
    static func textForElementType(elementType: ElementType) -> String {
        switch elementType {
        case .largeText:
            return "Lg:"
        case .smallText:
            return "Sm:"
        case .graphical:
            return "☂️"
        }
    }
    
    static func textForComplianceLevel(complianceLevel: ComplianceLevel) -> String {
        switch complianceLevel {
        case .passAAA:
            return "AAA"
        case .passAA:
            return "AA"
        case .fail:
            return "❌"
        case .pending:
            return "..."
        }
    }
    
    static func colorForComplianceLevel(complianceLevel: ComplianceLevel) -> Color {
        switch complianceLevel {
        case .passAAA:
            return Color.green
        case .passAA:
            return Color.green
        case .fail:
            return Color.red
        case .pending:
            return Color.primary
        }
    }
}


struct ContrastResult: View {
    var elementType: ElementType
    var level: ComplianceLevel
    
    var body: some View {
        HStack {
            Text(ContrastResultHelpers.textForElementType(elementType: elementType))
            Text(ContrastResultHelpers.textForComplianceLevel(complianceLevel: level)).foregroundColor(ContrastResultHelpers.colorForComplianceLevel(complianceLevel: level))
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


