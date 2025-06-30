//
//  CoreDataStatePublisher.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//

import Foundation
import CoreData
import Combine

final class CoreDataStatePublisher: ObservableObject {
    
    @Published var didChange = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.didChange.toggle()
                }
            }
            .store(in: &cancellables)
    }
}
