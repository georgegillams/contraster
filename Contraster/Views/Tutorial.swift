//
//  Tutorial.swift
//  Contraster
//
//  Created by George Gillams on 29/09/2022.
//

import SwiftUI

struct BackButton: View {
    var buttonAction: () -> Void
    
    var body: some View {
            GButton(role: nil, action: buttonAction) {
                Image(systemName: "arrow.left")
                Text("Back").foregroundColor(.white)
            }.bgColor(.gray)
    }
}

struct TutorialPart1: View {
    var forwardButtonAction: () -> Void
    var delegate: AppDelegate = NSApp.delegate as! AppDelegate
    
    @State private var hasPermissions: Bool = false
    @State private var permissionCheckTimer: Timer?
    
    var body: some View {
        HStack(spacing: 40){
            VStack(alignment: .leading, spacing: 10){
                if hasPermissions {
                    Text("Screen recording permission granted ✓")
                        .foregroundColor(.green)
                } else {
                    Text("Before you get started, you'll need to enable screen-recording permission.")
                }
                Text("This allows you to capture the colour from a single pixel on the screen. We don't do anything creepy with the image on your screen, and it will never leave your device.")
            }.frame(width: 300)
            Image("grant-permission-1")
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 200)
        }
        Spacer()
        HStack(spacing: 12) {
            if hasPermissions {
                GButton(role: nil, action: {
                    delegate.openScreenRecordingPreferences()
                }) {
                    Text("Manage permissions").foregroundColor(.white)
                }.bgColor(.gray)
                GButton(role: nil, action: forwardButtonAction) {
                    Text("Next").foregroundColor(.white)
                }
            } else {
                GButton(role: nil, action: {
                    delegate.checkScreenRecordingPermissions()
                }) {
                    Text("Grant permissions").foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Check permissions immediately
            checkPermissions()
            // Re-check permissions every 2 seconds
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                checkPermissions()
            }
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
        }
    }
    
    private func checkPermissions() {
        hasPermissions = delegate.hasScreenRecordingPermissions()
    }
}

struct TutorialPart2: View {
    var backButtonAction: () -> Void
    var forwardButtonAction: () -> Void
    
    var body: some View {
        HStack(spacing: 40){
            VStack(alignment: .leading, spacing: 10){
                Text("Click \"Open System Preferences\", then click the padlock.")
                Text("Next check the box next to \"Contraster\".")
            }.frame(width: 300)
            Image("grant-permission-2")
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 200)
        }
        Spacer()
        HStack() {
            BackButton(buttonAction: backButtonAction)
            Spacer()
            GButton(role: nil, action: forwardButtonAction) {
                Text("Done").foregroundColor(.white)
            }
            Spacer()
            BackButton(buttonAction: backButtonAction).opacity(0).accessibilityHidden(true)
        }.frame(maxWidth: .infinity)
    }
}

struct TutorialPart3: View {
    var backButtonAction: () -> Void
    var forwardButtonAction: () -> Void
    
    var body: some View {
        HStack(spacing: 40){
            VStack(alignment: .leading, spacing: 10){
                Text("Click on the eye-dropper in the menu bar to open the popover.")
                Text("Then click \"New Pick\", and then click twice anywhere on your screen.")
            }.frame(width: 300)
            Image("new-pick")
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 200)
        }
        
        Spacer()
        HStack {
            BackButton(buttonAction: backButtonAction)
            Spacer()
            GButton(role: nil, action: forwardButtonAction) {
                Text("Cool 😎").foregroundColor(.white)
            }
            Spacer()
            BackButton(buttonAction: backButtonAction).opacity(0).accessibilityHidden(true)
        }.frame(maxWidth: .infinity)
    }
}

struct TutorialPart4: View {
    var backButtonAction: () -> Void
    var forwardButtonAction: () -> Void
    
    var body: some View {
        HStack(spacing: 40){
            VStack(alignment: .leading, spacing: 10){
                Text("View history of picks in the popover.")
            }.frame(width: 300)
            Image("history")
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 200)
        }
        
        Spacer()
        HStack {
            BackButton(buttonAction: backButtonAction)
            Spacer()
            GButton(role: nil, action: forwardButtonAction) {
                Text("Cool 😎").foregroundColor(.white)
            }
            Spacer()
            BackButton(buttonAction: backButtonAction).opacity(0).accessibilityHidden(true)
        }.frame(maxWidth: .infinity)
    }
}

struct TutorialPart5: View {
    var backButtonAction: () -> Void
    var forwardButtonAction: () -> Void
    
    var body: some View {
        HStack(spacing: 40){
            VStack(alignment: .leading, spacing: 10){
                Text("Finally, if you have feedback or want to see this tutorial again, right-click on the icon in the menu bar.")
            }.frame(width: 300)
            Image("feedback")
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 200)
        }
        Spacer()
        HStack {
            BackButton(buttonAction: backButtonAction)
            Spacer()
            GButton(role: nil, action: forwardButtonAction) {
                Text("Got it!").foregroundColor(.white)
            }
            Spacer()
            BackButton(buttonAction: backButtonAction).opacity(0).accessibilityHidden(true)
        }.frame(maxWidth: .infinity)
    }
}

struct Tutorial: View {
    var delegate: AppDelegate = NSApp.delegate as! AppDelegate
    @ObservedObject var appModel: AppModel
    @State var stage: Int = 0
    
    init(appModel: AppModel) {
        self.appModel = appModel
    }
    
    public func stage(_ stage: Int) -> some View {
        var view = self
        view._stage = State(initialValue: stage)
        return view.id(UUID())
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Welcome to").font(Font.system(size: 24))
            Text("Contraster!").font(Font.system(size: 32)).bold()
            Image("eyedropper-3d")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            Spacer()
            if(stage == 0) {
                TutorialPart1(forwardButtonAction: {
                    stage += 1
                })
            }
            if(stage == 1) {
                TutorialPart2(backButtonAction: {
                    stage -= 1
                }, forwardButtonAction: {
                    stage += 1
                })
            }
            if(stage == 2) {
                TutorialPart3(backButtonAction: {
                    stage -= 1
                }, forwardButtonAction: {
                    stage += 1
                })
            }
            if(stage == 3) {
                TutorialPart4(backButtonAction: {
                    stage -= 1
                }, forwardButtonAction: {
                    stage += 1
                })
            }
            if(stage == 4) {
                TutorialPart5(backButtonAction: {
                    stage -= 1
                }, forwardButtonAction: {
                    appModel.setFirstWelcomeDone()
                    delegate.hideTutorial()
                })
            }
            Spacer()
        }.padding(EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 12))
            .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity, alignment: .center)
    }
}

struct Tutorial_Previews: PreviewProvider {
    static var previews: some View {
        Tutorial(appModel: AppModel())
        Tutorial(appModel: AppModel()).stage(1)
        Tutorial(appModel: AppModel()).stage(2)
        Tutorial(appModel: AppModel()).stage(3)
        Tutorial(appModel: AppModel()).stage(4)
    }
}
