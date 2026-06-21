//
//  MouseTrap.swift
//  Contraster
//

import SwiftUI
import AppKit

struct MouseTrap: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        if appModel.pickingMode != .notPicking {
            ZStack {
                Rectangle()
                    .fill(Color(cgColor: CGColor(red: 1, green: 1, blue: 1, alpha: 0)))
                    .frame(width: InterfaceConstants.magnificationWidth, height: InterfaceConstants.magnificationHeight)

                if let screenshot = appModel.currentScreenshot {
                    MagnificationView(
                        screenshot: screenshot,
                        screenFrame: appModel.currentScreenFrame,
                        mouseLocation: appModel.currentMouseLocation,
                        magnificationWidth: InterfaceConstants.magnificationWidth,
                        magnificationHeight: InterfaceConstants.magnificationHeight,
                        magnificationScale: appModel.magnificationScale
                    )
                    .id(ObjectIdentifier(screenshot))
                    .frame(width: InterfaceConstants.magnificationWidth, height: InterfaceConstants.magnificationHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }

                Circle()
                    .stroke(.black, lineWidth: 4)
                    .frame(width: 30, height: 30)
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 28.6, height: 28.6)
                Circle()
                    .stroke(appModel.currentResult?.color1 ?? .clear, lineWidth: 17.2)
                    .frame(width: 27.2, height: 27.2)
                if appModel.currentResult?.color1Captured == true {
                    Circle()
                        .trim(from: 0.5, to: 1.0)
                        .stroke(appModel.currentResult?.color2 ?? .clear, lineWidth: 17.2)
                        .frame(width: 27.2, height: 27.2)
                }
            }
        }
    }
}

struct MagnificationView: View {
    let screenshot: NSImage
    let screenFrame: NSRect
    let mouseLocation: NSPoint
    let magnificationWidth: CGFloat
    let magnificationHeight: CGFloat
    let magnificationScale: CGFloat

    @State private var renderedImage: NSImage?

    var body: some View {
        Group {
            if let renderedImage {
                Image(nsImage: renderedImage)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: magnificationWidth, height: magnificationHeight)
                    .clipped()
            } else {
                placeholder
            }
        }
        .onAppear { updateRenderedImage() }
        .onChange(of: magnificationScale) { _ in updateRenderedImage() }
        .onChange(of: mouseLocation.x) { _ in updateRenderedImage() }
        .onChange(of: mouseLocation.y) { _ in updateRenderedImage() }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: magnificationWidth, height: magnificationHeight)
    }

    private func updateRenderedImage() {
        renderedImage = MagnificationImageRenderer.render(
            screenshot: screenshot,
            screenFrame: screenFrame,
            mouseLocation: mouseLocation,
            magnificationWidth: magnificationWidth,
            magnificationHeight: magnificationHeight,
            magnificationScale: magnificationScale
        )
    }
}

struct MouseTrap_Previews: PreviewProvider {
    static var exampleAppModel1: AppModel {
        let appModel = AppModel()
        appModel.createNewPick()
        appModel.updatePreviewColor(.blue, slot: .first)
        return appModel
    }

    static var exampleAppModel2: AppModel {
        let appModel = AppModel()
        appModel.createNewPick()
        appModel.updatePreviewColor(.blue, slot: .first)
        appModel.captureFirstColor()
        appModel.updatePreviewColor(.red, slot: .second)
        return appModel
    }

    static var previews: some View {
        MouseTrap(appModel: exampleAppModel1)
        MouseTrap(appModel: exampleAppModel2)
    }
}
