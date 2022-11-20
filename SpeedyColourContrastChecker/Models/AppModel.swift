//
//  ResultModel.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 07/09/2022.
//

import SwiftUI
import Foundation

enum PickingMode {
    case notPicking
    case pickingFirstColor
    case pickingSecondColor
}

class AppModel: ObservableObject {
    
    @Published var currentPickerColor: Color?
    @Published var currentResult: ResultsModel?
    @Published var resultsList = [ResultsModel]()
    @Published var pickingMode: PickingMode = .notPicking
    
    init() {
//        CoreDataHelper().dropAllData()
        readCoreDataPairs()
        
        updatePickingMode()
    }
    
    func updatePickingMode () {
        if (currentResult == nil) {
            pickingMode = .notPicking
        }
        else if (currentResult?.color1Captured == false) {
            pickingMode = .pickingFirstColor
        }
        else if (currentResult?.color1Captured == true && currentResult?.color2Captured == false) {
            pickingMode = .pickingSecondColor
        }
    }
    
    func createNewPick() {
        currentResult = ResultsModel(color1: nil, color2: nil)
        updatePickingMode()
    }
    
    func cancelPick() {
        currentResult = nil
        updatePickingMode()
    }
    
    func updateFirstColor(color: Color) {
        if (currentResult == nil) {
            return
        }
        currentResult!.color1 = color
        currentPickerColor = color
    }
    
    func updateSecondColor(color: Color) {
        if (currentResult == nil) {
            return
        }
        currentResult!.color2 = color
        currentPickerColor = color
    }
    
    func captureFirstColor() {
        if (currentResult == nil) {
            return
        }
        currentResult?.color1Captured = true
        updatePickingMode()
    }
    
    func captureSecondColor() {
        if (currentResult == nil) {
            return
        }
        currentResult?.color2Captured = true
        resultsList.insert(currentResult!, at: 0)
        saveCurrentResultToCoreData()
        currentResult = nil
        updatePickingMode()
    }
    
    func deleteColourPair(pickId: String) {
        resultsList.removeAll(where: { resultModel in
            resultModel.pickId == pickId
        })
        deleteResultFromCoreData(pickId: pickId)
    }
    
    private func readCoreDataPairs() {
        let helper = CoreDataHelper()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "PickedColorPair")
        do {
            if let colorPairList = try helper.context.fetch(fr) as? [PickedColorPair] {
                colorPairList.forEach({ pair in
                    let color1 = pair.hexColor1 != nil ? Color(hex: pair.hexColor1!) : nil
                    let color2 = pair.hexColor2 != nil ? Color(hex: pair.hexColor2!) : nil
                    resultsList.insert(ResultsModel(pickId: pair.pickId, color1: color1, color2: color2), at: 0)
                })
            }
        } catch {
            print("Could not read contact fetcher")
        }
    }
    
    private func deleteResultFromCoreData(pickId: String) {
        let helper = CoreDataHelper()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "PickedColorPair")
        do {
            if let colorPairList = try helper.context.fetch(fr) as? [PickedColorPair] {
                colorPairList.forEach({ pair in
                    if (pair.pickId == pickId) {
                        helper.context.delete(pair)
                    }
                })
            }
        } catch {
            print("Could not delete result from core data")
        }
    
    do {
        try helper.context.save()
    } catch {
        print("error in saving context")
    }
    }
    
    private func saveCurrentResultToCoreData() {
        let helper = CoreDataHelper()
        guard let newColorPair = NSEntityDescription.insertNewObject(
                    forEntityName: "PickedColorPair",
                    into: helper.context) as? PickedColorPair else { return }
        newColorPair.pickId = currentResult?.pickId
        newColorPair.hexColor1 = currentResult?.color1?.hexString
        newColorPair.hexColor2 = currentResult?.color2?.hexString
        
        do {
            try helper.context.save()
        } catch {
            print("error in saving context")
        }
    }
    
    func setFirstWelcomeDone() {
        
        // TODO: Update existing value instead of inserting new
        let helper = CoreDataHelper()
        guard let newSettings = NSEntityDescription.insertNewObject(
                    forEntityName: "Settings",
                    into: helper.context) as? Settings else { return }
        newSettings.firstWelcomeDone = true
        
        do {
            try helper.context.save()
        } catch {
            print("error in saving context")
        }
    }
    
    func isFirstWelcomeDone() -> Bool {
        let helper = CoreDataHelper()
        var result = false
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
        do {
            if let settings = try helper.context.fetch(fr) as? [Settings] {
                settings.forEach({ setting in
                    if(setting.firstWelcomeDone) {
                        result = true
                    }
                })
            }
        } catch {
            print("Could not read contact fetcher")
        }
        return result
    }
}
