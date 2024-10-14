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
}

// MARK: - Helper Methods
private extension LLMChatOpenAI {
    var allHeaders: [String: String] {
        var defaultHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        if let headers {
            defaultHeaders.merge(headers) { _, new in new }
        }
        
        return defaultHeaders
    }
    
    func createRequest(for url: URL, with body: RequestBody) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)
        request.allHTTPHeaderFields = allHeaders
        
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
