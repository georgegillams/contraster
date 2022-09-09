//
//  Main.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 02/09/2022.
//

import SwiftUI

enum PickingMode {
    case notPicking
    case pickingFirstColor
    case pickingSecondColor
}

struct Main: View {
    var delegate: AppDelegate = NSApp.delegate as! AppDelegate
    @StateObject var appModel = AppModel()
    var mouseLocation: NSPoint { NSEvent.mouseLocation }
    
    @State var currentPage: Int = 0
    @State var pickingMode: PickingMode = .notPicking
    
    var body: some View {
        PagerView(pageCount: 1, currentIndex: $currentPage) {
            VStack(alignment: .center, spacing: 10) {
                Spacer()
                Button(pickingMode != .notPicking ? "Cancel pick" : "Pick", role: nil, action: {
                    if (pickingMode == .notPicking) {
                        pickingMode = .pickingFirstColor
                        appModel.createNewPick()
                    } else {
                        appModel.cancelPick()
                    }
                })
                Text(pickingMode != .notPicking ? "Picking colours..." : "Not picking")
                    .font(Font.system(size:24))
                    .padding(.bottom, 10)
                Text(pickingMode != .notPicking ? "Click anywhere on screen to select the next colour" : "...")
                    .padding(.bottom, 20)
                
                ScrollView() {
                    VStack(spacing: 40) {
                        ForEach(appModel.resultsList) { result in
                            ContrastResults(model: result)
                        }
                    }.padding(.bottom, 20)
                }
            }
//        }.onHover{over in
//            mouseOverPopup = over
        }
        .onAppear(perform: {
            NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
                if (pickingMode == .notPicking) {
                    return $0
                }
                if(mouseLocation.x <= 0 || mouseLocation.y <= 0) {
                    return $0
                }
                var rect = CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 1)
                var imageRef = CGDisplayCreateImage(CGMainDisplayID(), rect: rect)
                if imageRef == nil {
                    print("nil imageRef \(imageRef)")
                    return $0
                }
                var bitmapImageRef = NSBitmapImageRep(cgImage: imageRef!)
                var color = bitmapImageRef.colorAt(x: 0, y: 0)?.cgColor
                print("Color: \(color)")
                if (color == nil ) {
                    print("nil color \(color)")
                    return $0
                }
                if(pickingMode == .pickingFirstColor) {
                    appModel.updateFirstColor(color: Color(cgColor: color!))
                }else if (pickingMode == .pickingSecondColor) {
                    appModel.updateSecondColor(color: Color(cgColor: color!))
                }
                return $0
            }
            NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { event in
                if (pickingMode == .notPicking) {
                    return event
                }
                // TODO: prevent default. If not possible, then re-focus popover window
                if(event.type == .leftMouseUp) {
                    return event
                }
                if(pickingMode == .pickingFirstColor) {
                    pickingMode = .pickingSecondColor
                }else if(pickingMode == .pickingSecondColor) {
                    pickingMode = .notPicking
                }
                return event
            }
        })
        .frame(minWidth: 445, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}
