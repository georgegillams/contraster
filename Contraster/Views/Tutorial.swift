//
//  Tutorial.swift
//  Contraster
//

import AppKit
import LaunchAtLogin
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

enum TutorialImageSize {
    case permission
    case popover
    case pick
    case menu

    var width: CGFloat {
        switch self {
        case .menu: 280
        default: 340
        }
    }

    var height: CGFloat {
        switch self {
        case .permission: 167
        case .popover: 231
        case .pick: 207
        case .menu: 224
        }
    }
}

private struct TutorialImage: View {
    var imageName: String
    var size: TutorialImageSize

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct TutorialStepContent: View {
    var instructions: [String]
    var imageName: String
    var imageSize: TutorialImageSize

    var body: some View {
        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(instructions, id: \.self) { instruction in
                    Text(instruction)
                }
            }
            .frame(width: 300)
            TutorialImage(imageName: imageName, size: imageSize)
        }
    }
}

struct TutorialLaunchAtLoginContent: View {
    var body: some View {
        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Launch at login")
                    .font(.system(size: 24, weight: .semibold))
                Text("This keeps the menu bar icon available whenever you need to pick a colour.")
                LaunchAtLogin.Toggle()
                    .toggleStyle(.switch)
            }
            .frame(width: 300)
            if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
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
            TutorialImage(imageName: "grant-permission-1", size: .permission)
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
                    "Click on the Contraster icon in the menu bar to open the popover.",
                    "Then click \"New Pick\", and then click twice anywhere on your screen."
                ],
                imageName: "new-pick",
                imageSize: .popover
            )
        case 2:
            TutorialStepContent(
                instructions: ["View history of picks in the popover."],
                imageName: "history",
                imageSize: .pick
            )
        case 3:
            TutorialStepContent(
                instructions: [
                    "Hold Option while clicking the Contraster icon in the menu bar to start picking immediately."
                ],
                imageName: "option-pick",
                imageSize: .pick
            )
        case 4:
            TutorialStepContent(
                instructions: [
                    "Finally, if you have feedback or want to see this tutorial again, right-click on the Contraster icon in the menu bar."
                ],
                imageName: "feedback",
                imageSize: .menu
            )
        case 5:
            TutorialLaunchAtLoginContent()
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
                            appActions.openScreenRecordingPreferences()
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
                    Text("Cool 😎")
                }
            }
        case 2:
            TutorialNavigationBar {
                BackButton(buttonAction: { stage -= 1 })
            } center: {
                GButton(kind: .primary, action: { stage += 1 }) {
                    Text("Ok 👌")
                }
            }
        case 3:
            TutorialNavigationBar {
                BackButton(buttonAction: { stage -= 1 })
            } center: {
                GButton(kind: .primary, action: { stage += 1 }) {
                    Text("Nice 👍")
                }
            }
        case 4:
            TutorialNavigationBar {
                BackButton(buttonAction: { stage -= 1 })
            } center: {
                GButton(kind: .primary, action: { stage += 1 }) {
                    Text("Almost done")
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
        stage = 1
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
