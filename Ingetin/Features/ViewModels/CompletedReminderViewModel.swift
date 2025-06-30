//
//  CompletedReminderViewModel.swift
//  Ingetin
//
//  Created by Indra on 29/06/25.
//

import Foundation
import Factory
import Combine

@MainActor
final class CompletedRemindersViewModel: ObservableObject {
    @Published var completedReminders: [Reminder] = []
    @Published var isLoading = false
    @Published var error: ReminderError?
    
    private let getRemindersUseCase: GetRemindersUseCaseProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        getRemindersUseCase: GetRemindersUseCaseProtocol = Container.shared.getRemindersUseCase()
    ) {
        self.getRemindersUseCase = getRemindersUseCase
        
        Container.shared.coreDataStatePublisher()
            .$didChange.sink { [weak self] _ in
                self?.refresh()
        }
        .store(in: &cancellables)
        
        loadCompletedReminders()
    }
    
    private func loadCompletedReminders() {
        Task {
            isLoading = true
            do {
                let reminders = try await getRemindersUseCase.executeCompleted()
                completedReminders = reminders
            } catch {
                self.error = error as? ReminderError ?? .saveFailed
            }
            isLoading = false
        }
    }
    
    func refresh() {
        loadCompletedReminders()
    }
}
