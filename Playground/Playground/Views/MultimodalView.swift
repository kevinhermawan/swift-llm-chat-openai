//
//  MultimodalView.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI
import LLMChatOpenAI

struct MultimodalView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    @State private var imageDetail: ChatMessage.Content.ImageDetail = .auto
    
    @State private var image: String = "https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg"
    @State private var prompt: String = "What is in this image?"

    @State private var response: String = ""
    @State private var totalTokens: Int = 0
    
    var body: some View {
        @Bindable var viewModelBindable = viewModel
        
        VStack {
            Form {
                Section("Preferences") {
                    Toggle("Streaming", isOn: $viewModelBindable.streamMode)
                    
                    Picker("Model", selection: $viewModelBindable.selectedModel) {
                        ForEach(viewModelBindable.models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    
                    Picker("Image Detail", selection: $imageDetail) {
                        ForEach(ChatMessage.Content.ImageDetail.allCases, id: \.rawValue) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }
                
                Section("Prompt") {
                    TextField("Image", text: $image)
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
        .navigationTitle("Multimodal")
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
            ChatMessage(role: .user, content: [.text(prompt), .image(image, detail: imageDetail)])
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
            ChatMessage(role: .user, content: [.text(prompt), .image(image, detail: imageDetail)])
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
