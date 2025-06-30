//
//  AddReminderView.swift
//  Ingetin
//
//  Created by Indra on 25/06/25.
//
import SwiftUI
import Factory

struct AddReminderView: View {
    @Environment(\.container) private var container
    @StateObject private var viewModel: AddReminderViewModel
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    
    init() {
        self._viewModel = StateObject(wrappedValue: Container.shared.addReminderViewModel())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder Details")) {
                    TextField("Reminder name", text: $viewModel.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    DatePicker(
                        "Notification Time",
                        selection: $viewModel.selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                }
                
                Section(footer: Text("You'll be notified 10 minutes before the scheduled time.")) {
                    EmptyView()
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.saveReminder()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .fontWeight(.semibold)
                }
            }
            .alert("Permission Required", isPresented: $viewModel.showingPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive reminders.")
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
        }
    }
}
