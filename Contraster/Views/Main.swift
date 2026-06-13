//
//  Main.swift
//  Contraster
//
//  Created by George Gillams on 02/09/2022.
//

import SwiftUI

struct Main: View {
    var delegate: AppDelegate = NSApp.delegate as! AppDelegate
    @ObservedObject var appModel: AppModel
    
    init(appModel: AppModel) {
        self.appModel = appModel
    }
    
    private var isPicking: Bool {
        appModel.pickingMode != .notPicking
    }

    private func schedulePopoverSizeUpdate(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            delegate.updatePopoverContentSize()
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
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: {
                            delegate.togglePopover(delegate.statusBarItem.button)
                            delegate.openMenu()
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
                                delegate.updateMouseTrapWindow()
                            }) {
                                Label("Cancel", systemImage: "xmark")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .tint(Color("DangerColor"))
                        } else {
                            Button(action: {
                                appModel.createNewPick()
                                delegate.updateMouseTrapWindow()
                            }) {
                                Label("New pick", systemImage: "eyedropper.halffull")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(Color("CTABackgroundColor"))
                        }
                    }
                }

                ContrastResultsAnimated(model: appModel.currentResult)
            }
            .padding(.bottom, isPicking ? InterfaceConstants.popoverPickingSectionBottomPadding : 0)

            Divider().padding(.vertical, 4)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("History")
                        .font(InterfaceConstants.popoverTitleFont)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                    if appModel.resultsList.isEmpty {
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
                    ForEach(appModel.resultsList) { result in
                        ContrastResults(model: result, onDelete: {
                            appModel.deleteColourPair(pickId: result.pickId)
                        })
                        .padding(.vertical, InterfaceConstants.popoverCardShadowPadding)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: InterfaceConstants.popoverHistoryMaxHeight)
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


struct Main_Previews: PreviewProvider {
    static var exampleAppModel: AppModel {
        get {
            let exampleAppModel = AppModel()
            exampleAppModel.updateFirstColor(color: Color.red)
            exampleAppModel.captureFirstColor()
            exampleAppModel.currentPickerColor = Color.blue
            return exampleAppModel
        }
    }
    
    static var previews: some View {
        Main(appModel: exampleAppModel)
    }
}
