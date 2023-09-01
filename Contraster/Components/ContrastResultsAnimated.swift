//
//  ContrastResultsAnimated.swift
//  Contraster
//
//  Created by George Gillams on 22/09/2022.
//

import SwiftUI

struct ContrastResultsAnimated: View {
    var model: ResultsModel?
    var onDelete: (() -> Void)?
    @State var currentResultRenderHeight: CGFloat = 0
    var currentResultExpandedHeight: CGFloat = 50
    
    var body: some View {
        VStack{
            if model != nil {
                ContrastResults(model: model!, onDelete: onDelete).onAppear {
                    withAnimation(.linear(duration: 0.2), {currentResultRenderHeight = currentResultExpandedHeight})
                }.onDisappear {
                    withAnimation(.linear(duration: 0.2), {currentResultRenderHeight = 0})
                }
            }
        }.frame(height: currentResultRenderHeight).clipped()
    }
}

struct ContrastResultsAnimated_Previews: PreviewProvider {
    static let exampleData = [
        ResultsModel(color1: nil, color2: nil),
        ResultsModel(color1: Color(red: 1, green: 0.2, blue: 0.2), color2: nil),
        ResultsModel(color1: Color(red: 1, green: 0.2, blue: 0.2), color2: Color(red: 0.2, green: 0.2, blue: 0.8))
    ]
    
    static var previews: some View {
        ContrastResultsAnimated(model: nil, onDelete: {
            print("Delete")
        })
        ContrastResultsAnimated(model: exampleData[0], onDelete: {
            print("Delete")
        })
        ContrastResultsAnimated(model: exampleData[1], onDelete: {
            print("Delete")
        })
    }
}
