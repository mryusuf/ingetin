//
//  CoreDataReminderRepository.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//

import Foundation
import CoreData
import Factory

struct CoreDataReminderRepository: ReminderRepositoryProtocol {
    private var persistenceController: PersistenceController
    
    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    // MARK: - Initialization
    init(persistenceController: PersistenceController = Container.shared.persistenceController()) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - CRUD Operations
    func getAllReminders() async throws -> [Reminder] {
        try await viewContext.perform {
            let request: NSFetchRequest<ReminderItem> = ReminderItem.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \ReminderItem.notificationTime, ascending: true),
                NSSortDescriptor(keyPath: \ReminderItem.name, ascending: true)
            ]
            
            do {
                let reminderItems = try self.viewContext.fetch(request)
                return reminderItems.compactMap { self.mapToDomain($0) }
            } catch {
                throw ReminderRepositoryError.fetchFailed(underlying: error)
            }
        }
    }
    
    func getReminder(by notificationId: String) async throws -> Reminder? {
        try await viewContext.perform {
            let request: NSFetchRequest<ReminderItem> = ReminderItem.fetchRequest()
            request.predicate = NSPredicate(format: "%K == %@", "notificationId", notificationId as CVarArg)
            request.fetchLimit = 1
            
            do {
                let reminderItems = try self.viewContext.fetch(request)
                debugPrint(reminderItems.count)
                debugPrint(reminderItems.first.debugDescription)
                return reminderItems.first.flatMap { self.mapToDomain($0) }
            } catch {
                debugPrint("Save error: \(error.localizedDescription)")
                throw ReminderRepositoryError.fetchFailed(underlying: error)
            }
        }
    }
    
    func addReminder(_ reminder: Reminder) async throws -> Reminder {
        try await viewContext.perform {
            let reminderItem = ReminderItem(context: self.viewContext)
            reminderItem.name = reminder.name
            reminderItem.notificationTime = reminder.notificationTime
            reminderItem.isCompleted = reminder.isCompleted
            reminderItem.createdAt = reminder.createdAt
            reminderItem.completedAt = reminder.completedAt
            reminderItem.notificationId = reminder.notificationId
            
            do {
                try self.viewContext.save()
                return reminder
            } catch {
                debugPrint("Save error: \(error.localizedDescription)")
                throw ReminderRepositoryError.saveFailed(underlying: error)
            }
        }
    }
    
    func updateReminder(_ reminder: Reminder) async throws -> Reminder {
        try await viewContext.perform {
            let request: NSFetchRequest<ReminderItem> = ReminderItem.fetchRequest()
            request.predicate = NSPredicate(format: "notificationId == %@", (reminder.notificationId ?? "") as CVarArg)
            request.fetchLimit = 1
            
            do {
                let reminderItems = try self.viewContext.fetch(request)
                guard let reminderItem = reminderItems.first else {
                    throw ReminderRepositoryError.reminderNotFound
                }
                
                self.mapToCoreData(reminder, reminderItem: reminderItem)
                try self.viewContext.save()
                return reminder
            } catch let error as ReminderRepositoryError {
                debugPrint("Save error: \(error.localizedDescription)")
                throw error
            } catch {
                debugPrint("Save error: \(error.localizedDescription)")
                throw ReminderRepositoryError.saveFailed(underlying: error)
            }
        }
    }
    
    func deleteReminder(id: String) async throws {
        try await viewContext.perform {
            let request: NSFetchRequest<ReminderItem> = ReminderItem.fetchRequest()
            request.predicate = NSPredicate(format: "notificationId == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let reminderItems = try self.viewContext.fetch(request)
                guard let reminderItem = reminderItems.first else {
                    throw ReminderRepositoryError.reminderNotFound
                }
                
                self.viewContext.delete(reminderItem)
                try self.viewContext.save()
            } catch let error as ReminderRepositoryError {
                throw error
            } catch {
                throw ReminderRepositoryError.deleteFailed(underlying: error)
            }
        }
    }
    
    // MARK: - Filtered Queries
    func getActiveReminders() async throws -> [Reminder] {
        try await viewContext.perform {
            let request: NSFetchRequest<ReminderItem> = ReminderItem.fetchRequest()
            request.predicate = NSPredicate(format: "isCompleted == NO")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \ReminderItem.notificationTime, ascending: true)
            ]
            
            do {
                let reminderItems = try self.viewContext.fetch(request)
                return reminderItems.compactMap { self.mapToDomain($0) }
            } catch {
                throw ReminderRepositoryError.fetchFailed(underlying: error)
            }
        }
    }
    
    func getCompletedReminders() async throws -> [Reminder] {
        try await viewContext.perform {
            let request: NSFetchRequest<ReminderItem> = ReminderItem.fetchRequest()
            request.predicate = NSPredicate(format: "isCompleted == YES")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \ReminderItem.completedAt, ascending: false)
            ]
            
            do {
                let reminderItems = try self.viewContext.fetch(request)
                return reminderItems.compactMap { self.mapToDomain($0) }
            } catch {
                throw ReminderRepositoryError.fetchFailed(underlying: error)
            }
        }
    }
    
    // MARK: - Bulk Operations
    func markReminderComplete(id: String, completedAt: Date = Date()) async throws -> Reminder {
        guard let reminder = try await getReminder(by: id) else {
            throw ReminderRepositoryError.reminderNotFound
        }
        
        let updatedReminder = reminder.markCompleted(at: completedAt)
        return try await updateReminder(updatedReminder)
    }
    
    func markReminderIncomplete(id: String) async throws -> Reminder {
        guard let reminder = try await getReminder(by: id) else {
            throw ReminderRepositoryError.reminderNotFound
        }
        
        let updatedReminder = reminder.markIncomplete()
        return try await updateReminder(updatedReminder)
    }
    
    func deleteAllCompletedReminders() async throws {
        try await persistenceController.batchDelete(
            entity: ReminderItem.self,
            predicate: NSPredicate(format: "isCompleted == YES")
        )
    }
}

// MARK: - Mapping Extensions
private extension CoreDataReminderRepository {
    func mapToDomain(_ reminderItem: ReminderItem) -> Reminder? {
        guard let name = reminderItem.name,
              let targetTime = reminderItem.notificationTime,
              let createdDate = reminderItem.createdAt else {
            return nil
        }
        
        return Reminder(
            id: reminderItem.id.hashValue.description,
            name: name,
            notificationTime: targetTime,
            isCompleted: reminderItem.isCompleted,
            createdAt: createdDate,
            completedAt: reminderItem.completedAt,
            notificationId: reminderItem.notificationId
        )
    }
    
    func mapToCoreData(_ reminder: Reminder, reminderItem: ReminderItem) {
        reminderItem.name = reminder.name
        reminderItem.notificationTime = reminder.notificationTime
        reminderItem.isCompleted = reminder.isCompleted
        reminderItem.createdAt = reminder.createdAt
        reminderItem.completedAt = reminder.completedAt
        reminderItem.notificationId = reminder.notificationId
    }
}
