//
//  ReminderCardView.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//

import SwiftUI

struct ReminderCardView: View {
    let reminder: Reminder
    let onComplete: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Time Display
            VStack(alignment: .leading, spacing: 4) {
                Text(timeString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(reminder.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .alert("Delete Reminder", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(reminder.name)'?")
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reminder.notificationTime)
    }
}
