//
//  CardView.swift
//  Contraster
//
//  Created by George Gillams on 26/09/2022.
//

import SwiftUI

struct CardView<Content> : View where Content : View {
    var content: () -> Content

    private let cornerRadius: CGFloat = 8

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack {
            content()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(nsColor: .shadowColor).opacity(0.05))
                .padding(-InterfaceConstants.popoverCardShadowSpread)
        }
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
