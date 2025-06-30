//
//  CompletedRemindersView.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//
import SwiftUI
import Factory

struct CompletedRemindersView: View {
    @Environment(\.container) private var container
    @StateObject private var viewModel: CompletedRemindersViewModel
    
    // Initialize with dependency injection
    init() {
        self._viewModel = StateObject(wrappedValue: Container.shared.completedRemindersViewModel())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.completedReminders.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "No Completed Reminders",
                        subtitle: "Complete some reminders to see your progress here"
                    )
                } else {
                    completedList
                }
            }
            .navigationTitle("Completed")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var completedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.completedReminders) { reminder in
                    CompletedReminderCardView(
                        reminder: reminder
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}
