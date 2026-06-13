//
//  ContrastResultsAnimated.swift
//  Contraster
//
//  Created by George Gillams on 22/09/2022.
//

import SwiftUI

private extension AnyTransition {
    static var currentPickCard: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: -10)),
            removal: .opacity
        )
    }
}

struct ContrastResultsAnimated: View {
    var model: ResultsModel?

    var body: some View {
        Group {
            if let model {
                ContrastResults(model: model, onDelete: nil)
                    .padding(.vertical, InterfaceConstants.popoverCardShadowPadding)
                    .transition(.currentPickCard)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.28), value: model?.pickId)
    }
}

struct ContrastResultsAnimated_Previews: PreviewProvider {
    struct PreviewContainer: View {
        @State private var model: ResultsModel? = nil

        var body: some View {
            VStack(spacing: 16) {
                ContrastResultsAnimated(model: model)
                Button(model == nil ? "Show card" : "Hide card") {
                    if model == nil {
                        model = ResultsModel(color1: Color.red, color2: Color.blue)
                    } else {
                        model = nil
                    }
                }
            }
            .padding()
            .frame(width: 500)
        }
    }

    static var previews: some View {
        PreviewContainer()
    }
}
