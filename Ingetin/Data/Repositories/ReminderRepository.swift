//
//  ReminderRepository.swift
//  Ingetin
//
//  Created by Indra on 27/06/25.
//

import Foundation

// MARK: - Repository Errors
enum ReminderRepositoryError: Error, LocalizedError {
    case reminderNotFound
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .reminderNotFound:
            return "Reminder not found"
        case .saveFailed(let error):
            return "Failed to save reminder: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch reminders: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete reminder: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid reminder data"
        }
    }
}

// MARK: - Repository Protocol
protocol ReminderRepositoryProtocol {
    // MARK: - CRUD Operations
    func getAllReminders() async throws -> [Reminder]
    func getReminder(by notificationId: String) async throws -> Reminder?
    func addReminder(_ reminder: Reminder) async throws -> Reminder
    func markReminderComplete(id: String, completedAt: Date) async throws -> Reminder
    func deleteReminder(id: String) async throws
    
    // MARK: - Filtered Queries
    func getActiveReminders() async throws -> [Reminder]
    func getCompletedReminders() async throws -> [Reminder]
    func getRemindersForToday() async throws -> [Reminder]
    func getOverdueReminders() async throws -> [Reminder]
    
    // MARK: - Bulk Operations
    func deleteAllCompletedReminders() async throws
    
    // MARK: - Search and Filter
    func searchReminders(query: String) async throws -> [Reminder]
    func getReminders(sortedBy: ReminderSortOption, ascending: Bool) async throws -> [Reminder]
}

// MARK: - Sort Options
enum ReminderSortOption: String, CaseIterable {
    case name = "name"
    case notificationTime = "notificationTime"
    case createdAt = "createdAt"
    case completedAt = "completedAt"
    
    var displayName: String {
        switch self {
        case .name:
            return "Name"
        case .notificationTime:
            return "Notification Time"
        case .createdAt:
            return "Created Date"
        case .completedAt:
            return "Completed Date"
        }
    }
}

// MARK: - Default Implementations
extension ReminderRepositoryProtocol {
    func getRemindersForToday() async throws -> [Reminder] {
        let allReminders = try await getAllReminders()
        
        return allReminders.filter { reminder in
            // show all active reminders for today's remainders
            return !reminder.isCompleted
        }
    }
    
    func getOverdueReminders() async throws -> [Reminder] {
        let activeReminders = try await getActiveReminders()
        return activeReminders.filter { $0.isOverdue }
    }
    
    func searchReminders(query: String) async throws -> [Reminder] {
        let allReminders = try await getAllReminders()
        guard !query.isEmpty else { return allReminders }
        
        return allReminders.filter { reminder in
            reminder.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getReminders(sortedBy sortOption: ReminderSortOption, ascending: Bool = true) async throws -> [Reminder] {
        let allReminders = try await getAllReminders()
        
        return allReminders.sorted(by: { lhs, rhs in
            let result: Bool
            switch sortOption {
            case .name:
                result = lhs.name < rhs.name
            case .notificationTime:
                result = lhs.notificationTime < rhs.notificationTime
            case .createdAt:
                result = lhs.createdAt < rhs.createdAt
            case .completedAt:
                let lhsDate = lhs.completedAt ?? Date.distantPast
                let rhsDate = rhs.completedAt ?? Date.distantPast
                result = lhsDate < rhsDate
            }
            
            return ascending ? result : !result
        })
    }
}
