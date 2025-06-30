//
//  ReminderError.swift
//  Ingetin
//
//  Created by Indra on 28/06/25.
//

import Foundation

enum ReminderError: LocalizedError {
    case invalidName
    case reminderNotFound
    case saveFailed
    case deleteFailed
    case notificationPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Reminder name cannot be empty"
        case .reminderNotFound:
            return "Reminder not found"
        case .saveFailed:
            return "Failed to save reminder"
        case .deleteFailed:
            return "Failed to delete reminder"
        case .notificationPermissionDenied:
            return "Notification permission is required for reminders to work"
        }
    }
}
