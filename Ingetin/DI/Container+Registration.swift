//
//  Container+Registration.swift
//  Ingetin
//
//  Created by Indra on 27/06/25.
//

import Foundation
import Factory

// MARK: - Dependency Container
extension Container {
    
    // MARK: - Persistence
    var persistenceController: Factory<PersistenceController> {
        self { PersistenceController() }
            .singleton
    }
    
    // MARK: - CoreDataStatePublisher
    var coreDataStatePublisher: Factory<CoreDataStatePublisher> {
        self { CoreDataStatePublisher() }
            .singleton
    }
    
    // MARK: - Repositories
    var reminderRepository: Factory<ReminderRepositoryProtocol> {
        self { CoreDataReminderRepository(persistenceController: self.persistenceController()) }
            .singleton
    }
    
    // MARK: - Services
    var notificationService: Factory<NotificationServiceProtocol> {
        self { NotificationService() }
            .singleton
    }
    
    // MARK: - ViewModels
    @MainActor
    var reminderListViewModel: Factory<ReminderListViewModel> {
        self { @MainActor in ReminderListViewModel() }
    }
    
    @MainActor
    var addReminderViewModel: Factory<AddReminderViewModel> {
        self { @MainActor in AddReminderViewModel() }
    }
    
    @MainActor
    var completedRemindersViewModel: Factory<CompletedRemindersViewModel> {
        self { @MainActor in CompletedRemindersViewModel() }
    }
    
    // MARK: - Use Cases
    var addReminderUseCase: Factory<AddReminderUseCaseProtocol> {
        self {
            AddReminderUseCase(
                repository: Container.shared.reminderRepository(),
                notificationService: Container.shared.notificationService()
            )
        }
    }
    
    var completeReminderUseCase: Factory<CompleteReminderUseCaseProtocol> {
        self {
            CompleteReminderUseCase(
                repository: Container.shared.reminderRepository(),
                notificationService: Container.shared.notificationService()
            )
        }
    }
    
    var deleteReminderUseCase: Factory<DeleteReminderUseCaseProtocol> {
        self {
            DeleteReminderUseCase(
                repository: Container.shared.reminderRepository(),
                notificationService: Container.shared.notificationService()
            )
        }
    }
    
    var getRemindersUseCase: Factory<GetRemindersUseCaseProtocol> {
        self {
            GetRemindersUseCase(repository: Container.shared.reminderRepository())
        }
    }
    
}

// MARK: - Preview Container
extension Container {
    static let preview = Container()
    
    static func setupPreviewContainer() {
        preview.persistenceController.register {
            @MainActor in PersistenceController.preview
        }
        
        preview.reminderRepository.register {
            CoreDataReminderRepository(persistenceController: preview.persistenceController())
        }
        
        preview.notificationService.register {
            MockNotificationService()
        }
    }
}

// MARK: - Test Container
#if DEBUG
extension Container {
    static let test = Container()
    
    static func setupTestContainer() {
        test.persistenceController.register {
            PersistenceController(inMemory: true)
        }
        
        test.reminderRepository.register {
            CoreDataReminderRepository(persistenceController: test.persistenceController())
        }
        
        test.notificationService.register {
            MockNotificationService()
        }
    }
}
#endif
