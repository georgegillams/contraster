//
//  ColourSwatch.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 02/09/2022.
//

import SwiftUI

struct ColourPreview: View {
    var color: Color
    
    var body: some View {
        HStack {
            Rectangle().fill(color).frame(width: 18, height: 18, alignment: Alignment.leading).cornerRadius(4)
            Text(color.hexString)
        }
    }
}

struct ColourPreview_Previews: PreviewProvider {
    static var previews: some View {
        ColourPreview(color: Color(red: 1, green: 0.2, blue: 0.2))
        ColourPreview(color: Color(red: 0.2, green: 0.2, blue: 0.8))
        ColourPreview(color: Color.purple)
    }
}


