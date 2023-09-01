//
//  ScreenHelper.swift
//  Contraster
//
//  Created by George Gillams on 16/09/2022.
//

import SwiftUI

class ScreenHelper {
static func getScreenWithMouse() -> NSScreen? {
  let mouseLocation = NSEvent.mouseLocation
  let screens = NSScreen.screens
  let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })

  return screenWithMouse
}
}
