//
//  ChatModel.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 9/14/24.
//

import Foundation

/// A struct that represents a chat model response.
public struct ChatModel: Codable {
    /// An array of ``Model`` objects that contains about available models.
    public let data: [Model]
    
    public struct Model: Codable {
        /// The model identifier.
        public let id: String
        
        /// The Unix timestamp (in seconds) when the model was created.
        public let created: Int
        
        /// The object type, which is always `model`.
        public let object: String
        
        /// The organization that owns the model.
        public let ownedBy: String
        
        private enum CodingKeys: String, CodingKey {
            case id, created, object
            case ownedBy = "owned_by"
        }
    }
}
