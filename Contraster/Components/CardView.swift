//
//  CardView.swift
//  Contraster
//
//  Created by George Gillams on 26/09/2022.
//

import SwiftUI

struct CardView<Content> : View where Content : View {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack {
            content()
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .shadow(
            color: Color(nsColor: .shadowColor).opacity(0.22),
            radius: InterfaceConstants.popoverCardShadowRadius,
            x: 0,
            y: 1
        )
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView {
            HStack {
                Text("Something")
            }
        }
        .padding(8)
    }
}
