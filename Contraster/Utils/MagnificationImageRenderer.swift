//
//  MagnificationImageRenderer.swift
//  Contraster
//

import AppKit
import SwiftUI

enum MagnificationImageRenderer {
    static func render(
        screenshot: NSImage,
        screenFrame: NSRect,
        mouseLocation: NSPoint,
        magnificationWidth: CGFloat,
        magnificationHeight: CGFloat,
        magnificationScale: CGFloat
    ) -> NSImage? {
        guard let cgImage = screenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let sourceRegion = sourceRegion(
            cgImage: cgImage,
            screenFrame: screenFrame,
            mouseLocation: mouseLocation,
            magnificationWidth: magnificationWidth,
            magnificationHeight: magnificationHeight,
            magnificationScale: magnificationScale
        )

        guard let croppedImage = cropAndScaleImage(
            cgImage: cgImage,
            sourceRect: sourceRegion,
            targetSize: CGSize(width: magnificationWidth, height: magnificationHeight)
        ) else {
            return nil
        }

        return NSImage(
            cgImage: croppedImage,
            size: NSSize(width: magnificationWidth, height: magnificationHeight)
        )
    }

    private static func sourceRegion(
        cgImage: CGImage,
        screenFrame: NSRect,
        mouseLocation: NSPoint,
        magnificationWidth: CGFloat,
        magnificationHeight: CGFloat,
        magnificationScale: CGFloat
    ) -> CGRect {
        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)
        let pixelScale = pixelWidth / screenFrame.width

        let imagePoint = ScreenCoordinateMapper.imagePoint(
            for: mouseLocation,
            screenFrame: screenFrame,
            pixelSize: CGSize(width: pixelWidth, height: pixelHeight)
        )

        let sourceWidth = (magnificationWidth / magnificationScale) * pixelScale
        let sourceHeight = (magnificationHeight / magnificationScale) * pixelScale

        let sourceX = max(0, min(pixelWidth - sourceWidth, imagePoint.x - sourceWidth / 2))
        let sourceY = max(0, min(pixelHeight - sourceHeight, imagePoint.y - sourceHeight / 2))

        return CGRect(x: sourceX, y: sourceY, width: sourceWidth, height: sourceHeight)
    }

    private static func cropAndScaleImage(
        cgImage: CGImage,
        sourceRect: CGRect,
        targetSize: CGSize
    ) -> CGImage? {
        guard let croppedImage = cgImage.cropping(to: sourceRect) else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .none
        context.draw(croppedImage, in: CGRect(origin: .zero, size: targetSize))
        return context.makeImage()
    }
}
