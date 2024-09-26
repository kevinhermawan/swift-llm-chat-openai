//
//  ResponseFormatView.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI
import LLMChatOpenAI

struct ResponseFormatView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    @State private var prompt: String = "Can you recommend a philosophy book?"
    @State private var responseFormatType: ChatOptions.ResponseFormat.ResponseType = .jsonSchema
    
    @State private var response: String = ""
    @State private var totalTokens: Int = 0
    
    private let systemMessage = ChatMessage(role: .system, content: "You are a helpful assistant. Respond with a JSON object containing the book title and author.")
    private let jsonSchema = ChatOptions.ResponseFormat.Schema(
        name: "get_book_info",
        schema: .object(
            properties: [
                "title": .string(description: "The title of the book"),
                "author": .string(description: "The author of the book")
            ],
            required: ["title", "author"]
        )
    )
    
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
                    
                    Picker("Response Format", selection: $responseFormatType) {
                        ForEach(ChatOptions.ResponseFormat.ResponseType.allCases, id: \.rawValue) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }
                
                Section("Prompt") {
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
        .navigationTitle("Response Format")
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
            systemMessage,
            ChatMessage(role: .user, content: prompt)
        ]
        
        let options = ChatOptions(responseFormat: .init(type: responseFormatType, jsonSchema: jsonSchema))
        
        Task {
            do {
                let completion = try await viewModel.chat.send(model: viewModel.selectedModel, messages: messages, options: options)
                
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
            systemMessage,
            ChatMessage(role: .user, content: prompt)
        ]
        
        let options = ChatOptions(responseFormat: .init(type: responseFormatType, jsonSchema: jsonSchema))
        
        Task {
            do {
                for try await chunk in viewModel.chat.stream(model: viewModel.selectedModel, messages: messages, options: options) {
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
