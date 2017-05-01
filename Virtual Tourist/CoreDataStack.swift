//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 4/21/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import CoreData



struct CoreDataStack {
    
    // Properties
    
    private let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    private let modelURL: URL
    internal let dbURL: URL
    internal let persistingContext: NSManagedObjectContext
    internal let backgroundContext: NSManagedObjectContext
    let context: NSManagedObjectContext
    
    
    // Initializer
    
    init?(modelName: String) {
        
        // creates model URL
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName) in main bundle")
            return nil
        }
        
        self.modelURL = modelURL
        
        // Creates model from URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("Unable to create a model from \(modelURL)")
            return nil
        }
        
        self.model = model
        
        // Creates store coordinator for Object Model
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // Create a persistingContext (private queue) and a child one (main queue)
        // create a context and add connect it to the coordinator
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext
        
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        // Add a SQLite store located in the documents folder (aka choosing file location to store data)
        let fm = FileManager.default
        
        guard let docURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { // Can we choose downloads folder instead?
            print("Unable to reach documents folder")
            return nil
        }
        
        self.dbURL = docURL.appendingPathComponent("model.sqlite")
        
        // Migration Options
        let options = [NSInferMappingModelAutomaticallyOption: true, NSMigratePersistentStoresAutomaticallyOption: true]
        
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject:AnyObject]?)
        } catch {
            print("Unable to add store at \(dbURL)")
        }
    }
    
    // Utilities
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
    
    // Save function
    func save() {
        
        context.performAndWait() {
            
            if self.context.hasChanges {
                do {
                    try self.save()
                } catch {
                    fatalError("Error while trying to save main context: \(error)")
                }
                
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        fatalError("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    // Delete function
    func dropAllData() throws {
        // delete all the objects in the db.
        try coordinator.destroyPersistentStore(at: dbURL, ofType: NSSQLiteStoreType , options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
    
    // singleton -> CoreDataStack -> once
    
    static func sharedInstance() -> CoreDataStack  {
        struct Singleton {
            static var sharedInstance = CoreDataStack(modelName: "Virtual_Tourist")
        }
        if let sI = Singleton.sharedInstance {
            return sI
        } else {
            fatalError("Cannot find model named Virtual_Tourist")
        }
    }
}
