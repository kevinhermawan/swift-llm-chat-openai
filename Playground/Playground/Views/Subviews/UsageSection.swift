//
//  UsageSection.swift
//  Playground
//
//  Created by Kevin Hermawan on 10/15/24.
//

import SwiftUI

struct UsageSection: View {
    private let inputTokens: Int
    private let outputTokens: Int
    private let totalTokens: Int
    
    init(inputTokens: Int, outputTokens: Int, totalTokens: Int) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
    }
    
    var body: some View {
        Section("Usage") {
            Text("Input Tokens")
                .badge(inputTokens.formatted())
            
            Text("Output Tokens")
                .badge(outputTokens.formatted())
            
            Text("Total Tokens")
                .badge(totalTokens.formatted())
        }
    }
}
