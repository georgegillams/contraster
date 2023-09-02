//
//  GButton.swift
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
        HStack{
            content()
        }.padding(8).background(.background).cornerRadius(8)
//            .shadow(color: .primary, radius: 5, x: 2, y: 2)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView {
            HStack {
                Text("Something")
            }
        }
    }
}
