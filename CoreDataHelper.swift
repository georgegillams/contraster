//
//  CoreDataHelper.swift
//  Contraster
//

import CoreData

final class CoreDataHelper {
    static let shared = CoreDataHelper()

    let stack: CoreDataStack
    var context: NSManagedObjectContext

    private init() {
        guard let stack = CoreDataStack(modelName: "PersistedDataModel") else {
            fatalError("Failed to initialize Core Data stack")
        }
        self.stack = stack
        context = stack.context
    }
}
