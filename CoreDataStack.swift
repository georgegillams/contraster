//
//  CoreDataStack.swift
//  Contraster
//

import CoreData

struct CoreDataStack {
    private let model: NSManagedObjectModel
    let coordinator: NSPersistentStoreCoordinator
    private let modelURL: URL
    let dbURL: URL
    let context: NSManagedObjectContext

    init?(modelName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName) in the main bundle")
            return nil
        }
        self.modelURL = modelURL

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model

        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        let fm = FileManager.default

        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to reach the documents folder")
            return nil
        }

        self.dbURL = docUrl.appendingPathComponent("model.sqlite")

        let options: [String: Any] = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption: true
        ]

        do {
            try addStoreCoordinator(
                ofType: NSSQLiteStoreType,
                configuration: nil,
                storeURL: dbURL,
                options: options
            )
        } catch {
            print("unable to add store at \(dbURL)")
        }
    }

    func addStoreCoordinator(
        ofType storeType: String,
        configuration: String?,
        storeURL: URL,
        options: [AnyHashable: Any]?
    ) throws {
        try coordinator.addPersistentStore(
            ofType: storeType,
            configurationName: configuration,
            at: storeURL,
            options: options
        )
    }

    func dropAllData() throws {
        try coordinator.destroyPersistentStore(at: dbURL, ofType: NSSQLiteStoreType, options: nil)
        try addStoreCoordinator(
            ofType: NSSQLiteStoreType,
            configuration: nil,
            storeURL: dbURL,
            options: nil
        )
    }
}
