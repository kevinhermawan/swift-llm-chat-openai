//
//  ResponseFormatTests.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 9/28/24.
//

import XCTest
@testable import LLMChatOpenAI

final class ResponseFormatTests: XCTestCase {
    var chat: LLMChatOpenAI!
    var messages: [ChatMessage]!
    var options: ChatOptions!
    
    override func setUp() {
        super.setUp()
        
        chat = LLMChatOpenAI(apiKey: "mock-api-key")
        
        let responseFormat = ChatOptions.ResponseFormat(
            type: .jsonSchema,
            jsonSchema: .init(
                name: "get_book_info",
                schema: .object(
                    properties: [
                        "title": .string(description: "The title of the book"),
                        "author": .string(description: "The author of the book")
                    ],
                    required: ["title", "author"]
                )
            )
        )
        
        messages = [
            ChatMessage(role: .system, content: "You are a helpful assistant. Respond with a JSON object containing the book title and author."),
            ChatMessage(role: .user, content: "Can you recommend a philosophy book?")
        ]
        
        options = ChatOptions(responseFormat: responseFormat)
        
        URLProtocol.registerClass(URLProtocolMock.self)
    }
    
    override func tearDown() {
        chat = nil
        messages = nil
        options = nil
        URLProtocolMock.mockData = nil
        URLProtocolMock.mockError = nil
        URLProtocolMock.mockStreamData = nil
        URLProtocol.unregisterClass(URLProtocolMock.self)
        
        super.tearDown()
    }
    
    func testResponseFormat() async throws {
        let mockResponseString = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1694268190,
            "model": "gpt-4o",
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "{\\"title\\":\\"The Republic\\",\\"author\\":\\"Plato\\"}"
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 20,
                "completion_tokens": 30,
                "total_tokens": 50
            }
        }
        """
        
        URLProtocolMock.mockData = mockResponseString.data(using: .utf8)
        
        let completion = try await chat.send(model: "gpt-4o", messages: messages, options: options)
        let choice = completion.choices.first
        let message = choice?.message
        
        XCTAssertEqual(completion.id, "chatcmpl-123")
        XCTAssertEqual(completion.model, "gpt-4o")
        
        // Content
        XCTAssertEqual(message?.role, "assistant")
        XCTAssertEqual(message?.content, "{\"title\":\"The Republic\",\"author\":\"Plato\"}")
        
        // Usage
        XCTAssertEqual(completion.usage?.promptTokens, 20)
        XCTAssertEqual(completion.usage?.completionTokens, 30)
        XCTAssertEqual(completion.usage?.totalTokens, 50)
    }
    
    func testResponseFormatStreaming() async throws {
        URLProtocolMock.mockStreamData = [
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"{\\\"title\\\":\\\"\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"The Republic\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"\\\",\\\"author\\\":\\\"Plato\\\"}\"},\"finish_reason\":\"stop\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        
        var receivedContent = ""
        
        for try await chunk in chat.stream(model: "gpt-4o", messages: messages, options: options) {
            if let content = chunk.choices.first?.delta.content {
                receivedContent += content
            }
        }
        
        XCTAssertEqual(receivedContent, "{\"title\":\"The Republic\",\"author\":\"Plato\"}")
    }
}
