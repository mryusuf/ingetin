//
//  ReminderListViewModel.swift
//  Ingetin
//
//  Created by Indra on 29/06/25.
//

import Foundation
import Combine
import Factory

@MainActor
final class ReminderListViewModel: ObservableObject {
    @Published var activeReminders: [Reminder] = []
    @Published var filteredReminders: [Reminder] = []
    @Published var state: ScreenState = .initial
    @Published var error: ReminderError?
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .time
    
    enum SortOrder: CaseIterable {
        case time, name, created
        
        var displayName: String {
            switch self {
            case .time: return "Time"
            case .name: return "Name"
            case .created: return "Created"
            }
        }
    }
    
    private let getRemindersUseCase: GetRemindersUseCaseProtocol
    private let completeReminderUseCase: CompleteReminderUseCaseProtocol
    private let deleteReminderUseCase: DeleteReminderUseCaseProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        getRemindersUseCase: GetRemindersUseCaseProtocol = Container.shared.getRemindersUseCase(),
        completeReminderUseCase: CompleteReminderUseCaseProtocol = Container.shared.completeReminderUseCase(),
        deleteReminderUseCase: DeleteReminderUseCaseProtocol = Container.shared.deleteReminderUseCase()
    ) {
        self.getRemindersUseCase = getRemindersUseCase
        self.completeReminderUseCase = completeReminderUseCase
        self.deleteReminderUseCase = deleteReminderUseCase
        
        Container.shared.coreDataStatePublisher()
            .$didChange.sink { [weak self] _ in
                self?.refresh()
        }
        .store(in: &cancellables)
        
        setupBindings()
        loadReminders()
    }
    
    private func setupBindings() {
        Publishers.CombineLatest3($activeReminders, $searchText, $sortOrder)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] reminders, searchText, sortOrder in
                self?.applyFiltersAndSort(reminders: reminders, searchText: searchText, sortOrder: sortOrder)
            }
            .store(in: &cancellables)
    }
    
    private func loadReminders() {
        state = .loading
        Task {
            do {
                let reminders = try await getRemindersUseCase.executeActive()
                activeReminders = reminders
                state = .loaded
            } catch {
                self.error = error as? ReminderError ?? .saveFailed
            }
        }
    }
    
    private func applyFiltersAndSort(reminders: [Reminder], searchText: String, sortOrder: SortOrder) {
        let filtered = searchText.isEmpty ? reminders :
            reminders.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        
        let sorted = filtered.sorted { lhs, rhs in
            switch sortOrder {
            case .time:
                return lhs.notificationTime < rhs.notificationTime
            case .name:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .created:
                return lhs.createdAt > rhs.createdAt
            }
        }
        
        filteredReminders = sorted
    }
    
    func completeReminder(_ reminder: Reminder) {
        Task {
            do {
                debugPrint(reminder.id)
                _ = try await completeReminderUseCase.execute(reminderId: reminder.notificationId ?? "")
                await MainActor.run {
                    refresh()
                }
            } catch {
                await MainActor.run {
                    self.error = error as? ReminderError ?? .saveFailed
                }
            }
        }
    }
    
    func deleteReminder(_ reminder: Reminder) {
        Task {
            do {
                try await deleteReminderUseCase.execute(reminderId: reminder.notificationId ?? "")
                await MainActor.run {
                    refresh()
                }
            } catch {
                await MainActor.run {
                    self.error = error as? ReminderError ?? .deleteFailed
                }
            }
        }
    }
    
    func refresh() {
        loadReminders()
    }
    
}
