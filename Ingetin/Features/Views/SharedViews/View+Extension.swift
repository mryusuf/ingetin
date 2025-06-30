//
//  View+Extension.swift
//  Ingetin
//
//  Created by Indra on 30/06/25.
//

import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
    }
}
