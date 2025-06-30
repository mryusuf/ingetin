//
//  AddReminderViewModel.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//

import Foundation
import Combine
import Factory

@MainActor
final class AddReminderViewModel: ObservableObject {
    @Published var name = ""
    @Published var selectedTime = Date()
    @Published var isLoading = false
    @Published var error: ReminderError?
    @Published var isValidName = true
    @Published var showingPermissionAlert = false
    
    private let addReminderUseCase: AddReminderUseCaseProtocol
    private let notificationService: NotificationServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    init(
        addReminderUseCase: AddReminderUseCaseProtocol = Container.shared.addReminderUseCase(),
        notificationService: NotificationServiceProtocol = Container.shared.notificationService()
    ) {
        self.addReminderUseCase = addReminderUseCase
        self.notificationService = notificationService
        
        setupValidation()
    }
    
    private func setupValidation() {
        $name
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .assign(to: &$isValidName)
    }
    
    func saveReminder() async -> Bool {
        guard canSave else { return false }
        
        isLoading = true
        error = nil
        
        do {
            // Check notification permission first
            let hasPermission = await notificationService.requestPermission()
            guard hasPermission else {
                error = .notificationPermissionDenied
                showingPermissionAlert = true
                isLoading = false
                return false
            }
            
            _ = try await addReminderUseCase.execute(name: name, notificationTime: selectedTime)
            isLoading = false
            return true
        } catch {
            self.error = error as? ReminderError ?? .saveFailed
            isLoading = false
            return false
        }
    }
    
    func reset() {
        name = ""
        selectedTime = Date()
        error = nil
        isValidName = true
    }
}

