//
//  Reminder.swift
//  Ingetin
//
//  Created by Indra on 28/06/25.
//

import Foundation

struct Reminder: Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let notificationTime: Date
    let isCompleted: Bool
    let createdAt: Date
    let completedAt: Date?
    let notificationId: String?
    
    // MARK: - Computed Properties
    var notificationTimeComponents: DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
    }
    
    var isOverdue: Bool {
        guard !isCompleted else { return false }
        let now = Date()
        let todaysnotificationTime = Calendar.current.date(
            bySettingHour: notificationTimeComponents.hour ?? 0,
            minute: notificationTimeComponents.minute ?? 0,
            second: 0,
            of: now
        ) ?? now
        return now > todaysnotificationTime
    }
    
    var formattednotificationTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: notificationTime)
    }
    
    var notificationDate: Date? {
        guard let todaysnotificationTime = Calendar.current.date(
            bySettingHour: notificationTimeComponents.hour ?? 0,
            minute: notificationTimeComponents.minute ?? 0,
            second: 0,
            of: Date()
        ) else { return nil }
        
        // 10 minutes before target time
        return Calendar.current.date(byAdding: .minute, value: -10, to: todaysnotificationTime)
    }
}

// MARK: - Factory Methods
extension Reminder {
    static func create(
        name: String,
        notificationTime: Date,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) -> Reminder {
        return Reminder(
            id: id.uuidString,
            name: name,
            notificationTime: notificationTime,
            isCompleted: false,
            createdAt: createdAt,
            completedAt: nil,
            notificationId: nil
        )
    }
    
    func markCompleted(at date: Date = Date()) -> Reminder {
        return Reminder(
            id: self.id,
            name: self.name,
            notificationTime: self.notificationTime,
            isCompleted: true,
            createdAt: self.createdAt,
            completedAt: date,
            notificationId: self.notificationId
        )
    }
    
    func markIncomplete() -> Reminder {
        return Reminder(
            id: self.id,
            name: self.name,
            notificationTime: self.notificationTime,
            isCompleted: false,
            createdAt: self.createdAt,
            completedAt: nil,
            notificationId: self.notificationId
        )
    }
    
    func updatenotificationId(_ identifier: String?) -> Reminder {
        return Reminder(
            id: self.id,
            name: self.name,
            notificationTime: self.notificationTime,
            isCompleted: self.isCompleted,
            createdAt: self.createdAt,
            completedAt: self.completedAt,
            notificationId: identifier
        )
    }
}
