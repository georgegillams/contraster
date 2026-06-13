//
//  MouseTrap.swift
//  Contraster
//
//  Created by George Gillams on 22/09/2022.
//

import SwiftUI
import AppKit

struct MouseTrap: View {
    @ObservedObject var appModel: AppModel
    
    init(appModel: AppModel) {
        self.appModel = appModel
    }
    
    // Magnification region size
    private let magnificationScale: CGFloat = 3.0 // How much to zoom in
    
    var body: some View {
            if(appModel.pickingMode != .notPicking) {
                ZStack {
                    Rectangle().fill(Color(cgColor: CGColor(red: 1, green: 1, blue: 1, alpha: 0))).frame(width: InterfaceConstants.magnificationWidth, height: InterfaceConstants.magnificationHeight)

                // Magnification region
                if let screenshot = appModel.currentScreenshot {
                    MagnificationView(
                        screenshot: screenshot,
                        screenFrame: appModel.currentScreenFrame,
                        mouseLocation: appModel.currentMouseLocation,
                        magnificationWidth: InterfaceConstants.magnificationWidth,
                        magnificationHeight: InterfaceConstants.magnificationHeight,
                        magnificationScale: magnificationScale
                    )
                    .frame(width: InterfaceConstants.magnificationWidth, height: InterfaceConstants.magnificationHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }

                                // Circle indicators

                    // Comment MT_21
                    // We show a 1x1 rectangle at the center of this view so that the user mouse click is registered.
                    // Making this transparentcauses the click event to be ignored, so it must be the current picker colour, or almost completely invisible.
                    // See Comment AD+F_102
                    // Rectangle().fill(appModel.currentPickerColor ?? Color(cgColor: CGColor(red: 1, green: 1, blue: 1, alpha: 0.01))).frame(width: 2, height: 2)
                    Circle()
                        .stroke(.black, lineWidth: 4).frame(width: 30, height: 30)
                    Circle()
                        .stroke(.white, lineWidth: 4).frame(width: 28.6, height: 28.6)
                    Circle()
                        .stroke(appModel.currentResult?.color1 ?? .clear, lineWidth: 17.2).frame(width: 27.2, height: 27.2)
                    if (appModel.currentResult?.color1Captured == true) {
                        Circle().trim(from: 0.5, to: 1.0)
                            .stroke(appModel.currentResult?.color2 ?? .clear, lineWidth: 17.2).frame(width: 27.2, height: 27.2)
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
    
    var body: some View {
        GeometryReader { geometry in
            if let cgImage = screenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                // Calculate the region to magnify
                let sourceRegion = calculateSourceRegion(cgImage: cgImage)
                
                // Create a cropped and scaled image
                if let croppedImage = cropAndScaleImage(
                    cgImage: cgImage,
                    sourceRect: sourceRegion,
                    targetSize: CGSize(width: magnificationWidth, height: magnificationHeight)
                ) {
                    Image(nsImage: NSImage(cgImage: croppedImage, size: NSSize(width: magnificationWidth, height: magnificationHeight)))
                        .resizable()
                        .interpolation(.none) // Use nearest neighbor for pixel-perfect zoom
                        .aspectRatio(contentMode: .fill)
                        .frame(width: magnificationWidth, height: magnificationHeight)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: magnificationWidth, height: magnificationHeight)
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: magnificationWidth, height: magnificationHeight)
            }
        }
    }
    
    private func calculateSourceRegion(cgImage: CGImage) -> CGRect {
        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)
        let screenHeight = screenFrame.height
        let pixelScale = pixelWidth / screenFrame.width

        let relativeX = mouseLocation.x - screenFrame.origin.x
        let relativeY = mouseLocation.y - screenFrame.origin.y
        let imageY = screenHeight - relativeY

        let imagePointX = (relativeX / screenFrame.width) * pixelWidth
        let imagePointY = (imageY / screenFrame.height) * pixelHeight

        let sourceWidth = (magnificationWidth / magnificationScale) * pixelScale
        let sourceHeight = (magnificationHeight / magnificationScale) * pixelScale

        let sourceX = max(0, min(pixelWidth - sourceWidth, imagePointX - sourceWidth / 2))
        let sourceY = max(0, min(pixelHeight - sourceHeight, imagePointY - sourceHeight / 2))

        return CGRect(x: sourceX, y: sourceY, width: sourceWidth, height: sourceHeight)
    }
    
    private func cropAndScaleImage(cgImage: CGImage, sourceRect: CGRect, targetSize: CGSize) -> CGImage? {
        // Crop the image
        guard let croppedImage = cgImage.cropping(to: sourceRect) else {
            return nil
        }
        
        // Scale the cropped image to target size
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        guard let scaledContext = context else {
            return nil
        }
        
        scaledContext.interpolationQuality = .none // Nearest neighbor for pixel-perfect zoom
        scaledContext.draw(croppedImage, in: CGRect(origin: .zero, size: targetSize))
        
        return scaledContext.makeImage()
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
