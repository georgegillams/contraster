//
//  Settings+CoreDataClass.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 29/09/2022.
//
//

import Foundation
import CoreData

@objc(Settings)
public class Settings: NSManagedObject {
    convenience init(context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Settings", in: context) {
            self.init(entity: ent, insertInto: context)
            self.firstWelcomeDone = true
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
