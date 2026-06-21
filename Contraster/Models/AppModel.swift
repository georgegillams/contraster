//
//  AppModel.swift
//  Contraster
//

import SwiftUI
import AppKit

enum PickingMode {
    case notPicking
    case pickingFirstColor
    case pickingSecondColor
}

class AppModel: ObservableObject {
    private let store = ColorPairStore.shared

    @Published var currentPickerColor: Color?
    @Published var currentResult: ResultsModel?
    @Published var resultsList = [ResultsModel]()
    @Published var pickingMode: PickingMode = .notPicking
    @Published var currentMouseLocation: NSPoint = .zero
    @Published var currentScreenshot: NSImage?
    @Published var currentScreenFrame: NSRect = .zero
    @Published var magnificationScale: CGFloat = InterfaceConstants.defaultMagnificationScale

    init() {
        loadHistory()
        updatePickingMode()
    }

    func updatePickingMode() {
        if currentResult == nil {
            pickingMode = .notPicking
        } else if currentResult?.color1Captured == false {
            pickingMode = .pickingFirstColor
        } else if currentResult?.color1Captured == true && currentResult?.color2Captured == false {
            pickingMode = .pickingSecondColor
        }
        gDebugPrint("updatePickingMode: \(pickingMode)")
    }

    func createNewPick() {
        gDebugPrint("createNewPick")
        resetMagnificationScale()
        currentResult = ResultsModel(color1: nil, color2: nil)
        updatePickingMode()
    }

    func resetMagnificationScale() {
        magnificationScale = InterfaceConstants.defaultMagnificationScale
    }

    func adjustMagnificationScale(by delta: Int) {
        let newScale = Int(round(magnificationScale)) + delta
        let clampedScale = min(
            Int(InterfaceConstants.maxMagnificationScale),
            max(Int(InterfaceConstants.minMagnificationScale), newScale)
        )
        guard clampedScale != Int(round(magnificationScale)) else { return }
        magnificationScale = CGFloat(clampedScale)
        gDebugPrint("adjustMagnificationScale: \(magnificationScale)")
    }

    func cancelPick() {
        gDebugPrint("cancelPick")
        currentResult = nil
        currentPickerColor = nil
        updatePickingMode()
    }

    func updatePreviewColor(_ color: Color, slot: PickingColorSlot) {
        guard let currentResult else { return }
        currentResult.setPreviewColor(color, slot: slot)
        currentPickerColor = color
    }

    func captureFirstColor() {
        guard let currentResult else { return }
        currentResult.color1Captured = true
        currentResult.commitCalculations()
        updatePickingMode()
    }

    func captureSecondColor() {
        guard let result = currentResult else { return }
        result.color2Captured = true
        result.commitCalculations()
        resultsList.insert(result, at: 0)
        store.savePair(
            pickId: result.pickId,
            color1: result.color1,
            color2: result.color2
        )
        currentResult = nil
        currentPickerColor = nil
        updatePickingMode()
    }

    func deleteColourPair(pickId: String) {
        resultsList.removeAll { $0.pickId == pickId }
        store.deletePair(pickId: pickId)
    }

    func setFirstWelcomeDone() {
        store.setFirstWelcomeDone()
    }

    func isFirstWelcomeDone() -> Bool {
        store.isFirstWelcomeDone()
    }

    private func loadHistory() {
        store.loadAllPairs().forEach { pair in
            resultsList.insert(
                ResultsModel(pickId: pair.pickId, color1: pair.color1, color2: pair.color2),
                at: 0
            )
        }
    }
}
