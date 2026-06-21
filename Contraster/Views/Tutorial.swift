//
//  Tutorial.swift
//  Contraster
//

import AppKit
import SwiftUI

struct BackButton: View {
    var buttonAction: () -> Void

    var body: some View {
        GButton(kind: .secondary, action: buttonAction) {
            Image(systemName: "arrow.left")
            Text("Back")
        }
    }
}

struct TutorialNavigationBar<Leading: View, Center: View>: View {
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var center: () -> Center

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            ZStack {
                HStack {
                    leading()
                    Spacer(minLength: 0)
                }
                center()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct TutorialStepContent: View {
    var instructions: [String]
    var imageName: String

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
    }
}

struct TutorialPart1Content: View {
    let appActions: ContrasterAppActions
    @ObservedObject var permissionMonitor: ScreenRecordingPermissionMonitor

    var body: some View {
        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 10) {
                if permissionMonitor.hasPermissions {
                    Text("Screen recording permission granted ✓")
                        .foregroundStyle(Color("PositiveColor"))
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

    private var headerIconSize: CGFloat {
        stage == 0 ? 100 : 64
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Text("Welcome to").font(Font.system(size: 24))
                Text("Contraster!").font(Font.system(size: 32)).bold()
                if let icon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: headerIconSize, height: headerIconSize)
                }
                Spacer(minLength: 0)
                stepContent
                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            navigationBar
        }
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch stage {
        case 0:
            TutorialPart1Content(
                appActions: appActions,
                permissionMonitor: permissionMonitor
            )
        case 1:
            TutorialStepContent(
                instructions: [
                    "Click \"Open System Preferences\", then click the padlock.",
                    "Next check the box next to \"Contraster\"."
                ],
                imageName: "grant-permission-2"
            )
        case 2:
            TutorialStepContent(
                instructions: [
                    "Click on the Contraster icon in the menu bar to open the popover.",
                    "Then click \"New Pick\", and then click twice anywhere on your screen."
                ],
                imageName: "new-pick"
            )
        case 3:
            TutorialStepContent(
                instructions: ["View history of picks in the popover."],
                imageName: "history"
            )
        case 4:
            TutorialStepContent(
                instructions: [
                    "Hold Option while clicking the Contraster icon in the menu bar to start picking immediately."
                ],
                imageName: "menu-icon"
            )
        case 5:
            TutorialStepContent(
                instructions: [
                    "Finally, if you have feedback or want to see this tutorial again, right-click on the Contraster icon in the menu bar."
                ],
                imageName: "feedback"
            )
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var navigationBar: some View {
        switch stage {
        case 0:
            TutorialNavigationBar {
                 if permissionMonitor.hasPermissions {
                    GButton(kind: .secondary, action: {
                        appActions.openScreenRecordingPreferences()
                    }) {
                        Text("Manage permissions")
                    }
                } else {
                    EmptyView()
                }
            } center: {
                HStack(spacing: 12) {
                    if permissionMonitor.hasPermissions {
                        GButton(kind: .primary, action: advanceFromPermissionsIntro) {
                            Text("Next")
                        }
                    } else {
                        GButton(kind: .primary, action: {
                            appActions.checkScreenRecordingPermissions()
                        }) {
                            Text("Grant permissions")
                        }
                    }
                }
            }
        case 1:
            TutorialNavigationBar {
                BackButton(buttonAction: { stage -= 1 })
            } center: {
                GButton(kind: .primary, action: { stage += 1 }) {
                    Text("Done")
                }
            }
        case 2:
            TutorialNavigationBar {
                BackButton(buttonAction: retreatFromNewPickIntro)
            } center: {
                GButton(kind: .primary, action: { stage += 1 }) {
                    Text("Cool 😎")
                }
            }
        case 3:
            TutorialNavigationBar {
                BackButton(buttonAction: { stage -= 1 })
            } center: {
                GButton(kind: .primary, action: { stage += 1 }) {
                    Text("Ok 👌")
                }
            }
        case 4:
            TutorialNavigationBar {
                BackButton(buttonAction: { stage -= 1 })
            } center: {
                GButton(kind: .primary, action: { stage += 1 }) {
                    Text("Nice 👍")
                }
            }
        case 5:
            TutorialNavigationBar {
                BackButton(buttonAction: { stage -= 1 })
            } center: {
                GButton(kind: .primary, action: {
                    appModel.setFirstWelcomeDone()
                    appActions.hideTutorial()
                }) {
                    Text("Got it!")
                }
            }
        default:
            EmptyView()
        }
    }

    private func advanceFromPermissionsIntro() {
        stage = permissionMonitor.hasPermissions ? 2 : 1
    }

    private func retreatFromNewPickIntro() {
        stage = permissionMonitor.hasPermissions ? 0 : 1
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
