//
//  PickedColorPair+CoreDataProperties.swift
//  Contraster
//
//  Created by George Gillams on 27/09/2022.
//
//

import Foundation
import CoreData


extension PickedColorPair {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PickedColorPair> {
        return NSFetchRequest<PickedColorPair>(entityName: "PickedColorPair")
    }

    @NSManaged public var pickId: String?
    @NSManaged public var hexColor1: String?
    @NSManaged public var hexColor2: String?

}

extension PickedColorPair : Identifiable {

}
