//
//  FallbackModelView.swift
//  Playground
//
//  Created by Kevin Hermawan on 10/19/24.
//

import SwiftUI
import LLMChatOpenAI

struct FallbackModelView: View {
    let provider: ServiceProvider
    
    @Environment(AppViewModel.self) private var viewModel
    @State private var isPreferencesPresented: Bool = false
    
    @State private var fallbackModel: String = ""
    
    @State private var prompt: String = "Hi!"
    @State private var response: String = ""
    @State private var inputTokens: Int = 0
    @State private var outputTokens: Int = 0
    @State private var totalTokens: Int = 0
    
    var body: some View {
        @Bindable var viewModelBindable = viewModel
        
        VStack {
            Form {
                Section("Models") {
                    Picker("Primary Model", selection: $viewModelBindable.selectedModel) {
                        ForEach(viewModelBindable.models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    
                    Picker("Fallback Model", selection: $fallbackModel) {
                        ForEach(viewModelBindable.models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }
                .disabled(viewModel.models.isEmpty)
                
                Section("Prompt") {
                    TextField("Prompt", text: $prompt)
                }
                
                Section("Response") {
                    Text(response)
                }
                
                UsageSection(inputTokens: inputTokens, outputTokens: outputTokens, totalTokens: totalTokens)
            }
            
            VStack {
                SendButton(stream: viewModel.stream, onSend: onSend, onStream: onStream)
                    .disabled(viewModel.models.isEmpty)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavigationTitle("Fallback Model")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Preferences", systemImage: "gearshape", action: { isPreferencesPresented.toggle() })
            }
        }
        .sheet(isPresented: $isPreferencesPresented) {
            PreferencesView()
        }
        .onAppear {
            viewModel.setup(for: provider)
        }
        .onDisappear {
            viewModel.selectedModel = ""
        }
        .onChange(of: viewModel.models) { _, models in
            if let firstModel = models.first {
                fallbackModel = firstModel
            }
        }
    }
    
    private func onSend() {
        clear()
        
        let messages = [
            ChatMessage(role: .system, content: viewModel.systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]
        
        let options = ChatOptions(temperature: viewModel.temperature)
        
        Task {
            do {
                let completion = try await viewModel.chat.send(models: [viewModel.selectedModel, fallbackModel], messages: messages, options: options)
                
                if let content = completion.choices.first?.message.content {
                    self.response = content
                }
                
                if let usage = completion.usage {
                    self.inputTokens = usage.promptTokens
                    self.outputTokens = usage.completionTokens
                    self.totalTokens = usage.totalTokens
                }
            } catch {
                print(String(describing: error))
            }
        }
    }
    
    private func onStream() {
        clear()
        
        let messages = [
            ChatMessage(role: .system, content: viewModel.systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]
        
        let options = ChatOptions(temperature: viewModel.temperature)
        
        Task {
            do {
                for try await chunk in viewModel.chat.stream(models: [viewModel.selectedModel, fallbackModel], messages: messages, options: options) {
                    if let content = chunk.choices.first?.delta.content {
                        self.response += content
                    }
                    
                    if let usage = chunk.usage {
                        self.inputTokens = usage.promptTokens ?? 0
                        self.outputTokens = usage.completionTokens ?? 0
                        self.totalTokens = usage.totalTokens ?? 0
                    }
                }
            } catch {
                print(String(describing: error))
            }
        }
    }
    
    private func clear() {
        response = ""
        inputTokens = 0
        outputTokens = 0
        totalTokens = 0
    }
}
