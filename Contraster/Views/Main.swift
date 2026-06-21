//
//  Main.swift
//  Contraster
//

import SwiftUI

struct Main: View {
    let appActions: ContrasterAppActions
    @ObservedObject var appModel: AppModel

    init(appModel: AppModel, appActions: ContrasterAppActions) {
        self.appModel = appModel
        self.appActions = appActions
    }

    private var isPicking: Bool {
        appModel.pickingMode != .notPicking
    }

    private func schedulePopoverSizeUpdate(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            appActions.updatePopoverContentSize()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 12) {
                if isPicking {
                    Spacer(minLength: 0)
                        .frame(height: InterfaceConstants.popoverPickingExtraTopPadding)
                }

                HStack(alignment: .top) {
                    PickingStatusHeader(isPicking: isPicking)
                    Spacer()
                    PickingActionButtons(
                        isPicking: isPicking,
                        appActions: appActions,
                        appModel: appModel
                    )
                }

                ContrastResultsAnimated(model: appModel.currentResult)
            }
            .padding(.horizontal, InterfaceConstants.popoverCardShadowInset)
            .padding(.bottom, isPicking ? InterfaceConstants.popoverPickingSectionBottomPadding : 0)

            Divider().padding(.vertical, 4)
            HistorySection(appModel: appModel)
        }
        .padding(16)
        .frame(width: InterfaceConstants.popoverWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: isPicking) { _ in
            schedulePopoverSizeUpdate(after: 0.05)
        }
    }
}

private struct PickingStatusHeader: View {
    let isPicking: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isPicking ? Color.accentColor : Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text(isPicking ? "Current pick" : "Ready")
                    .font(InterfaceConstants.popoverTitleFont)
            }
            Text(isPicking
                 ? "Click anywhere on screen to select the next colour"
                 : "Click the picker button to get started")
                .font(InterfaceConstants.popoverBodyFont)
                .foregroundStyle(.secondary)
            if isPicking {
                Text("Press ESC to cancel")
                    .font(InterfaceConstants.popoverSecondaryFont)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PickingActionButtons: View {
    let isPicking: Bool
    let appActions: ContrasterAppActions
    @ObservedObject var appModel: AppModel

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                appActions.togglePopover(nil)
                appActions.openMenu()
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
            }
            .buttonStyle(.borderless)
            .controlSize(.large)
            .accessibilityLabel("Open menu")

            if isPicking {
                Button(action: {
                    appModel.cancelPick()
                    appActions.updateMouseTrapWindow()
                }) {
                    Label("Cancel", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(Color("DangerColor"))
            } else {
                Button(action: {
                    appModel.createNewPick()
                    appActions.updateMouseTrapWindow()
                }) {
                    Label("New pick", systemImage: "eyedropper.halffull")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color("CTABackgroundColor"))
            }
        }
    }
}

private struct HistorySection: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("History")
                    .font(InterfaceConstants.popoverTitleFont)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
                if appModel.resultsList.isEmpty {
                    EmptyHistoryPlaceholder()
                }
                ForEach(appModel.resultsList) { result in
                    ContrastResults(model: result, onDelete: {
                        appModel.deleteColourPair(pickId: result.pickId)
                    })
                    .padding(.vertical, InterfaceConstants.popoverCardShadowSpread)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, InterfaceConstants.popoverCardShadowInset)
            .padding(.top, InterfaceConstants.popoverCardShadowInset)
            .padding(.bottom, InterfaceConstants.popoverCardShadowInset + InterfaceConstants.popoverCardShadowSpread)
        }
        .frame(maxHeight: InterfaceConstants.popoverHistoryMaxHeight)
    }
}

private struct EmptyHistoryPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No results yet")
                .font(InterfaceConstants.popoverTitleFont)
            Text("Once you start picking colours, they'll show up here.")
                .font(InterfaceConstants.popoverBodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct Main_Previews: PreviewProvider {
    static var exampleAppModel: AppModel {
        let exampleAppModel = AppModel()
        exampleAppModel.updatePreviewColor(.red, slot: .first)
        exampleAppModel.captureFirstColor()
        exampleAppModel.currentPickerColor = Color.blue
        return exampleAppModel
    }

    static var previews: some View {
        Main(appModel: exampleAppModel, appActions: PreviewAppActions())
    }
}

private final class PreviewAppActions: ContrasterAppActions {
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
