//
//  Settings+CoreDataProperties.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 29/09/2022.
//
//

import Foundation
import CoreData


extension Settings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Settings> {
        return NSFetchRequest<Settings>(entityName: "Settings")
    }

    @NSManaged public var firstWelcomeDone: Bool

}

extension Settings : Identifiable {

}
