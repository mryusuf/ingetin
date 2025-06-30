//
//  Persistence.swift
//  Ingetin
//
//  Created by Indra on 25/06/25.
//

import CoreData

struct PersistenceController {
    
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let sampleReminder = ReminderItem(context: viewContext)
        sampleReminder.name = "Morning Exercise"
        sampleReminder.notificationTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        sampleReminder.createdAt = Date()
        
        let completedReminder = ReminderItem(context: viewContext)
        completedReminder.name = "Read Book"
        completedReminder.notificationTime = Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: Date()) ?? Date()
        completedReminder.createdAt = Date()
        completedReminder.completedAt = Date()
        do {
            try viewContext.save()
        } catch {
            debugPrint("Preview context save error: \(error)")
        }
        return result
    }()

    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Ingetin")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Save Operations
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            debugPrint("Save error: \(error)")
        }
    }
    
    func saveBackground() async throws {
        let context = container.newBackgroundContext()
        
        do {
            try context.performAndWait {
                try context.save()
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Delete All Operations
    func batchDelete<T: NSManagedObject>(
            entity: T.Type,
            predicate: NSPredicate? = nil
        ) async throws {
            let context = container.newBackgroundContext()
            
            try await context.perform {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entity))
                fetchRequest.predicate = predicate
                
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                batchDeleteRequest.resultType = .resultTypeObjectIDs
                
                let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes,
                                                        into: [container.viewContext])
                }
            }
        }
}
