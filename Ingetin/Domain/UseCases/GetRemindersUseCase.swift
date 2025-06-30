//
//  GetRemindersUseCase.swift
//  Ingetin
//
//  Created by Indra on 28/06/25.
//

import Foundation
import Combine

protocol GetRemindersUseCaseProtocol {
    func execute() async throws -> [Reminder]
    func executeActive() async throws -> [Reminder]
    func executeCompleted() async throws -> [Reminder]
}

final class GetRemindersUseCase: GetRemindersUseCaseProtocol {
    private let repository: ReminderRepositoryProtocol
    
    init(repository: ReminderRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() async throws -> [Reminder] {
        return try await repository.getAllReminders()
    }
        
    func executeActive() async throws -> [Reminder] {
        return try await repository.getActiveReminders()
    }
    
    func executeCompleted() async throws -> [Reminder] {
        return try await repository.getCompletedReminders()
    }
}
