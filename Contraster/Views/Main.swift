//
//  Main.swift
//  Contraster
//
//  Created by George Gillams on 02/09/2022.
//

import SwiftUI

struct Main: View {
    var delegate: AppDelegate = NSApp.delegate as! AppDelegate
    @ObservedObject var appModel: AppModel
    
    init(appModel: AppModel) {
        self.appModel = appModel
    }
    
    @State var currentPage: Int = 0
    
    var body: some View {
        PagerView(pageCount: 1, currentIndex: $currentPage) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            
                            Text(appModel.pickingMode != .notPicking ? "Current pick" : "Not picking")
                                .font(Font.system(size:24))
                            Text(appModel.pickingMode != .notPicking ? "Click anywhere on screen to select the next colour" : "Click the picker button to get started")
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            GButton(role: nil, action: {
                                delegate.togglePopover(delegate.statusBarItem.button)
                                delegate.openMenu()
                            }) {
                                Image(systemName: "gear").foregroundColor(Color.white).font(.system(size: 18))

                            }.bgColor(Color(hex: "#5E5E5E")!).accessibilityLabel("Open menu")
                            
                            
                            GButton(role: nil, action: {
                                if (appModel.pickingMode == .notPicking) {
                                    appModel.createNewPick()
                                    delegate.updateMouseTrapWindow()
                                } else {
                                    appModel.cancelPick()
                                    delegate.updateMouseTrapWindow()
                                }
                            }) {
                                Image(systemName: "eyedropper.halffull").foregroundColor(Color.white)
                                Text(appModel.pickingMode == .notPicking ? "New pick" : "Cancel").foregroundColor(Color.white)
                            }.bgColor(appModel.pickingMode == .notPicking ? Color("CTABackgroundColor") : Color("DangerColor"))
                        }
                    }.frame( alignment: .center)

                    ContrastResultsAnimated(model: appModel.currentResult, onDelete: nil)
                    Line()
                    ScrollView() {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("History")
                                .font(Font.system(size:24))
                                .padding(.bottom, 4)
                            if (appModel.resultsList.isEmpty) {
                                Text("No results yet!").frame(maxWidth: .infinity)
                                Text("Once you start picking colours, they'll show up here.").frame(maxWidth: .infinity)
                            }
                            ForEach(appModel.resultsList) { result in
                                ContrastResultsAnimated(model: result, onDelete: {
                                    appModel.deleteColourPair(pickId: result.pickId)
                                })
                            }
                        }.frame(maxWidth: .infinity)
                    }
                }.padding(EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 12))
                
            }
        }
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}


struct Main_Previews: PreviewProvider {
    static var exampleAppModel: AppModel {
        get {
            let exampleAppModel = AppModel()
            exampleAppModel.updateFirstColor(color: Color.red)
            exampleAppModel.captureFirstColor()
            exampleAppModel.currentPickerColor = Color.blue
            return exampleAppModel
        }
    }
    
    static var previews: some View {
        Main(appModel: exampleAppModel)
    }
}

