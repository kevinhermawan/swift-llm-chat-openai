//
//  ChatCompletionView.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI
import LLMChatOpenAI

struct ChatCompletionView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    @State private var systemPrompt: String = "You're a helpful assistant."
    @State private var prompt: String = "Hi!"
    
    @State private var response: String = ""
    @State private var totalTokens: Int = 0
    
    var body: some View {
        @Bindable var viewModelBindable = viewModel
        
        VStack {
            Form {
                Section("Preferences") {
                    Toggle("Stream Mode", isOn: $viewModelBindable.streamMode)
                    
                    Picker("Model", selection: $viewModelBindable.selectedModel) {
                        ForEach(viewModelBindable.models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }
                
                Section("Prompts") {
                    TextField("System Prompt", text: $systemPrompt)
                    TextField("Prompt", text: $prompt)
                }
                
                Section("Response") {
                    Text(response)
                }
                
                Section("Total Tokens") {
                    Text(totalTokens.formatted())
                }
            }
            
            VStack {
                SendButton(stream: viewModel.streamMode, onSend: onSend, onStream: onStream)
            }
        }
        .navigationTitle("Chat Completion")
        .task {
            Task {
                do {
                    try await viewModel.fetchModels()
                } catch {
                    print(String(describing: error))
                }
            }
        }
    }
    
    private func onSend() {
        self.response = ""
        self.totalTokens = 0
        
        let messages = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]
        
        Task {
            do {
                let completion = try await viewModel.chat.send(model: viewModel.selectedModel, messages: messages)
                
                if let content = completion.choices.first?.message.content {
                    self.response = content
                }
                
                if let totalTokens = completion.usage?.totalTokens {
                    self.totalTokens = totalTokens
                }
            } catch {
                print(String(describing: error))
            }
        }
    }
    
    private func onStream() {
        self.response = ""
        self.totalTokens = 0
        
        let messages = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]
        
        Task {
            do {
                for try await chunk in viewModel.chat.stream(model: viewModel.selectedModel, messages: messages) {
                    if let content = chunk.choices.first?.delta.content {
                        self.response += content
                    }
                    
                    if let totalTokens = chunk.usage?.totalTokens {
                        self.totalTokens = totalTokens
                    }
                }
            } catch {
                print(String(describing: error))
            }
        }
    }
}
