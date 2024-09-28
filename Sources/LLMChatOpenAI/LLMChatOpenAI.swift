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
    private let modelEndpoint: URL
    private var customHeaders: [String: String]? = nil
    
    /// Creates a new instance of ``LLMChatOpenAI``.
    ///
    /// - Parameter apiKey: Your OpenAI API key.
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        self.modelEndpoint = URL(string: "https://api.openai.com/v1/models")!
    }
    
    /// Creates a new instance of ``LLMChatOpenAI`` with custom endpoints and headers.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI-compatible API key.
    ///   - endpoint: The OpenAI-compatible endpoint for the chat completions API, including the scheme.
    ///   - modelEndpoint: The OpenAI-compatible endpoint for retrieving available models, including the scheme.
    ///   - customHeaders: Additional HTTP headers to include in the requests.
    ///
    /// - Note: Ensure you provide the complete URLs for both `endpoint` and `modelEndpoint`, including the scheme (http:// or https://) and the full path.
    public init(apiKey: String, endpoint: URL, modelEndpoint: URL, customHeaders: [String: String]? = nil) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.modelEndpoint = modelEndpoint
        self.customHeaders = customHeaders
    }
}

extension LLMChatOpenAI {
    /// Sends a chat completion request.
    ///
    /// - Parameters:
    ///   - model: The model to use for completion.
    ///   - messages: An array of ``ChatMessage`` objects that represent the conversation history.
    ///   - options: Optional ``ChatOptions`` that customize the completion request.
    ///
    /// - Returns: A `ChatCompletion` object that contains the API's response.
    public func send(model: String, messages: [ChatMessage], options: ChatOptions? = nil) async throws -> ChatCompletion {
        let body = RequestBody(stream: false, model: model, messages: messages, options: options)
        let request = try createRequest(for: endpoint, with: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response)
        
        return try JSONDecoder().decode(ChatCompletion.self, from: data)
    }
    
    /// Streams a chat completion request.
    ///
    /// - Parameters:
    ///   - model: The model to use for completion.
    ///   - messages: An array of ``ChatMessage`` objects that represent the conversation history.
    ///   - options: Optional ``ChatOptions`` that customize the completion request.
    ///
    /// - Returns: An `AsyncThrowingStream` of ``ChatCompletionChunk`` objects.
    public func stream(model: String, messages: [ChatMessage], options: ChatOptions? = nil) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let body = RequestBody(stream: true, model: model, messages: messages, options: options)
                    let request = try createRequest(for: endpoint, with: body)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    try validateHTTPResponse(response)
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = line.dropFirst(6)
                            
                            if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[DONE]" {
                                break
                            }
                            
                            if let data = jsonString.data(using: .utf8) {
                                do {
                                    let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
                                    continuation.yield(chunk)
                                } catch {
                                    continuation.finish(throwing: error)
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Retrieves the list of available models.
    ///
    /// - Returns: A ``ChatModel`` object containing information about available models.
    public func models() async throws -> ChatModel {
        var request = URLRequest(url: modelEndpoint)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = defaultHeaders
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response)
        
        return try JSONDecoder().decode(ChatModel.self, from: data)
    }
}

// MARK: - Helper Methods
private extension LLMChatOpenAI {
    var defaultHeaders: [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        if let customHeaders {
            headers.merge(customHeaders) { _, new in new }
        }
        
        return headers
    }
    
    func createRequest(for url: URL, with body: RequestBody) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)
        request.allHTTPHeaderFields = defaultHeaders
        
        return request
    }
    
    func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - Supporting Types
private extension LLMChatOpenAI {
    struct RequestBody: Encodable {
        let stream: Bool
        let model: String
        let messages: [ChatMessage]
        let options: ChatOptions?
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(stream, forKey: .stream)
            try container.encode(model, forKey: .model)
            try container.encode(messages, forKey: .messages)
            
            if stream {
                try container.encode(["include_usage": true], forKey: .streamOptions)
            }
            
            if let options {
                try options.encode(to: encoder)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case stream, model, messages
            case streamOptions = "stream_options"
        }
    }
}
