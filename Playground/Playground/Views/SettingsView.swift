//
//  SettingsView.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        @Bindable var viewModelBindable = viewModel
        
        NavigationStack {
            Form {
                Section("OpenAI") {
                    TextField("API Key", text: $viewModelBindable.openaiApiKey)
                }
                
                Section("OpenAI-compatible") {
                    TextField("API Key", text: $viewModelBindable.customApiKey)
                    TextField("Custom Chat Endpoint", text: $viewModelBindable.customChatEndpoint)
                    TextField("Custom Model Endpoint", text: $viewModelBindable.customModelEndpoint)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { dismiss() })
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveAction)
                        .disabled(viewModel.openaiApiKey.isEmpty && viewModel.customApiKey.isEmpty)
                }
            }
        }
    }
    
    func saveAction() {
        viewModel.saveSettings()
        
        Task {
            do {
                try await viewModel.fetchModels()
                
                if viewModel.models.count > 0 {
                    dismiss()
                }
            } catch {
                print(String(describing: error))
            }
        }
    }
}
