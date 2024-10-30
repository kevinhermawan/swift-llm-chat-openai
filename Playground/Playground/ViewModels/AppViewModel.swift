//
//  AppViewModel.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import Foundation
import AIModelRetriever
import LLMChatOpenAI

enum ServiceProvider: String, CaseIterable {
    case openai = "OpenAI"
    case openRouter = "OpenRouter"
    case groq = "Groq"
}

@MainActor
@Observable
final class AppViewModel {
    var stream: Bool = true
    var openaiAPIKey: String = ""
    var openRouterAPIKey: String = ""
    var groqAPIKey: String = ""
    
    var chat = LLMChatOpenAI(apiKey: "")
    var modelRetriever = AIModelRetriever()
    
    var models = [String]()
    var selectedModel: String = ""
    var systemPrompt: String = "You're a helpful AI assistant."
    var temperature = 0.5
    
    init() {
        loadDefaults()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(openaiAPIKey, forKey: "openaiAPIKey")
        UserDefaults.standard.set(openRouterAPIKey, forKey: "openRouterAPIKey")
        UserDefaults.standard.set(groqAPIKey, forKey: "groqAPIKey")
        
        loadDefaults()
    }
    
    private func loadDefaults() {
        if let newAPIKey = UserDefaults.standard.string(forKey: "openaiAPIKey") {
            self.openaiAPIKey = newAPIKey
        }
        
        if let newAPIKey = UserDefaults.standard.string(forKey: "openRouterAPIKey") {
            self.openRouterAPIKey = newAPIKey
        }
        
        if let newAPIKey = UserDefaults.standard.string(forKey: "groqAPIKey") {
            self.groqAPIKey = newAPIKey
        }
    }
    
    func setup(for provider: ServiceProvider) {
        switch provider {
        case .openai:
            setupOpenAI()
        case .openRouter:
            setupOpenRouter()
        case .groq:
            setupGroq()
        }
    }
}

// MARK: - OpenAI
private extension AppViewModel {
    func setupOpenAI() {
        chat = LLMChatOpenAI(apiKey: openaiAPIKey)
        
        Task {
            try await fetchOpenAIModels()
        }
    }
    
    func fetchOpenAIModels() async throws {
        let llmModels = try await modelRetriever.openAI(apiKey: openaiAPIKey)
        models = llmModels
            .filter {
                $0.id.contains("o1") ||
                $0.id.contains("gpt")
            }
            .map(\.id)
        
        if let firstModel = models.first {
            selectedModel = firstModel
        }
    }
}

// MARK: - OpenRouter
private extension AppViewModel {
    func setupOpenRouter() {
        guard let endpointURL = URL(string: "https://openrouter.ai/api/v1/chat/completions") else { return }
        
        chat = LLMChatOpenAI(apiKey: openRouterAPIKey, endpoint: endpointURL)
        
        Task {
            try await fetchOpenRouterModels()
        }
    }
    
    func fetchOpenRouterModels() async throws {
        guard let endpointURL = URL(string: "https://openrouter.ai/api/v1/models") else { return }
        
        let llmModels = try await modelRetriever.openAI(apiKey: openRouterAPIKey, endpoint: endpointURL)
        models = llmModels
            .filter {
                $0.id.contains("grok") ||
                $0.id.contains("llama-3.2")
            }
            .map(\.id)
        
        if let firstModel = models.first {
            selectedModel = firstModel
        }
    }
}

// MARK: - Groq
private extension AppViewModel {
    func setupGroq() {
        guard let endpointURL = URL(string: "https://api.groq.com/openai/v1/chat/completions") else { return }
        
        chat = LLMChatOpenAI(apiKey: groqAPIKey, endpoint: endpointURL)
        
        Task {
            try await fetchGroqModels()
        }
    }
    
    func fetchGroqModels() async throws {
        guard let endpointURL = URL(string: "https://api.groq.com/openai/v1/models") else { return }
        
        let llmModels = try await modelRetriever.openAI(apiKey: groqAPIKey, endpoint: endpointURL)
        models = llmModels
            .filter {
                $0.id.contains("llama-3.2")
            }
            .map(\.id)
        
        if let firstModel = models.first {
            selectedModel = firstModel
        }
    }
}
