//
//  ToolUseTests.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 9/28/24.
//

import XCTest
@testable import LLMChatOpenAI

final class ToolUseTests: XCTestCase {
    var chat: LLMChatOpenAI!
    var messages: [ChatMessage]!
    var options: ChatOptions!
    
    override func setUp() {
        super.setUp()
        
        chat = LLMChatOpenAI(apiKey: "mock-api-key")
        
        let recommendBookTool = ChatOptions.Tool(
            type: "function",
            function: .init(
                name: "recommend_book",
                description: "Recommend a book based on a given book and genre",
                parameters: .object(
                    properties: [
                        "reference_book": .string(description: "The name of a book the user likes"),
                        "genre": .enum(
                            description: "The preferred genre for the book recommendation",
                            values: [.string("fiction"), .string("non-fiction")]
                        )
                    ],
                    required: ["reference_book", "genre"]
                )
            )
        )
        
        messages = [ChatMessage(role: .user, content: "Recommend a book similar to '1984'")]
        options = ChatOptions(tools: [recommendBookTool])
        
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
    
    func testToolCalling() async throws {
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
                        "content": null,
                        "tool_calls": [
                            {
                                "id": "call_abc123",
                                "type": "function",
                                "function": {
                                    "name": "recommend_book",
                                    "arguments": "{\\"reference_book\\": \\"1984\\",\\"genre\\": \\"fiction\\"}"
                                }
                            }
                        ]
                    },
                    "finish_reason": "tool_calls"
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
        XCTAssertEqual(message?.toolCalls?.first?.function.name, "recommend_book")
        XCTAssertTrue(message?.toolCalls?.first?.function.arguments.contains("1984") ?? false)
        XCTAssertTrue(message?.toolCalls?.first?.function.arguments.contains("fiction") ?? false)
        
        // Usage
        XCTAssertEqual(completion.usage?.promptTokens, 20)
        XCTAssertEqual(completion.usage?.completionTokens, 30)
        XCTAssertEqual(completion.usage?.totalTokens, 50)
    }
    
    func testToolCallingStreaming() async throws {
        URLProtocolMock.mockStreamData = [
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":null,\"tool_calls\":[{\"index\":0,\"id\":\"call_abc123\",\"type\":\"function\",\"function\":{\"name\":\"recommend_book\",\"arguments\":\"\"}}]},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"tool_calls\":[{\"index\":0,\"function\":{\"arguments\":\"{\\n  \\\"reference_book\\\": \\\"1984\\\",\\n  \\\"genre\\\": \\\"fiction\\\"\\n}\"}}]},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"stop\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        
        var receivedArguments = ""
        
        for try await chunk in chat.stream(model: "gpt-4o", messages: messages, options: options) {
            if let toolCalls = chunk.choices.first?.delta.toolCalls {
                for toolCall in toolCalls {
                    receivedArguments += toolCall.function?.arguments ?? ""
                }
            }
        }
        
        XCTAssertTrue(receivedArguments.contains("1984"))
        XCTAssertTrue(receivedArguments.contains("fiction"))
    }
}
