//
//  CoreDataHelper.swift
//  SpeedyColourContrastChecker
//
//  Created by George Gillams on 27/09/2022.
//

import Foundation
import CoreData

class CoreDataHelper {
    
    let stack = CoreDataStack(modelName: "PersistedDataModel")!
    var context:NSManagedObjectContext
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            executeSearch()
        }
    }
    
    init() {
        context = stack.context
    }
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
    
    func dropAllData() {
        do {
            try stack.dropAllData()
        }catch {
            print("Error while trying to drop all data")
        }
    }
}
