//
//  ContrastResult.swift
//  Contraster
//
//  Created by George Gillams on 03/09/2022.
//

import SwiftUI

struct ContrastResults: View {
    @ObservedObject var model: ResultsModel
    @State var showControls = false
    var onDelete: (() -> Void)?
    
    init(model: ResultsModel, onDelete: (() -> Void)?) {
        self.model = model
        self.onDelete = onDelete
    }
    
    var body: some View {
        CardView {
            HStack(alignment: .center) {
                ZStack(alignment: .bottomTrailing) {
                    HStack {
                        VStack(spacing:0) {
                            ColourPreview(color: model.color1, foregroundColor: model.color1Foreground)
                            ColourPreview(color: model.color2, foregroundColor: model.color2Foreground)
                        }.frame(width: 70).cornerRadius(4)
                        Spacer().frame(width: 18, height: 28)
                        HStack {
                            Text(model.contrastRatio ?? "…").lineLimit(1).layoutPriority(1)
                            Spacer().frame(width: .infinity)
                        }.frame(width: 62, alignment: .leading)
                        HStack {
                            ContrastResult(elementType: .largeText, level: model.complianceLevelLgText).frame(alignment: .leading).layoutPriority(1)
                            Spacer().frame(maxWidth: .infinity)
                        }.frame(width: 82, alignment: .leading)
                        HStack {
                            ContrastResult(elementType: .smallText, level: model.complianceLevelSmText).frame(alignment: .leading).layoutPriority(1)
                            Spacer().frame(maxWidth: .infinity)
                        }.frame(width: 82, alignment: .leading)
                        ContrastResult(elementType: .graphical, level: model.complianceLevelGraphical).frame(width: 58, alignment: .leading)
                        if let deleteFunction = onDelete {

                            HStack {
                                Button(role: nil, action: {
                                    deleteFunction()
                                }) {
                                    Image(systemName: "trash").foregroundColor(Color("DangerColor"))
                                }.buttonStyle(.plain)
                            }.padding(.trailing, 4)
                        }
                    }
                    //            HStack {
                    //                Text(model.pickId).font(.footnote).foregroundColor(.secondary)
                    //                Text("21/09/2022").font(.footnote).foregroundColor(.secondary).opacity(showControls ? 1 : 0)
                    //            }
                }
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity)
        }.onHover(perform: {isMouseOver in
            showControls = isMouseOver
        })
    }
}

struct ContrastResults_Previews: PreviewProvider {
    static let exampleData = [
        ResultsModel(color1: nil, color2: nil),
        ResultsModel(color1: Color(red: 1, green: 0.2, blue: 0.2), color2: nil),
        ResultsModel(color1: Color(red: 1, green: 0.2, blue: 0.2), color2: Color(red: 0.2, green: 0.2, blue: 0.8))
    ]
    
    static var previews: some View {
        ContrastResults(model: exampleData[0], onDelete: {
            print("Delete")
        })
        ContrastResults(model: exampleData[1], onDelete: {
            print("Delete")
        })
        ContrastResults(model: exampleData[2], onDelete: {
            print("Delete")
        })
    }
}
