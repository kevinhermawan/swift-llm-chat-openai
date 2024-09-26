//
//  AppViewModel.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import Foundation
import LLMChatOpenAI

@Observable
final class AppViewModel {
    var streamMode: Bool = false
    var chat: LLMChatOpenAI
    
    var isUsingCustomApi: Bool = false {
        didSet {
            configureChat()
        }
    }
    
    var openaiApiKey: String = ""
    var customApiKey: String = ""
    var customChatEndpoint: String = "https://api.groq.com/openai/v1/chat/completions"
    var customModelEndpoint: String = "https://api.groq.com/openai/v1/models"
    
    var models = [String]()
    var selectedModel: String = ""
    
    init() {
        chat = LLMChatOpenAI(apiKey: "")
        
        loadSettings()
    }
    
    private func loadSettings() {
        isUsingCustomApi = UserDefaults.standard.bool(forKey: "isUsingCustomApi")
        openaiApiKey = UserDefaults.standard.string(forKey: "openaiApiKey") ?? ""
        customApiKey = UserDefaults.standard.string(forKey: "customApiKey") ?? ""
        customChatEndpoint = UserDefaults.standard.string(forKey: "customChatEndpoint") ?? customChatEndpoint
        customModelEndpoint = UserDefaults.standard.string(forKey: "customModelEndpoint") ?? customModelEndpoint
        
        configureChat()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isUsingCustomApi, forKey: "isUsingCustomApi")
        UserDefaults.standard.set(openaiApiKey, forKey: "openaiApiKey")
        UserDefaults.standard.set(customApiKey, forKey: "customApiKey")
        UserDefaults.standard.set(customChatEndpoint, forKey: "customChatEndpoint")
        UserDefaults.standard.set(customModelEndpoint, forKey: "customModelEndpoint")
        
        configureChat()
    }
    
    private func configureChat() {
        if isUsingCustomApi, let customChatEndpointURL = URL(string: customChatEndpoint), let customModelEndpointURL = URL(string: customModelEndpoint) {
            chat = LLMChatOpenAI(apiKey: customApiKey, endpoint: customChatEndpointURL, modelEndpoint: customModelEndpointURL)
        } else {
            chat = LLMChatOpenAI(apiKey: openaiApiKey)
        }
    }
    
    func fetchModels() async throws {
        let response = try await self.chat.models()
        
        if let firstModel = response.data.first?.id {
            models = response.data.map({ $0.id })
            selectedModel = firstModel
        }
    }
}
