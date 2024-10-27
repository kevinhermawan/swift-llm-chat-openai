//
//  LLMChatOpenAI.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 9/14/24.
//

import Foundation

/// A struct that facilitates interactions with OpenAI and OpenAI-compatible chat completion APIs.
public struct LLMChatOpenAI {
    private let apiKey: String
    private let endpoint: URL
    private var headers: [String: String]? = nil
    
    private var isSupportFallbackModel: Bool {
        endpoint.host == "openrouter.ai"
    }
    
    /// Creates a new instance of ``LLMChatOpenAI``.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key.
    ///   - endpoint: The OpenAI-compatible endpoint.
    ///   - headers: Additional HTTP headers to include in the requests.
    ///
    /// - Note: Make sure to include the complete URL for the `endpoint`, including the protocol (http:// or https://) and its path.
    public init(apiKey: String, endpoint: URL? = nil, headers: [String: String]? = nil) {
        self.apiKey = apiKey
        self.endpoint = endpoint ?? URL(string: "https://api.openai.com/v1/chat/completions")!
        self.headers = headers
    }
    
    private var allHeaders: [String: String] {
        var defaultHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        if let headers {
            defaultHeaders.merge(headers) { _, new in new }
        }
        
        return defaultHeaders
    }
}

// MARK: - Send
public extension LLMChatOpenAI {
    /// Sends a chat completion request.
    ///
    /// - Parameters:
    ///   - model: The model to use for completion.
    ///   - messages: An array of ``ChatMessage`` objects that represent the conversation history.
    ///   - options: Optional ``ChatOptions`` that customize the completion request.
    ///
    /// - Returns: A ``ChatCompletion`` object that contains the API's response.
    func send(model: String, messages: [ChatMessage], options: ChatOptions? = nil) async throws -> ChatCompletion {
        let body = RequestBody(stream: false, model: model, messages: messages, options: options)
        
        return try await performRequest(with: body)
    }
    
    /// Sends a chat completion request using fallback models (OpenRouter only).
    ///
    /// - Parameters:
    ///   - models: An array of models to use for completion, in order of preference.
    ///   - messages: An array of ``ChatMessage`` objects that represent the conversation history.
    ///   - options: Optional ``ChatOptions`` that customize the completion request.
    ///
    /// - Returns: A ``ChatCompletion`` object that contains the API's response.
    ///
    /// - Note: This method enables fallback functionality when using OpenRouter. For other providers, only the first model in the array will be used.
    func send(models: [String], messages: [ChatMessage], options: ChatOptions? = nil) async throws -> ChatCompletion {
        let body: RequestBody
        
        if isSupportFallbackModel {
            body = RequestBody(stream: false, models: models, messages: messages, options: options)
        } else {
            body = RequestBody(stream: false, model: models.first ?? "", messages: messages, options: options)
        }
        
        return try await performRequest(with: body)
    }
}

// MARK: - Stream
public extension LLMChatOpenAI {
    /// Streams a chat completion request.
    ///
    /// - Parameters:
    ///   - model: The model to use for completion.
    ///   - messages: An array of ``ChatMessage`` objects that represent the conversation history.
    ///   - options: Optional ``ChatOptions`` that customize the completion request.
    ///
    /// - Returns: An `AsyncThrowingStream` of ``ChatCompletionChunk`` objects.
    func stream(model: String, messages: [ChatMessage], options: ChatOptions? = nil) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
        let body = RequestBody(stream: true, model: model, messages: messages, options: options)
        
        return performStreamRequest(with: body)
    }
    
    /// Streams a chat completion request using fallback models (OpenRouter only).
    ///
    /// - Parameters:
    ///   - models: An array of models to use for completion, in order of preference.
    ///   - messages: An array of ``ChatMessage`` objects that represent the conversation history.
    ///   - options: Optional ``ChatOptions`` that customize the completion request.
    ///
    /// - Returns: An `AsyncThrowingStream` of ``ChatCompletionChunk`` objects.
    ///
    /// - Note: This method enables fallback functionality when using OpenRouter. For other providers, only the first model in the array will be used.
    func stream(models: [String], messages: [ChatMessage], options: ChatOptions? = nil) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
        let body: RequestBody
        
        if isSupportFallbackModel {
            body = RequestBody(stream: true, models: models, messages: messages, options: options)
        } else {
            body = RequestBody(stream: true, model: models.first ?? "", messages: messages, options: options)
        }
        
        return performStreamRequest(with: body)
    }
}

// MARK: - Helpers
private extension LLMChatOpenAI {
    func createRequest(for url: URL, with body: RequestBody) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)
        request.allHTTPHeaderFields = allHeaders
        
        return request
    }
    
    func performRequest(with body: RequestBody) async throws -> ChatCompletion {
        do {
            let request = try createRequest(for: endpoint, with: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let errorResponse = try? JSONDecoder().decode(ChatCompletionError.self, from: data) {
                throw LLMChatOpenAIError.serverError(errorResponse.error.message)
            }
            
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                throw LLMChatOpenAIError.badServerResponse
            }
            
            return try JSONDecoder().decode(ChatCompletion.self, from: data)
        } catch let error as LLMChatOpenAIError {
            throw error
        } catch {
            throw LLMChatOpenAIError.networkError(error)
        }
    }
    
    func performStreamRequest(with body: RequestBody) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try createRequest(for: endpoint, with: body)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                        for try await line in bytes.lines {
                            if let data = line.data(using: .utf8), let errorResponse = try? JSONDecoder().decode(ChatCompletionError.self, from: data) {
                                throw LLMChatOpenAIError.serverError(errorResponse.error.message)
                            }
                            
                            break
                        }
                        
                        throw LLMChatOpenAIError.badServerResponse
                    }
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = line.dropFirst(6)
                            
                            if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
                                break
                            }
                            
                            if let data = jsonString.data(using: .utf8) {
                                let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
                                
                                continuation.yield(chunk)
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch let error as LLMChatOpenAIError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(throwing: LLMChatOpenAIError.networkError(error))
                }
            }
        }
    }
}

// MARK: - Supporting Types
private extension LLMChatOpenAI {
    struct RequestBody: Encodable {
        let stream: Bool
        let model: String?
        let models: [String]?
        let messages: [ChatMessage]
        let options: ChatOptions?
        
        init(stream: Bool, model: String, messages: [ChatMessage], options: ChatOptions?) {
            self.stream = stream
            self.model = model
            self.models = nil
            self.messages = messages
            self.options = options
        }
        
        init(stream: Bool, models: [String], messages: [ChatMessage], options: ChatOptions?) {
            self.stream = stream
            self.model = nil
            self.models = models
            self.messages = messages
            self.options = options
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(stream, forKey: .stream)
            try container.encode(messages, forKey: .messages)
            
            if stream {
                try container.encode(["include_usage": true], forKey: .streamOptions)
            }
            
            if let model = model {
                try container.encode(model, forKey: .model)
            } else if let models = models {
                try container.encode(models, forKey: .models)
                try container.encode("fallback", forKey: .route)
            }
            
            if let options {
                try options.encode(to: encoder)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case stream, model, models, route, messages
            case streamOptions = "stream_options"
        }
    }
    
    struct ChatCompletionError: Codable {
        let error: Error
        
        struct Error: Codable {
            public let message: String
        }
    }
}
