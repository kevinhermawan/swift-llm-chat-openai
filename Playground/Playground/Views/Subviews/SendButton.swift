//
//  SendButton.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI

struct SendButton: View {
    private let stream: Bool
    private let onSend: () -> Void
    private let onStream: () -> Void
    
    init(stream: Bool, onSend: @escaping () -> Void, onStream: @escaping () -> Void) {
        self.stream = stream
        self.onSend = onSend
        self.onStream = onStream
    }
    
    var body: some View {
        Button(action: stream ? onStream : onSend) {
            Text(stream ? "Stream" : "Send")
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding([.horizontal, .bottom])
        .padding(.top, 8)
    }
}
