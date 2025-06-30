//
//  Container+Extension.swift
//  Ingetin
//
//  Created by Indra on 27/06/25.
//

import Foundation
import Factory
import SwiftUI

// MARK: - SwiftUI Environment Integration
struct DependencyInjectionKey: EnvironmentKey {
    static let defaultValue = Container.shared
}

extension EnvironmentValues {
    var container: Container {
        get { self[DependencyInjectionKey.self] }
        set { self[DependencyInjectionKey.self] = newValue }
    }
}

// MARK: - SwiftUI View Extensions
extension View {
    func withDependencies(_ container: Container = .shared) -> some View {
        self.environment(\.container, container)
    }
    
    func withPreviewDependencies() -> some View {
        Container.setupPreviewContainer()
        return self.environment(\.container, .preview)
    }
}

// MARK: - Convenience Macros
extension Container {
    
    // MARK: - Quick Access Properties
    static var shared: Container = Container()
    
    // MARK: - Reset for Testing
    #if DEBUG
    static func reset() {
        shared = Container()
    }
    #endif
}
