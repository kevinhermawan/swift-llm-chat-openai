//
//  LLMChatOpenAIError.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 10/27/24.
//

import Foundation

/// An enum that represents errors from the chat completion request.
public enum LLMChatOpenAIError: LocalizedError {
    /// A case that represents a server-side error response.
    ///
    /// - Parameter message: The error message from the server.
    case serverError(String)
    
    /// A case that represents a network-related error.
    ///
    /// - Parameter error: The underlying network error.
    case networkError(Error)
    
    /// A case that represents an invalid server response.
    case badServerResponse
    
    /// A localized message that describes the error.
    public var errorDescription: String? {
        switch self {
        case .serverError(let error):
            return error
        case .networkError(let error):
            return error.localizedDescription
        case .badServerResponse:
            return "Invalid response received from server"
        }
    }
}
