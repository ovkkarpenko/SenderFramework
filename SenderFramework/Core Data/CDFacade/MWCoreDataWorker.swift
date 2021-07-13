//
//  MWCoreDataWorker.swift
//  SENDER
//
//  Created by Eugene Gilko on 4/2/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation
import CoreData

class MWCoreDataWorker: NSObject {

    let kStoreName = "senderBase.sqlite"
    let kModmName = "senderBase"
    
    var _managedObjectContext: NSManagedObjectContext?
    var _managedObjectModel: NSManagedObjectModel?
    var _persistentStoreCoordinator: NSPersistentStoreCoordinator?
    

    static let shared = MWCoreDataWorker()
    
    func initialize(){
        self.managedObjectContext
    }
    
    var managedObjectContext: NSManagedObjectContext{
        
        if Thread.isMainThread {
            
            if (_managedObjectContext == nil) {
                if let coordinator = self.persistentStoreCoordinator  {
                    _managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                    _managedObjectContext!.persistentStoreCoordinator = coordinator
                }
                
                return _managedObjectContext!
            }
            
        }else{
            
            var threadContext : NSManagedObjectContext? = Thread.current.threadDictionary["NSManagedObjectContext"] as? NSManagedObjectContext;
            
            print(Thread.current.threadDictionary)
            
            if threadContext == nil {
                print("creating new context")
                threadContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                threadContext!.parent = _managedObjectContext
                threadContext!.name = Thread.current.description
                
                Thread.current.threadDictionary["NSManagedObjectContext"] = threadContext
                
                NotificationCenter.default.addObserver(self, selector:#selector(MWCoreDataWorker.contextWillSave(_:)) , name: NSNotification.Name.NSManagedObjectContextWillSave, object: threadContext)
                
            } else {
                print("using old context")
            }
            return threadContext!;
        }
        
        return _managedObjectContext!
    }
    
    var managedObjectModel: NSManagedObjectModel {
        if _managedObjectModel == nil {
            let modelURL = SENDER_FRAMEWORK_BUNDLE.url(forResource: kModmName, withExtension: "momd")
            _managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)
        }
        return _managedObjectModel!
    }
    
    var persistentStoreCoordinator: NSPersistentStoreCoordinator? {
        if _persistentStoreCoordinator == nil {
            let storeURL = self.applicationDocumentsDirectory.appendingPathComponent(kStoreName)
            var error: NSError? = nil
            _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
          
            do {
                try _persistentStoreCoordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: self.databaseOptions())
            } catch let error1 as NSError {
                error = error1
                abort()
            }
        }
        
        return _persistentStoreCoordinator!
    }
    
    // fetches
    
    func executeFetchRequest(_ request: NSFetchRequest<NSManagedObject>) -> Array<AnyObject>?{
        
        var results:Array<AnyObject>?
        self.managedObjectContext.performAndWait{
            var fetchError:NSError?
            do {
                results = try self.managedObjectContext.fetch(request)
            } catch let error as NSError {
                fetchError = error
                results = nil
            } catch {
                fatalError()
            }
            
            if let error = fetchError {
                print("Warning!! \(error.description)")
            }
        }
        return results
        
    }
    
    func executeFetchRequest(_ request:NSFetchRequest<NSManagedObject>, completionHandler:@escaping (_ results: Array<AnyObject>?) -> Void)-> () {
        
        self.managedObjectContext.perform{
            var fetchError:NSError?
            var results:Array<AnyObject>?
            do {
                results = try self.managedObjectContext.fetch(request)
            } catch let error as NSError {
                fetchError = error
                results = nil
            } catch {
                fatalError()
            }
            
            if let error = fetchError {
                print("Warning!! \(error.description)")
            }
            
            completionHandler(results)
        }
    }
    
    func deleteEntity(_ object:NSManagedObject)-> () {
        object.managedObjectContext!.delete(object)
    }
    
    // Utilites
    
    func save() {
        
        let context:NSManagedObjectContext = self.managedObjectContext;
        if context.hasChanges {
            
            context.performAndWait{
                
                var saveError:NSError?
                let saved: Bool
                do {
                    try context.save()
                    saved = true
                } catch let error as NSError {
                    saveError = error
                    saved = false
                } catch {
                    fatalError()
                }
                
                if !saved {
                    if let error = saveError{
                        print("Warning!! Saving error \(error.description)")
                    }
                }
                
                if context.parent != nil {
                    
                    context.parent!.performAndWait{
                        var saveError:NSError?
                        let saved: Bool
                        do {
                            try context.parent!.save()
                            saved = true
                        } catch let error as NSError {
                            saveError = error
                            saved = false
                        } catch {
                            fatalError()
                        }
                        
                        if !saved{
                            if let error = saveError{
                                print("Warning!! Saving parent error \(error.description)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func contextWillSave(_ notification:Notification){
        
        let context : NSManagedObjectContext! = notification.object as! NSManagedObjectContext
        let insertedObjects : NSSet = context.insertedObjects as NSSet
        
        if insertedObjects.count != 0 {
            var obtainError:NSError?
            
            do {
                try context.obtainPermanentIDs(for: insertedObjects.allObjects as! [NSManagedObject])
            } catch let error as NSError {
                obtainError = error
            }
            if let error = obtainError {
                print("Warning!! obtaining ids error \(error.description)")
            }
        }
    }
    
    var applicationDocumentsDirectory: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex-1] as URL
    }
    
    func databaseOptions() -> Dictionary <String,Bool> {
        var options =  Dictionary<String,Bool>()
        options[NSMigratePersistentStoresAutomaticallyOption] = true
        options[NSInferMappingModelAutomaticallyOption] = true
        return options
    }
}
