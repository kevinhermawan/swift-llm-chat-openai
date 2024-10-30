//
//  LLMChatOpenAIError.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 10/27/24.
//

import Foundation

/// An enum that represents errors from the chat completion request.
public enum LLMChatOpenAIError: Error, Sendable {
    /// An error that occurs during JSON decoding.
    ///
    /// - Parameter error: The underlying decoding error.
    case decodingError(Error)
    
    /// An error that occurs during network operations.
    ///
    /// - Parameter error: The underlying network error.
    case networkError(Error)
    
    /// An error returned by the server.
    ///
    /// - Parameter message: The error message received from the server.
    case serverError(String)
    
    /// An error that occurs during stream processing.
    case streamError
    
    /// An error that occurs when the request is cancelled.
    case cancelled
}
