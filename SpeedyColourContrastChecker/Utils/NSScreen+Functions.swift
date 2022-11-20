//
//  NSScreen+Functions.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 16/09/2022.
//

import SwiftUI

extension NSScreen {
  var displayID: CGDirectDisplayID {
      let x = deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] ?? nil
      if(x == nil) {
          return 0
      }
      return x as? CGDirectDisplayID ?? 0
  }
}
