//
//  ContrastResult.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 03/09/2022.
//

import SwiftUI

struct ContrastResults: View {
    var color1: Color?
    var color2: Color?
    
    var body: some View {
        HStack {
            VStack {
                ColourPreview(color: color1).frame(maxWidth: .infinity, alignment: .leading)
                ColourPreview(color: color2).frame(maxWidth: .infinity, alignment: .leading)
            }.frame(width: 100)
            Spacer().frame(width: 16)
            ContrastResult(elementType: .largeText, level: .pending).frame(width: 55, alignment: .leading)
            Spacer().frame(width: 16)
            ContrastResult(elementType: .smallText, level: .pending).frame(width: 55, alignment: .leading)
            Spacer().frame(width: 16)
            ContrastResult(elementType: .graphical, level: .pending).frame(width: 55, alignment: .leading)
        }
    }
}

struct ContrastResults_Previews: PreviewProvider {
    static var previews: some View {
        ContrastResults()
        ContrastResults(color1: Color(red: 1, green: 0.2, blue: 0.2), color2: nil)
        ContrastResults(color1: Color(red: 1, green: 0.2, blue: 0.2), color2: Color(red: 0.2, green: 0.2, blue: 0.8))
    }
}
