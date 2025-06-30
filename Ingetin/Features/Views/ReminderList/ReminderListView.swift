//
//  ReminderListView.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//
import SwiftUI
import Factory

struct ReminderListView: View {
    @Environment(\.container) private var container
    @StateObject private var viewModel: ReminderListViewModel
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var showingSearchBar = false
    
    init() {
        self._viewModel = StateObject(wrappedValue: Container.shared.reminderListViewModel())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                if showingSearchBar {
                    searchAndFilterBar
                        .transition(.opacity)
                }
                
                // Content
                ZStack {
                    switch viewModel.state {
                    case .initial:
                        LoadingView()
                    case .loading:
                        LoadingView()
                    case .empty:
                        EmptyStateView(
                            icon: "bell.slash",
                            title: "No Reminders",
                            subtitle: "Add your first reminder to get started",
                            actionTitle: "Add Reminder",
                            action: coordinator.showAddReminder
                        )
                    case .loaded:
                        remindersList
                    }
                }
            }
            .navigationTitle("Daily Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { withAnimation { showingSearchBar.toggle() } }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: coordinator.showAddReminder) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .sheet(isPresented: $coordinator.isShowingAddReminder) {
                AddReminderView()
                .environmentObject(coordinator)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search reminders...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Sort Options
            Picker("Sort by", selection: $viewModel.sortOrder) {
                ForEach(ReminderListViewModel.SortOrder.allCases, id: \.self) { order in
                    Text(order.displayName).tag(order)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var remindersList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredReminders) { reminder in
                    ReminderCardView(
                        reminder: reminder,
                        onComplete: { viewModel.completeReminder(reminder) },
                        onDelete: { viewModel.deleteReminder(reminder) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}
