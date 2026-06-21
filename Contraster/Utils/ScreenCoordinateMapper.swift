//
//  ScreenCoordinateMapper.swift
//  Contraster
//

import AppKit

enum ScreenCoordinateMapper {
    /// Converts a screen-space point to pixel coordinates within a screenshot image.
    static func imagePoint(
        for screenPoint: NSPoint,
        screenFrame: NSRect,
        pixelSize: CGSize
    ) -> CGPoint {
        let relativeX = screenPoint.x - screenFrame.origin.x
        let relativeY = screenPoint.y - screenFrame.origin.y
        let imageY = screenFrame.height - relativeY

        let imagePointX = (relativeX / screenFrame.width) * pixelSize.width
        let imagePointY = (imageY / screenFrame.height) * pixelSize.height

        return CGPoint(x: imagePointX, y: imagePointY)
    }

    static func isPointInBounds(_ point: CGPoint, pixelSize: CGSize) -> Bool {
        point.x >= 0 && point.x < pixelSize.width &&
        point.y >= 0 && point.y < pixelSize.height
    }
}
