//
//  ColourSwatch.swift
//  Contraster
//
//  Created by George Gillams on 02/09/2022.
//

import SwiftUI

struct ColourPreview: View {
    var color: Color?
    var foregroundColor: Color?

    var body: some View {
        ZStack {
            Rectangle().fill(color ?? Color.clear).frame(width: 70, height: 18, alignment: .leading)
            Text(color?.hexString ?? "…").background(.clear).foregroundColor(foregroundColor ?? Color.black)
        }.frame(width: 70, height: 18)
    }
}

struct ColourPreview_Previews: PreviewProvider {
    static var previews: some View {
        ColourPreview(foregroundColor: Color.black).frame(maxWidth: 100, alignment: .leading)
        ColourPreview(color: Color(red: 1, green: 0.2, blue: 0.2), foregroundColor: Color.black)
        ColourPreview(color: Color(red: 0.2, green: 0.2, blue: 0.8), foregroundColor: Color.white)
        ColourPreview(color: Color.purple, foregroundColor: Color.black)
    }
}


