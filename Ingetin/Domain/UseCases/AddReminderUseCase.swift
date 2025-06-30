//
//  AddReminderUseCase.swift
//  Ingetin
//
//  Created by Indra on 28/06/25.
//

import Foundation
import Combine

protocol AddReminderUseCaseProtocol {
    func execute(name: String, notificationTime: Date) async throws -> Reminder?
}

final class AddReminderUseCase: AddReminderUseCaseProtocol {
    private let repository: ReminderRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    
    init(
        repository: ReminderRepositoryProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.repository = repository
        self.notificationService = notificationService
    }
    
    func execute(name: String,
                 notificationTime: Date) async throws -> Reminder? {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReminderError.invalidName
        }
        
        let id = UUID().uuidString
        let reminder = Reminder(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            notificationTime: notificationTime,
            isCompleted: false,
            createdAt: Date(),
            completedAt: nil,
            notificationId: "reminder-\(id)"
        )
        
        do {
            let savedReminder = try await repository.addReminder(reminder)
            try await notificationService.scheduleReminder(for: savedReminder)
            return savedReminder
        } catch {
            debugPrint(error.localizedDescription)
            throw error
        }
    }
}
