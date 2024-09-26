//
//  ToolCallingView.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI
import LLMChatOpenAI

struct ToolCallingView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    @State private var prompt: String = "Recommend a book similar to '1984'"
    
    @State private var response: String = ""
    @State private var totalTokens: Int = 0
    
    private let recommendBookTool = ChatOptions.Tool(
        type: "function",
        function: .init(
            name: "recommend_book",
            description: "Recommend a book based on a given book and genre",
            parameters: .object(
                properties: [
                    "reference_book": .string(description: "The name of a book the user likes"),
                    "genre": .enum(
                        description: "The preferred genre for the book recommendation",
                        values: [.string("fiction"), .string("non-fiction")]
                    )
                ],
                required: ["reference_book", "genre"],
                additionalProperties: .boolean(false)
            ),
            strict: true
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
                            Text(model)
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
        .navigationTitle("Tool Calling")
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
        
        let messages = [ChatMessage(role: .user, content: prompt)]
        let options = ChatOptions(tools: [recommendBookTool])
        
        Task {
            do {
                let completion = try await viewModel.chat.send(model: viewModel.selectedModel, messages: messages, options: options)
                
                if let toolCalls = completion.choices.first?.message.toolCalls {
                    self.response = toolCalls.first?.function.arguments ?? ""
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
        
        let messages = [ChatMessage(role: .user, content: prompt)]
        let options = ChatOptions(tools: [recommendBookTool])
        
        Task {
            do {
                for try await chunk in viewModel.chat.stream(model: viewModel.selectedModel, messages: messages, options: options) {
                    if let toolCalls = chunk.choices.first?.delta.toolCalls?.first {
                        self.response += toolCalls.function?.arguments ?? ""
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
