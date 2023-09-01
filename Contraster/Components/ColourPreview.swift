//
//  ColourSwatch.swift
//  Contraster
//
//  Created by George Gillams on 02/09/2022.
//

import SwiftUI

struct ColourPreview: View {
    var color: Color?
    
    var body: some View {
        HStack {
            Rectangle().fill(color ?? Color.clear).frame(width: 18, height: 18, alignment: .leading).cornerRadius(4).overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color != nil ? .clear : .gray, lineWidth: 1.4)
            )
            Text(color?.hexString ?? "...")
        }
    }
}

struct ColourPreview_Previews: PreviewProvider {
    static var previews: some View {
        ColourPreview().frame(maxWidth: 100, alignment: .leading)
        ColourPreview(color: Color(red: 1, green: 0.2, blue: 0.2))
        ColourPreview(color: Color(red: 0.2, green: 0.2, blue: 0.8))
        ColourPreview(color: Color.purple)
    }
}


