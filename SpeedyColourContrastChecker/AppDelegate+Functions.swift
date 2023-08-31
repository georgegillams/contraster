//
//  AppDelegate+Functions.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 02/09/2022.
//

import Cocoa
import SwiftUI

extension AppDelegate {
    
    @objc func openAbout() {
        AboutWindowController.createWindow()
    }
    
    @objc func viewOnboarding() {
        showWelcomeTutorial()
    }
    
    @objc func openMenu() {
        let versionNsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject
        let version = versionNsObject as! String
        let menu = NSMenu()
        menu.addItem(withTitle: "About Speedy Colour Contrast Checker", action: #selector(openAbout), keyEquivalent: "")
        menu.addItem(withTitle: "Show welcome tutorial", action: #selector(viewOnboarding), keyEquivalent: "")
        menu.addItem(withTitle: "Send me feedback", action: #selector(openFeedback), keyEquivalent: "")
        menu.addItem(withTitle: "Buy me a coffee", action: #selector(openCoffee), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Speedy Colour Contrast Checker \(version)", action: nil, keyEquivalent: ""))
        menu.addItem(withTitle: "Quit Speedy Colour Contrast Checker", action: #selector(quit), keyEquivalent: "q")
        
        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
        statusBarItem.menu = nil
    }
    
    @objc func openFeedback() {
        if let url = URL(string: "https://www.georgegillams.co.uk/contact") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func openCoffee() {
        if let url = URL(string: "https://www.georgegillams.co.uk/coffee") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func quit() {
        NSApp.terminate(self)
    }
    
    @objc func updateMouseTrapWindow() {
        if (self.appModel.pickingMode == .notPicking) {
            removeMouseObserver()
            self.mouseTrapWindow.setFrame(NSRect(x: 0, y: 0, width: 0, height: 0), display: true, animate: false)
        } else {
            addMouseObserver()
        }
    }
    
    func removeMouseObserver() {
        if(mouseMoveMonitor != nil) {
            NSEvent.removeMonitor(mouseMoveMonitor!)
            mouseMoveMonitor = nil
        }
        if(mouseClickMonitor != nil) {
            NSEvent.removeMonitor(mouseClickMonitor!)
            mouseClickMonitor = nil
        }
    }
    
    func addMouseObserver() {
        // Play it safe and ensure no observers are active:
        removeMouseObserver()
        
        mouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
            // TODO: FIND MEMORY LEAK IN HERE
            
            // This shouldn't actually happen, as the monitor should be inactive when not picking.
            if (self.appModel.pickingMode == .notPicking) {
                return $0
            }
            
            var mouseLocation: NSPoint { NSEvent.mouseLocation }
            
            let mouseTrapFrame = NSRect(x: mouseLocation.x - InterfaceConstants.mouseTrapRectSize.width/2, y: mouseLocation.y - InterfaceConstants.mouseTrapRectSize.height/2, width: InterfaceConstants.mouseTrapRectSize.width, height: InterfaceConstants.mouseTrapRectSize.height)
            self.mouseTrapWindow.setFrame(mouseTrapFrame, display: true, animate: false)
            
            let currentScreen = ScreenHelper.getScreenWithMouse()
            let displayID = currentScreen?.displayID ?? CGMainDisplayID()
            let screenHeight = currentScreen?.frame.size.height
            
            if(self.pixelConverterWindow.frame != currentScreen?.frame) {
                self.pixelConverterWindow.setFrameOrigin(currentScreen!.frame.origin)
                self.pixelConverterWindow.setContentSize(currentScreen!.frame.size)
            }
            
            let mousePositionWithinScreen = self.pixelConverterWindow.convertPoint(fromScreen: mouseLocation)
            let mousePositionWithinScreenInvertedY = (screenHeight ?? 0) - mousePositionWithinScreen.y
            // Comment AD+F_102
            // We read the pixel that is 2 pixels away from the mouse cursor. This is to avoid reading the value of the MouseTrap UI, and ensure we instead read the colour that is just left of the mouse
            // See Comment MT_21 for more information
            let colourPickingPixelFrame = NSRect(x: max(0, mousePositionWithinScreen.x - 2), y: max(0, mousePositionWithinScreenInvertedY - 2), width: 1, height: 1)
            
            let imageRef = CGDisplayCreateImage(displayID, rect: colourPickingPixelFrame)
            if imageRef == nil {
                return $0
            }
            let bitmapImageRef = NSBitmapImageRep(cgImage: imageRef!)
            let color = bitmapImageRef.colorAt(x: 0, y: 0)?.cgColor
            if (color == nil ) {
                return $0
            }
            if(self.appModel.pickingMode == .pickingFirstColor) {
                self.appModel.updateFirstColor(color: Color(cgColor: color!))
            }else if ( self.appModel.pickingMode == .pickingSecondColor) {
                self.appModel.updateSecondColor(color: Color(cgColor: color!))
            }
            return $0
        }
        
        
        mouseClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { event in
            // This shouldn't actually happen, as the monitor should be inactive when not picking.
            if (self.appModel.pickingMode == .notPicking) {
                return event
            }
            if(event.type == .leftMouseUp) {
                return event
            }
            
            if(self.appModel.pickingMode == .pickingFirstColor) {
                self.appModel.captureFirstColor()
            } else if(self.appModel.pickingMode == .pickingSecondColor) {
                self.appModel.captureSecondColor()
            }
            
            self.updateMouseTrapWindow()
            
            return event
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        let event = NSApp.currentEvent!
        
        if event.type == NSEvent.EventType.leftMouseUp {
            
            if let sbutton = statusBarItem.button {
                
                // find the coordinates of the statusBarItem in screen space
                let buttonRect: NSRect = sbutton.convert(sbutton.bounds, to: nil)
                let screenRect: NSRect = sbutton.window!.convertToScreen(buttonRect)
                
                // calculate the bottom center position (10 is the half of the window width)
                let posX = screenRect.origin.x + (screenRect.width / 2) - 10
                let posY = screenRect.origin.y
                
                colourPickerWindow.setFrame(NSRect(x: posX, y: posY, width: 20, height: 5), display: true,animate: false)
                updateMouseTrapWindow()
                
                if popover.isShown {
                    popover.performClose(sender)
                    self.appModel.cancelPick()
                    updateMouseTrapWindow()
                } else {
                    colourPickerWindow.makeKeyAndOrderFront(self)
                    NSApplication.shared.presentationOptions = []
                    NSApp.activate(ignoringOtherApps: true)
                    popover.show(relativeTo: colourPickerWindow.contentView!.frame, of: colourPickerWindow.contentView!, preferredEdge: NSRectEdge.minY)
                }
            }
        } else if event.type == NSEvent.EventType.rightMouseUp {
            openMenu()
        }
    }
}
