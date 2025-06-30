//
//  CompletedReminderCardView.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//
import SwiftUI

struct CompletedReminderCardView: View {
    let reminder: Reminder
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let completedDate = reminder.completedAt {
                    Text("Completed \(completedDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4)
        )
    }
}
