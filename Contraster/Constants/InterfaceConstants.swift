//
//  Interface.swift
//  Contraster
//
//  Created by George Gillams on 22/09/2022.
//

import Foundation
import SwiftUI

class InterfaceConstants {
    static let popoverWidth: CGFloat = 500
    static let popoverMaxHeight: CGFloat = 420
    static let popoverMinHeight: CGFloat = 260
    static let popoverHistoryMaxHeight: CGFloat = 240
    static let popoverCardShadowRadius: CGFloat = 3
    static let popoverCardShadowPadding: CGFloat = 3
    static let popoverPickingExtraTopPadding: CGFloat = 18
    static let popoverPickingSectionBottomPadding: CGFloat = 16
    static let popoverTitleFont = Font.system(size: 17, weight: .semibold)
    static let popoverBodyFont = Font.system(size: 14)
    static let popoverSecondaryFont = Font.system(size: 13)
    static let popoverResultFont = Font.system(size: 14)
    static let popoverSwatchFont = Font.system(size: 12, design: .monospaced)
    static let popoverSwatchRowHeight: CGFloat = 22
    static let popoverSwatchWidth: CGFloat = 76
    static let mouseTrapRectSize = NSSize(width: 50, height: 50)
    static let magnificationWidth: CGFloat = 300
    static let magnificationHeight: CGFloat = 200
    static let minMagnificationScale: CGFloat = 1
    static let maxMagnificationScale: CGFloat = 10
    static let defaultMagnificationScale: CGFloat = 3
    static let magnificationScrollThresholdPrecise: CGFloat = 24
    static let magnificationScrollThresholdDiscrete: CGFloat = 3
}
