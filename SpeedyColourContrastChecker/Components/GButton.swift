//
//  GButton.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 26/09/2022.
//

import SwiftUI



struct GButton<Label>: View where Label: View {
    var role: ButtonRole?
    var action: () -> Void
    var label: () -> Label
    @State var bgColor: Color = Color.blue
    
    init(role: ButtonRole?, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.role = role
        self.action = action
        self.label = label
    }
    
    public func bgColor(_ color: Color) -> some View {
        var view = self
        view._bgColor = State(initialValue: color)
        return view.id(UUID())
    }
    
    var body: some View {
        Button(role: role, action: action) {
            HStack {
                label()
            }.padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)).frame(height: 34).background(bgColor)
        }.buttonStyle(.plain).frame(height: 34).background(bgColor).cornerRadius(8)
    }
}

struct GButton_Previews: PreviewProvider {
    static var previews: some View {
        GButton(role: nil, action: {
            print("Pressed")
        }) {
            Text("Button")
        }.bgColor(Color.yellow)
    }
}
