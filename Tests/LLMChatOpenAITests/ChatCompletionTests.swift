//
//  ChatCompletionTests.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 9/28/24.
//

import XCTest
@testable import LLMChatOpenAI

final class ChatCompletionTests: XCTestCase {
    var chat: LLMChatOpenAI!
    var messages: [ChatMessage]!
    
    override func setUp() {
        super.setUp()
        
        chat = LLMChatOpenAI(apiKey: "mock-api-key")
        
        messages = [
            ChatMessage(role: .system, content: "You are a helpful assistant."),
            ChatMessage(role: .user, content: "What is the capital of Indonesia?")
        ]
        
        URLProtocol.registerClass(URLProtocolMock.self)
    }
    
    override func tearDown() {
        chat = nil
        messages = nil
        URLProtocolMock.mockData = nil
        URLProtocolMock.mockError = nil
        URLProtocolMock.mockStreamData = nil
        URLProtocol.unregisterClass(URLProtocolMock.self)
        
        super.tearDown()
    }
    
    func testSendChatCompletion() async throws {
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
                        "content": "The capital of Indonesia is Jakarta."
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 5,
                "completion_tokens": 10,
                "total_tokens": 15
            }
        }
        """
        
        URLProtocolMock.mockData = mockResponseString.data(using: .utf8)
        let completion = try await chat.send(model: "gpt-4o", messages: messages)
        let choice = completion.choices.first?.message.content
        
        XCTAssertEqual(choice, "The capital of Indonesia is Jakarta.")
        XCTAssertEqual(completion.usage?.promptTokens, 5)
        XCTAssertEqual(completion.usage?.completionTokens, 10)
        XCTAssertEqual(completion.usage?.totalTokens, 15)
    }
    
    func testStreamChatCompletion() async throws {
        URLProtocolMock.mockStreamData = [
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"The capital\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\" of Indonesia\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\" is Jakarta.\"},\"finish_reason\":\"stop\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        
        var receivedContent = ""
        
        for try await chunk in chat.stream(model: "gpt-4o", messages: messages) {
            if let content = chunk.choices.first?.delta.content {
                receivedContent += content
            }
        }
        
        XCTAssertEqual(receivedContent, "The capital of Indonesia is Jakarta.")
    }
}
