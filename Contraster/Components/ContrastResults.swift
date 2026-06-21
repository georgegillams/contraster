//
//  ContrastResults.swift
//  Contraster
//

import SwiftUI

struct ContrastResults: View {
    @ObservedObject var model: ResultsModel
    var onDelete: (() -> Void)?

    init(model: ResultsModel, onDelete: (() -> Void)?) {
        self.model = model
        self.onDelete = onDelete
    }

    var body: some View {
        CardView {
            HStack(alignment: .center, spacing: 0) {
                ContrastSwatches(model: model)
                Spacer().frame(width: 18)
                ContrastRatioLabel(ratio: model.contrastRatio)
                ComplianceBadgesRow(model: model)
                if let onDelete {
                    DeleteButton(action: onDelete)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ContrastSwatches: View {
    @ObservedObject var model: ResultsModel

    var body: some View {
        VStack(spacing: 0) {
            ColourPreview(color: model.color1, foregroundColor: model.color1Foreground)
            ColourPreview(color: model.color2, foregroundColor: model.color2Foreground)
        }
        .frame(width: InterfaceConstants.popoverSwatchWidth)
        .cornerRadius(4)
    }
}

private struct ContrastRatioLabel: View {
    let ratio: String?

    var body: some View {
        Text(ratio ?? "…")
            .font(InterfaceConstants.popoverResultFont)
            .monospacedDigit()
            .lineLimit(1)
            .frame(width: 68, alignment: .leading)
    }
}

private struct ComplianceBadgesRow: View {
    @ObservedObject var model: ResultsModel

    var body: some View {
        HStack(spacing: 0) {
            ContrastResult(elementType: .largeText, level: model.complianceLevelLgText)
                .frame(width: 82, alignment: .leading)
            ContrastResult(elementType: .smallText, level: model.complianceLevelSmText)
                .frame(width: 82, alignment: .leading)
            ContrastResult(elementType: .graphical, level: model.complianceLevelGraphical)
                .frame(width: 58, alignment: .leading)
        }
    }
}

private struct DeleteButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: nil, action: action) {
            Image(systemName: "trash")
                .font(InterfaceConstants.popoverBodyFont)
                .foregroundColor(Color("DangerColor"))
        }
        .buttonStyle(.plain)
        .padding(.trailing, 4)
    }
}

struct ContrastResults_Previews: PreviewProvider {
    static let exampleData = [
        ResultsModel(color1: nil, color2: nil),
        ResultsModel(color1: Color(red: 1, green: 0.2, blue: 0.2), color2: nil),
        ResultsModel(color1: Color(red: 1, green: 0.2, blue: 0.2), color2: Color(red: 0.2, green: 0.2, blue: 0.8))
    ]

    static var previews: some View {
        ContrastResults(model: exampleData[0], onDelete: { print("Delete") })
        ContrastResults(model: exampleData[1], onDelete: { print("Delete") })
        ContrastResults(model: exampleData[2], onDelete: { print("Delete") })
    }
}
