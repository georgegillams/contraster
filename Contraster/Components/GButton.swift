//
//  GButton.swift
//  Contraster
//

import SwiftUI

struct GButton<Label>: View where Label: View {
    var role: ButtonRole?
    var action: () -> Void
    var label: () -> Label
    var backgroundColor: Color

    init(
        role: ButtonRole?,
        backgroundColor: Color = Color.blue,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.role = role
        self.backgroundColor = backgroundColor
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(role: role, action: action) {
            HStack {
                label()
            }
            .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .frame(height: 34)
            .background(backgroundColor)
        }
        .buttonStyle(.plain)
        .frame(height: 34)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

struct GButton_Previews: PreviewProvider {
    static var previews: some View {
        GButton(role: nil, backgroundColor: .yellow, action: {
            print("Pressed")
        }) {
            Text("Button")
        }
    }
}
