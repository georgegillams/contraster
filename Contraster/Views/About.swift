//
//  About.swift
//  Contraster
//

import Cocoa
import SwiftUI

struct AboutView: View {
    let appActions: ContrasterAppActions

    var body: some View {
        VStack {
            VStack(alignment: .center) {
                if let icon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                }

                Text("Contraster \(Bundle.main.appVersion)")
                    .bold()
                    .font(.title)
                    .padding(.vertical, 5.0)

                Text("Created by George Gillams")
                    .underline()
                    .onTapGesture {
                        AppURLs.open(AppURLs.author)
                    }
            }
            .padding(.vertical, 10.0)

            Button(action: {
                appActions.showWelcomeTutorial()
            }) {
                Text("Show welcome tutorial")
            }

            HStack {
                Text("Bug or feature request?")

                Button(action: {
                    AppURLs.openFeedback()
                }) {
                    Text("Tell Me")
                }
            }
        }
        .padding(10.0)
        .background(Color.clear)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}

class AboutWindowController {
    static func createWindow(appActions: ContrasterAppActions) {
        let windowRef = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 240),
            styleMask: [.titled, .closable, .borderless],
            backing: .buffered,
            defer: false
        )
        windowRef.contentView = NSHostingView(rootView: AboutView(appActions: appActions))
        windowRef.title = "About Contraster"
        windowRef.level = .floating
        windowRef.isReleasedWhenClosed = false
        windowRef.makeKeyAndOrderFront(nil)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(appActions: PreviewAboutActions()).frame(width: 380, height: 240)
    }
}

private final class PreviewAboutActions: ContrasterAppActions {
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
