//
//  ToolUseView.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI
import LLMChatOpenAI

struct ToolUseView: View {
    let provider: ServiceProvider
    
    @Environment(AppViewModel.self) private var viewModel
    @State private var isPreferencesPresented: Bool = false
    
    @State private var prompt: String = "Recommend a book similar to '1984'"
    @State private var selectedToolChoiceKey: String = "auto"
    
    @State private var response: String = ""
    @State private var inputTokens: Int = 0
    @State private var outputTokens: Int = 0
    @State private var totalTokens: Int = 0
    
    private let toolChoices: [String: ChatOptions.ToolChoice] = [
        "none": .none,
        "auto": .auto,
        "recommend_book": .function(name: "recommend_book")
    ]
    
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
                Section("Prompt") {
                    TextField("Prompt", text: $prompt)
                }
                
                Section("Response") {
                    Text(response)
                }
                
                Section("Usage") {
                    Text("Input Tokens")
                        .badge(inputTokens.formatted())
                    
                    Text("Output Tokens")
                        .badge(outputTokens.formatted())
                    
                    Text("Total Tokens")
                        .badge(totalTokens.formatted())
                }
            }
            
            VStack {
                SendButton(stream: viewModel.stream, onSend: onSend, onStream: onStream)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavigationTitle("Tool Use")
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
        self.response = ""
        self.totalTokens = 0
        
        let messages = [
            ChatMessage(role: .system, content: viewModel.systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]
        
        let options = ChatOptions(
            temperature: viewModel.temperature,
            tools: [recommendBookTool],
            toolChoice: toolChoices[selectedToolChoiceKey]
        )
        
        Task {
            do {
                let completion = try await viewModel.chat.send(model: viewModel.selectedModel, messages: messages, options: options)
                
                if let toolCalls = completion.choices.first?.message.toolCalls {
                    self.response = toolCalls.first?.function.arguments ?? ""
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
        
        let options = ChatOptions(
            temperature: viewModel.temperature,
            tools: [recommendBookTool],
            toolChoice: toolChoices[selectedToolChoiceKey]
        )
        
        Task {
            do {
                for try await chunk in viewModel.chat.stream(model: viewModel.selectedModel, messages: messages, options: options) {
                    if let toolCalls = chunk.choices.first?.delta.toolCalls?.first {
                        self.response += toolCalls.function?.arguments ?? ""
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
