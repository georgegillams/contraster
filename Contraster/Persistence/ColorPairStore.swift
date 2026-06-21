//
//  ColorPairStore.swift
//  Contraster
//

import CoreData
import SwiftUI

struct StoredColorPair {
    let pickId: String
    let color1: Color?
    let color2: Color?
}

final class ColorPairStore {
    static let shared = ColorPairStore()

    private let helper = CoreDataHelper.shared

    private init() {}

    func loadAllPairs() -> [StoredColorPair] {
        let request = PickedColorPair.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "pickId", ascending: false)]

        do {
            let pairs = try helper.context.fetch(request)
            return pairs.map { pair in
                StoredColorPair(
                    pickId: pair.pickId ?? UUID().uuidString,
                    color1: pair.hexColor1.flatMap { Color(hex: $0) },
                    color2: pair.hexColor2.flatMap { Color(hex: $0) }
                )
            }
        } catch {
            print("Could not read color pairs: \(error)")
            return []
        }
    }

    func savePair(pickId: String, color1: Color?, color2: Color?) {
        guard let newColorPair = NSEntityDescription.insertNewObject(
            forEntityName: "PickedColorPair",
            into: helper.context
        ) as? PickedColorPair else { return }

        newColorPair.pickId = pickId
        newColorPair.hexColor1 = color1?.hexString
        newColorPair.hexColor2 = color2?.hexString

        saveContext()
    }

    func deletePair(pickId: String) {
        let request = PickedColorPair.fetchRequest()
        request.predicate = NSPredicate(format: "pickId == %@", pickId)

        do {
            let pairs = try helper.context.fetch(request)
            pairs.forEach { helper.context.delete($0) }
            saveContext()
        } catch {
            print("Could not delete color pair: \(error)")
        }
    }

    func setFirstWelcomeDone() {
        let request = NSFetchRequest<Settings>(entityName: "Settings")

        do {
            let settingsObject: Settings
            if let existingSettings = try helper.context.fetch(request).first {
                settingsObject = existingSettings
            } else {
                guard let newSettings = NSEntityDescription.insertNewObject(
                    forEntityName: "Settings",
                    into: helper.context
                ) as? Settings else {
                    print("Failed to create new Settings object")
                    return
                }
                settingsObject = newSettings
            }

            settingsObject.firstWelcomeDone = true
            saveContext()
        } catch {
            print("Error in setFirstWelcomeDone: \(error)")
        }
    }

    func isFirstWelcomeDone() -> Bool {
        let request = NSFetchRequest<Settings>(entityName: "Settings")

        do {
            if let settings = try helper.context.fetch(request).first {
                return settings.firstWelcomeDone
            }
        } catch {
            print("Could not read settings: \(error)")
        }
        return false
    }

    private func saveContext() {
        guard helper.context.hasChanges else { return }
        do {
            try helper.context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
