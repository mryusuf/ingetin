//
//  IngetinApp.swift
//  Ingetin
//
//  Created by Indra on 25/06/25.
//

import SwiftUI

@main
struct IngetinApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
