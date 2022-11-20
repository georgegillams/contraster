//
//  JoiningLine.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 05/09/2022.
//

import SwiftUI

class JoiningLineHelpers {
   static func getPath(size: CGSize) -> Path {
        let height = size.height
       let width = size.width
       
        var path = Path()
        path.move(to: CGPoint(x:0, y:0))
        path.addLine(to: CGPoint(x: width/4, y: 0))
        path.addCurve(to: CGPoint(x: 3*width/4, y: height/2), control1: CGPoint(x: width/2, y: 0), control2: CGPoint(x: width/2, y: height/2))
        path.addLine(to: CGPoint(x: width, y: height/2))
        path.addLine(to: CGPoint(x: 3*width/4, y: height/2))
        path.addCurve(to: CGPoint(x: width/4, y: height), control1: CGPoint(x: width/2, y: height/2), control2: CGPoint(x: width/2, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        return path
    }
}


struct JoiningLine: View {
    var body: some View {
        GeometryReader { geometryProxy in
            JoiningLineHelpers.getPath(size: geometryProxy.size).stroke(.gray, lineWidth: 1.0)
        }
    }
}

struct JoiningLine_Previews: PreviewProvider {
    static var previews: some View {
        JoiningLine()
    }
}
