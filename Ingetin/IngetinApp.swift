//
//  IngetinApp.swift
//  Ingetin
//
//  Created by Indra on 25/06/25.
//

import SwiftUI
import Factory

@main
struct IngetinApp: App {
    @Injected(\.persistenceController) private var persistenceController
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(coordinator)
                .withDependencies()
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        BackgroundTaskManager.shared.registerBackgroundTasks()
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        Task {
            @Injected(\.notificationService) var notificationService
            let granted = await notificationService.requestPermission()
            debugPrint("Notification permission granted: \(granted)")
        }
    }
}
