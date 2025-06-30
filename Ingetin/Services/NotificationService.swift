//
//  NotificationService.swift
//  Ingetin
//
//  Created by Indra on 27/06/25.
//

import Foundation
import UserNotifications

// MARK: - Notification Service Protocol
protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleReminder(for reminder: Reminder) async throws
    func cancelReminder(identifier: String) async
    func cancelAllReminders()
    func getPendingNotifications() async -> [UNNotificationRequest]
    func handleNotificationResponse(_ response: UNNotificationResponse) async
}

// MARK: - Notification Errors
enum NotificationError: Error, LocalizedError {
    case permissionDenied
    case schedulingFailed(String)
    case invalidTime
    case notificationNotFound
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission denied"
        case .schedulingFailed(let reason):
            return "Failed to schedule notification: \(reason)"
        case .invalidTime:
            return "Invalid notification time"
        case .notificationNotFound:
            return "Notification not found"
        }
    }
}

// MARK: - Notification Categories
enum NotificationCategory: String, CaseIterable {
    case reminderAlert = "REMINDER_ALERT"
    
    var identifier: String { rawValue }
    
    var actions: [UNNotificationAction] {
        switch self {
        case .reminderAlert:
            return [
                UNNotificationAction(
                    identifier: "COMPLETE_ACTION",
                    title: "Mark Complete",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SNOOZE_ACTION",
                    title: "Snooze 10m",
                    options: []
                )
            ]
        }
    }
}

// MARK: - Notification Service Implementation
final class NotificationService: NSObject, NotificationServiceProtocol {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        setupNotificationCategories()
        notificationCenter.delegate = self
    }
    
    // MARK: - Permission Management
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .criticalAlert]
            )
            
            if granted {
                setupNotificationCategories()
            }
            
            return granted
        } catch {
            debugPrint("Permission request failed: \(error)")
            return false
        }
    }
    
    // MARK: - Scheduling
    func scheduleReminder(for reminder: Reminder) async throws {
        // Check permission first
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            throw NotificationError.permissionDenied
        }
        
        // Calculate notification time (10 minutes before target)
        guard let notificationTime = reminder.notificationDate else {
            throw NotificationError.invalidTime
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "Time for: \(reminder.name)"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.reminderAlert.identifier
        content.interruptionLevel = .timeSensitive
        
        content.userInfo = [
            "reminderId": reminder.id,
            "reminderName": reminder.name,
            "notificationTime": reminder.notificationTime.timeIntervalSince1970
        ]
        
        // Create trigger for daily repeat at notification time
        let timeComponents = Calendar.current.dateComponents(
            [.hour, .minute],
            from: notificationTime
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: timeComponents,
            repeats: true
        )
        
        let identifier = reminder.notificationId ?? ""
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            throw NotificationError.schedulingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Cancellation
    func cancelReminder(identifier: String) async {
        let pendingRequests = await getPendingNotifications()
        let pendingIds = pendingRequests.map { $0.identifier }
        
        if pendingIds.contains(identifier) {
            debugPrint("Found notification to cancel")
        } else {
            debugPrint("Notification with ID '\(identifier)' not found in pending notifications")
            debugPrint("Current pending IDs: \(pendingIds)")
        }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let remainingRequests = await getPendingNotifications()
        let wasRemoved = !remainingRequests.contains { $0.identifier == identifier }
        debugPrint(wasRemoved ? "Notification successfully cancelled" : "Notification still pending")
    }
    
    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Query
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Response Handling
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        guard let reminderIdString = userInfo["reminderId"] as? String,
              let reminderId = UUID(uuidString: reminderIdString) else {
            return
        }
        
        switch response.actionIdentifier {
        case "COMPLETE_ACTION":
            // Handle completion - this will be integrated with repository later
            await handleCompleteAction(reminderId: reminderId)
            
        case "SNOOZE_ACTION":
            // Handle snooze - schedule another notification in 10 minutes
            await handleSnoozeAction(reminderId: reminderId, userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            debugPrint("User opened app from notification for reminder: \(reminderId)")
            
        default:
            break
        }
    }
    
    // MARK: - Private Helpers
    private func setupNotificationCategories() {
        let categories = NotificationCategory.allCases.map { category in
            UNNotificationCategory(
                identifier: category.identifier,
                actions: category.actions,
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
        }
        
        notificationCenter.setNotificationCategories(Set(categories))
    }
    
    private func handleCompleteAction(reminderId: UUID) async {
        debugPrint("Marking reminder \(reminderId) as complete")
        await cancelReminder(identifier: "reminder-\(reminderId.uuidString)")
    }
    
    // Create snooze notification (10 minutes from now, one-time)
    private func handleSnoozeAction(reminderId: UUID, userInfo: [AnyHashable: Any]) async {
        guard let reminderName = userInfo["reminderName"] as? String else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Snoozed Reminder"
        content.body = "Time for: \(reminderName)"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.reminderAlert.identifier
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false) // 10 minutes
        let snoozeIdentifier = "snooze-\(reminderId.uuidString)-\(Date().timeIntervalSince1970)"
        
        let request = UNNotificationRequest(
            identifier: snoozeIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            debugPrint("Failed to schedule snooze notification: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            await handleNotificationResponse(response)
            completionHandler()
        }
    }
}

// MARK: - Mock Implementation for Testing/Previews
final class MockNotificationService: NotificationServiceProtocol {
    private var scheduledNotifications: [String: Reminder] = [:]
    
    func requestPermission() async -> Bool {
        return true
    }
    
    func scheduleReminder(for reminder: Reminder) async throws {
        let identifier = "mock-\(reminder.id)"
        scheduledNotifications[identifier] = reminder
    }
    
    func cancelReminder(identifier: String) {
        scheduledNotifications.removeValue(forKey: identifier)
    }
    
    func cancelAllReminders() {
        scheduledNotifications.removeAll()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return []
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        debugPrint("Mock: Handling notification response")
    }
}
