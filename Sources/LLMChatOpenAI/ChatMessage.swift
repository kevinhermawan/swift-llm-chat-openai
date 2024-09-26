//
//  ChatMessage.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 9/14/24.
//

import Foundation

/// A struct that represents a message in a chat conversation.
public struct ChatMessage: Encodable {
    /// The role of the message's author.
    public let role: Role
    
    /// The contents of the message.
    public let content: [Content]
    
    /// An optional name for the participant.
    /// Provides the model information to differentiate between participants of the same role.
    public let name: String?
    
    public enum Role: String, Codable {
        case system
        case user
        case assistant
    }
    
    public enum Content: Encodable {
        /// Text content of the message.
        case text(String)
        
        /// Image content of the message.
        case image(String, detail: ImageDetail = .auto)
        
        public enum ImageDetail: String, Encodable, CaseIterable {
            /// High detail mode. The model first sees the low res image (using 85 tokens) and then creates detailed crops using 170 tokens for each 512px x 512px tile.
            case high
            
            /// Low detail mode. The model receives a low-res 512px x 512px version of the image, and represents the image with a budget of 85 tokens.
            /// This allows for faster responses and lower token consumption for use cases that don't require high detail.
            case low
            
            /// Automatic detail mode (default). The model looks at the image input size and decides whether to use the `low` or `high` setting.
            case auto
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .text)
            case .image(let imageString, let detail):
                try container.encode("image_url", forKey: .type)
                var imageContainer = container.nestedContainer(keyedBy: ImageCodingKeys.self, forKey: .imageUrl)
                try imageContainer.encode(imageString, forKey: .url)
                try imageContainer.encode(detail.rawValue, forKey: .detail)
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case type, text
            case imageUrl = "image_url"
        }
        
        private enum ImageCodingKeys: String, CodingKey {
            case url, detail
        }
    }
    
    /// Initializes a new ``ChatMessage``.
    public init(role: Role, content: [Content], name: String? = nil) {
        self.role = role
        self.content = content
        self.name = name
    }
    
    /// Initializes a new ``ChatMessage`` with a single text content.
    public init(role: Role, content: String, name: String? = nil) {
        self.init(role: role, content: [.text(content)], name: name)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        
        if content.count == 1, case .text(let text) = content[0] {
            try container.encode(text, forKey: .content)
        } else {
            try container.encode(content, forKey: .content)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case role, content, name
    }
}
