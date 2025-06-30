//
//  AppCoordinator.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//

import Foundation

final class AppCoordinator: ObservableObject {
    @Published var currentTab: Tab = .reminders
    @Published var isShowingAddReminder = false
    @Published var selectedReminder: Reminder?
    
    enum Tab: CaseIterable {
        case reminders, completed
        
        var title: String {
            switch self {
            case .reminders: return "Reminders"
            case .completed: return "Completed"
            }
        }
        
        var systemImage: String {
            switch self {
            case .reminders: return "bell.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
    
    func showAddReminder() {
        isShowingAddReminder = true
    }
    
    func hideAddReminder() {
        isShowingAddReminder = false
    }
    
    func selectTab(_ tab: Tab) {
        currentTab = tab
    }
}
