//
//  NavigationTitle.swift
//  Playground
//
//  Created by Kevin Hermawan on 10/15/24.
//

import SwiftUI

struct NavigationTitle: View {
    @Environment(AppViewModel.self) private var viewModel
    
    private let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
            
            Text(viewModel.selectedModel)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
