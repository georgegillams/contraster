//
//  PickedColorPair+CoreDataClass.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 27/09/2022.
//
//

// TODO: Follow https://dev.to/midhetfatema94/getting-started-with-core-data-4jb1

import Foundation
import CoreData

@objc(PickedColorPair)
public class PickedColorPair: NSManagedObject {
    convenience init(pickId: String, hexColor1: String, hexColor2: String, context: NSManagedObjectContext) {
            if let ent = NSEntityDescription.entity(forEntityName: "PickedColorPair", in: context) {
                self.init(entity: ent, insertInto: context)
                self.pickId = pickId
                self.hexColor1 = hexColor1
                self.hexColor2 = hexColor2
            } else {
                fatalError("Unable to find Entity name!")
            }
        }
}
