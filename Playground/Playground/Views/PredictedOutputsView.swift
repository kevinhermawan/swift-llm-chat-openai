//
//  PredictedOutputsView.swift
//  Playground
//
//  Created by Kevin Hermawan on 11/5/24.
//

import SwiftUI
import LLMChatOpenAI

struct PredictedOutputsView: View {
    let provider: ServiceProvider
    
    @Environment(AppViewModel.self) private var viewModel
    @State private var isPreferencesPresented: Bool = false
    
    @State private var prompt: String = "Replace the Username property with an Email property. Respond only with code, and with no markdown formatting."
    @State private var response: String = ""
    @State private var acceptedPredictionTokens: Int = 0
    @State private var rejectedPredictionTokens: Int = 0
    @State private var inputTokens: Int = 0
    @State private var outputTokens: Int = 0
    @State private var totalTokens: Int = 0
    
    private let prediction = """
    /// <summary>
    /// Represents a user with a first name, last name, and username.
    /// </summary>
    public class User
    {
        /// <summary>
        /// Gets or sets the user's first name.
        /// </summary>
        public string FirstName { get; set; }
    
        /// <summary>
        /// Gets or sets the user's last name.
        /// </summary>
        public string LastName { get; set; }
    
        /// <summary>
        /// Gets or sets the user's username.
        /// </summary>
        public string Username { get; set; }
    }
    """
    
    var body: some View {
        @Bindable var viewModelBindable = viewModel
        
        VStack {
            Form {
                Section("Prompt") {
                    TextField("Prompt", text: $prompt)
                }
                
                Section("Prediction") {
                    Text(prediction)
                }
                
                Section("Response") {
                    Text(response)
                }
                
                Section("Prediction Section") {
                    Text("Accepted Prediction Tokens")
                        .badge(acceptedPredictionTokens.formatted())
                    
                    Text("Rejected Prediction Tokens")
                        .badge(rejectedPredictionTokens.formatted())
                }
                
                UsageSection(inputTokens: inputTokens, outputTokens: outputTokens, totalTokens: totalTokens)
            }
            
            VStack {
                SendButton(stream: viewModel.stream, onSend: onSend, onStream: onStream)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavigationTitle("Predicted Outputs")
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
            ChatMessage(role: .user, content: prompt),
            ChatMessage(role: .user, content: prediction)
        ]
        
        let options = ChatOptions(
            prediction: .init(type: .content, content: [.init(type: "text", text: prediction)]),
            temperature: viewModel.temperature
        )
        
        Task {
            do {
                let completion = try await viewModel.chat.send(model: viewModel.selectedModel, messages: messages, options: options)
                
                if let content = completion.choices.first?.message.content {
                    self.response = content
                }
                
                if let usage = completion.usage {
                    if let completionTokensDetails = usage.completionTokensDetails {
                        self.acceptedPredictionTokens = completionTokensDetails.acceptedPredictionTokens
                        self.rejectedPredictionTokens = completionTokensDetails.rejectedPredictionTokens
                    }
                    
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
            ChatMessage(role: .user, content: prompt),
            ChatMessage(role: .user, content: prediction)
        ]
        
        let options = ChatOptions(
            prediction: .init(type: .content, content: prediction),
            temperature: viewModel.temperature
        )
        
        Task {
            do {
                for try await chunk in viewModel.chat.stream(model: viewModel.selectedModel, messages: messages, options: options) {
                    if let content = chunk.choices.first?.delta.content {
                        self.response += content
                    }
                    
                    if let usage = chunk.usage {
                        if let completionTokensDetails = usage.completionTokensDetails {
                            self.acceptedPredictionTokens = completionTokensDetails.acceptedPredictionTokens
                            self.rejectedPredictionTokens = completionTokensDetails.rejectedPredictionTokens
                        }
                        
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
        acceptedPredictionTokens = 0
        rejectedPredictionTokens = 0
        inputTokens = 0
        outputTokens = 0
        totalTokens = 0
    }
}
