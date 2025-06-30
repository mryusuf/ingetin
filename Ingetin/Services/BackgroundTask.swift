//
//  BackgroundTask.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//

import Foundation
import BackgroundTasks

final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private let backgroundTaskIdentifier = "io.github.mryusuf.Ingetin"
    
    private init() {}
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            task.setTaskCompleted(success: true)
        }
        
        scheduleBackgroundRefresh()
    }
}
