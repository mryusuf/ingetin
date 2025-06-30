//
//  ContentView.swift
//  Ingetin
//
//  Created by Indra on 25/06/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
        
    var body: some View {
        NavigationView {
            TabView(selection: $coordinator.currentTab) {
                ReminderListView()
                    .tabItem {
                        Image(systemName: AppCoordinator.Tab.reminders.systemImage)
                        Text(AppCoordinator.Tab.reminders.title)
                    }
                    .tag(AppCoordinator.Tab.reminders)
                
                CompletedRemindersView()
                    .tabItem {
                        Image(systemName: AppCoordinator.Tab.completed.systemImage)
                        Text(AppCoordinator.Tab.completed.title)
                    }
                    .tag(AppCoordinator.Tab.completed)
            }
            .accentColor(.blue)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView()
}
