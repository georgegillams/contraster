//
//  Tutorial.swift
//  Contraster
//

import SwiftUI

struct BackButton: View {
    var buttonAction: () -> Void

    var body: some View {
        GButton(role: nil, backgroundColor: .gray, action: buttonAction) {
            Image(systemName: "arrow.left")
            Text("Back").foregroundColor(.white)
        }
    }
}

struct TutorialStepFooter: View {
    var backButtonAction: () -> Void
    var forwardButtonAction: () -> Void
    var forwardLabel: String

    var body: some View {
        HStack {
            BackButton(buttonAction: backButtonAction)
            Spacer()
            GButton(role: nil, action: forwardButtonAction) {
                Text(forwardLabel).foregroundColor(.white)
            }
            Spacer()
            BackButton(buttonAction: backButtonAction)
                .opacity(0)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TutorialStep: View {
    var instructions: [String]
    var imageName: String
    var backButtonAction: (() -> Void)?
    var forwardButtonAction: () -> Void
    var forwardLabel: String

    var body: some View {
        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(instructions, id: \.self) { instruction in
                    Text(instruction)
                }
            }
            .frame(width: 300)
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 200)
        }
        Spacer()
        if let backButtonAction {
            TutorialStepFooter(
                backButtonAction: backButtonAction,
                forwardButtonAction: forwardButtonAction,
                forwardLabel: forwardLabel
            )
        } else {
            HStack(spacing: 12) {
                forwardButton
            }
        }
    }

    @ViewBuilder
    private var forwardButton: some View {
        GButton(role: nil, action: forwardButtonAction) {
            Text(forwardLabel).foregroundColor(.white)
        }
    }
}

struct TutorialPart1: View {
    var forwardButtonAction: () -> Void
    let appActions: ContrasterAppActions
    @ObservedObject var permissionMonitor: ScreenRecordingPermissionMonitor

    var body: some View {
        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 10) {
                if permissionMonitor.hasPermissions {
                    Text("Screen recording permission granted ✓")
                        .foregroundColor(.green)
                } else {
                    Text("Before you get started, you'll need to enable screen-recording permission.")
                }
                Text("This allows you to capture the colour from a single pixel on the screen. We don't do anything creepy with the image on your screen, and it will never leave your device.")
            }
            .frame(width: 300)
            Image("grant-permission-1")
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 200)
        }
        Spacer()
        HStack(spacing: 12) {
            if permissionMonitor.hasPermissions {
                GButton(role: nil, backgroundColor: .gray, action: {
                    appActions.openScreenRecordingPreferences()
                }) {
                    Text("Manage permissions").foregroundColor(.white)
                }
                GButton(role: nil, action: forwardButtonAction) {
                    Text("Next").foregroundColor(.white)
                }
            } else {
                GButton(role: nil, action: {
                    appActions.checkScreenRecordingPermissions()
                }) {
                    Text("Grant permissions").foregroundColor(.white)
                }
            }
        }
        .onAppear {
            permissionMonitor.startPolling()
        }
        .onDisappear {
            permissionMonitor.stopPolling()
        }
    }
}

struct Tutorial: View {
    let appActions: ContrasterAppActions
    @ObservedObject var appModel: AppModel
    @ObservedObject var permissionMonitor: ScreenRecordingPermissionMonitor
    @State private var stage = 0

    init(
        appModel: AppModel,
        appActions: ContrasterAppActions,
        permissionMonitor: ScreenRecordingPermissionMonitor = .shared
    ) {
        self.appModel = appModel
        self.appActions = appActions
        self.permissionMonitor = permissionMonitor
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
            switch stage {
            case 0:
                TutorialPart1(forwardButtonAction: { stage += 1 }, appActions: appActions, permissionMonitor: permissionMonitor)
            case 1:
                TutorialStep(
                    instructions: [
                        "Click \"Open System Preferences\", then click the padlock.",
                        "Next check the box next to \"Contraster\"."
                    ],
                    imageName: "grant-permission-2",
                    backButtonAction: { stage -= 1 },
                    forwardButtonAction: { stage += 1 },
                    forwardLabel: "Done"
                )
            case 2:
                TutorialStep(
                    instructions: [
                        "Click on the eye-dropper in the menu bar to open the popover.",
                        "Then click \"New Pick\", and then click twice anywhere on your screen."
                    ],
                    imageName: "new-pick",
                    backButtonAction: { stage -= 1 },
                    forwardButtonAction: { stage += 1 },
                    forwardLabel: "Cool 😎"
                )
            case 3:
                TutorialStep(
                    instructions: ["View history of picks in the popover."],
                    imageName: "history",
                    backButtonAction: { stage -= 1 },
                    forwardButtonAction: { stage += 1 },
                    forwardLabel: "Cool 😎"
                )
            case 4:
                TutorialStep(
                    instructions: [
                        "Finally, if you have feedback or want to see this tutorial again, right-click on the icon in the menu bar."
                    ],
                    imageName: "feedback",
                    backButtonAction: { stage -= 1 },
                    forwardButtonAction: {
                        appModel.setFirstWelcomeDone()
                        appActions.hideTutorial()
                    },
                    forwardLabel: "Got it!"
                )
            default:
                EmptyView()
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 12))
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity, alignment: .center)
    }
}

struct Tutorial_Previews: PreviewProvider {
    static var previews: some View {
        Tutorial(appModel: AppModel(), appActions: PreviewTutorialActions())
    }
}

private final class PreviewTutorialActions: ContrasterAppActions {
    func togglePopover(_ sender: AnyObject?) {}
    func openMenu() {}
    func updateMouseTrapWindow() {}
    func showWelcomeTutorial() {}
    func hideTutorial() {}
    func hasScreenRecordingPermissions() -> Bool { true }
    func checkScreenRecordingPermissions() {}
    func openScreenRecordingPreferences() {}
    func updatePopoverContentSize() {}
}
