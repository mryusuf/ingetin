//
//  IngetinApp.swift
//  Ingetin
//
//  Created by Indra on 25/06/25.
//

import SwiftUI

@main
struct IngetinApp: App {
    let persistenceController = PersistenceController()

    var body: some Scene {
        WindowGroup {
            Color.clear
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
