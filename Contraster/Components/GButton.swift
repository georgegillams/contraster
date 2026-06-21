//
//  GButton.swift
//  Contraster
//

import SwiftUI

enum GButtonKind {
    case primary
    case secondary
    case destructive
}

enum GButtonSize {
    case regular
    case small

    var height: CGFloat {
        switch self {
        case .regular: 34
        case .small: 28
        }
    }

    var padding: EdgeInsets {
        switch self {
        case .regular:
            EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
        case .small:
            EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .regular: 12
        case .small: 10
        }
    }
}

struct GButton<Label>: View where Label: View {
    var kind: GButtonKind
    var size: GButtonSize
    var action: () -> Void
    var label: () -> Label

    private var backgroundColor: Color {
        switch kind {
        case .primary:
            Color("PrimaryColorDark")
        case .secondary:
            Color("SecondaryButtonBackgroundColor")
        case .destructive:
            Color("DangerColor")
        }
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary:
            Color("PrimaryButtonForegroundColor")
        case .secondary:
            Color("SecondaryButtonForegroundColor")
        case .destructive:
            Color("DestructiveButtonForegroundColor")
        }
    }

    init(
        kind: GButtonKind = .primary,
        size: GButtonSize = .regular,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.kind = kind
        self.size = size
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: size == .small ? 4 : 6) {
                label()
            }
            .padding(size.padding)
            .frame(height: size.height)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
        }
        .buttonStyle(.plain)
        .frame(height: size.height)
        .background(backgroundColor)
        .cornerRadius(size.cornerRadius)
    }
}

struct GButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            GButton(kind: .primary, action: {}) {
                Text("Primary")
            }
            GButton(kind: .secondary, action: {}) {
                Text("Secondary")
            }
            GButton(kind: .destructive, action: {}) {
                Text("Destructive")
            }
            GButton(kind: .primary, size: .small, action: {}) {
                Label("New pick", systemImage: "eyedropper.halffull")
            }
            GButton(kind: .destructive, size: .small, action: {}) {
                Label("Cancel", systemImage: "xmark")
            }
        }
        .padding()
    }
}
