//
//  DeleteReminderUseCase.swift
//  Ingetin
//
//  Created by Indra on 28/06/25.
//

import Foundation

protocol DeleteReminderUseCaseProtocol {
    func execute(reminderId: String) async throws
}

final class DeleteReminderUseCase: DeleteReminderUseCaseProtocol {
    private let repository: ReminderRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    
    init(
        repository: ReminderRepositoryProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.repository = repository
        self.notificationService = notificationService
    }
    
    func execute(reminderId: String) async throws {
        guard let reminder = try await repository.getReminder(by: reminderId) else {
            throw ReminderError.reminderNotFound
        }
        
        do {
            await notificationService.cancelReminder(identifier: reminder.notificationId ?? "")
            try await repository.deleteReminder(id: reminderId)
        } catch {
            debugPrint(error.localizedDescription)
            throw error
        }
    }
}
