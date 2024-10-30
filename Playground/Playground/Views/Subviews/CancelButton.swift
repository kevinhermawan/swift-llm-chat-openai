//
//  CancelButton.swift
//  Playground
//
//  Created by Kevin Hermawan on 10/31/24.
//

import SwiftUI

struct CancelButton: View {
    private let onCancel: () -> Void
    
    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }
    
    var body: some View {
        Button(action: onCancel) {
            Text("Cancel")
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .padding([.horizontal, .bottom])
        .padding(.top, 8)
    }
}
