//
//  VisionView.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI
import LLMChatOpenAI

struct VisionView: View {
    let provider: ServiceProvider
    
    @Environment(AppViewModel.self) private var viewModel
    @State private var isPreferencesPresented: Bool = false
    
    @State private var imageDetail: ChatMessage.Content.ImageDetail = .auto
    @State private var image: String = "https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg"
    @State private var prompt: String = "What is in this image?"
    
    @State private var response: String = ""
    @State private var inputTokens: Int = 0
    @State private var outputTokens: Int = 0
    @State private var totalTokens: Int = 0
    
    var body: some View {
        @Bindable var viewModelBindable = viewModel
        
        VStack {
            Form {
                Section("Prompt") {
                    TextField("Image", text: $image)
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
                NavigationTitle("Vision")
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
    }
    
    private func onSend() {
        clear()
        
        let messages = [
            ChatMessage(role: .user, content: [.text(prompt), .image(image, detail: imageDetail)])
        ]
        
        let options = ChatOptions(temperature: viewModel.temperature)
        
        Task {
            do {
                let completion = try await viewModel.chat.send(model: viewModel.selectedModel, messages: messages, options: options)
                
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
            ChatMessage(role: .user, content: [.text(prompt), .image(image, detail: imageDetail)])
        ]
        
        let options = ChatOptions(temperature: viewModel.temperature)
        
        Task {
            do {
                for try await chunk in viewModel.chat.stream(model: viewModel.selectedModel, messages: messages, options: options) {
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
