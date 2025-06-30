//
//  CompleteReminderUseCase.swift
//  Ingetin
//
//  Created by Indra on 28/06/25.
//

import Foundation

protocol CompleteReminderUseCaseProtocol {
    func execute(reminderId: String) async throws -> Reminder
}

final class CompleteReminderUseCase: CompleteReminderUseCaseProtocol {
    private let repository: ReminderRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    
    init(
        repository: ReminderRepositoryProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.repository = repository
        self.notificationService = notificationService
    }
    
    func execute(reminderId: String) async throws -> Reminder {
        guard let reminder = try await repository.getReminder(by: reminderId) else {
            throw ReminderError.reminderNotFound
        }
        
        do {
            let updatedReminder = try await repository.markReminderComplete(id: reminderId,
                                                                            completedAt: Date())
            await notificationService.cancelReminder(identifier: reminder.notificationId ?? "")
            
            return updatedReminder
        } catch {
            debugPrint(error.localizedDescription)
            throw error
        }
    }
}
