//
//  MouseTrap.swift
//  Contraster
//
//  Created by George Gillams on 22/09/2022.
//

import SwiftUI

struct MouseTrap: View {
    @ObservedObject var appModel: AppModel
    
    init(appModel: AppModel) {
        self.appModel = appModel
    }

    var body: some View {
        ZStack {
            if(appModel.pickingMode != .notPicking) {
                Rectangle().fill(Color(cgColor: CGColor(red: 1, green: 1, blue: 1, alpha: 0))).frame(width: 50, height: 50)
                // Comment MT_21
                // We show a 1x1 rectangle at the center of this view so that the user mouse click is registered.
                // Making this transparentcauses the click event to be ignored, so it must be the current picker colour, or almost completely invisible.
                // See Comment AD+F_102
                Rectangle().fill(appModel.currentPickerColor ?? Color(cgColor: CGColor(red: 1, green: 1, blue: 1, alpha: 0.01))).frame(width: 2, height: 2)
                Circle()
                    .stroke(.black, lineWidth: 20).frame(width: 30, height: 30)
                Circle()
                    .stroke(.white, lineWidth: 18.6).frame(width: 28.6, height: 28.6)
                Circle()
                    .stroke(appModel.currentPickerColor ?? .clear, lineWidth: 17.2).frame(width: 27.2, height: 27.2)
                if (appModel.currentResult?.color1Captured == true) {
                    Circle().trim(from: 0.5, to: 1.0)
                        .stroke(appModel.currentResult?.color1 ?? .pink, lineWidth: 17.2).frame(width: 27.2, height: 27.2)
                }
            }
        }
    }
}

struct MouseTrap_Previews: PreviewProvider {
    static var exampleAppModel1: AppModel {
        get {
            let appModel = AppModel()
            appModel.createNewPick()
            appModel.updateFirstColor(color: Color.blue)
            return appModel
        }
    }
    
    static var exampleAppModel2: AppModel {
        get {
            let appModel = AppModel()
            appModel.createNewPick()
            appModel.updateFirstColor(color: Color.blue)
            appModel.captureFirstColor()
            appModel.updateSecondColor(color: Color.red)
            return appModel
        }
    }
    
    static var previews: some View {
        MouseTrap(appModel: exampleAppModel1)
        MouseTrap(appModel: exampleAppModel2)
    }
}
