//
//  LLMChatOpenAITests.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 9/27/24.
//

import XCTest
@testable import LLMChatOpenAI

class LLMChatOpenAITests: XCTestCase {
    var chat: LLMChatOpenAI!
    let mockAPIKey = "mock-api-key"
    
    override func setUp() {
        super.setUp()
        
        URLProtocol.registerClass(MockURLProtocol.self)
        chat = LLMChatOpenAI(apiKey: mockAPIKey)
    }
    
    override func tearDown() {
        chat = nil
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockError = nil
        MockURLProtocol.mockStreamData = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
        
        super.tearDown()
    }
    
    // MARK: - Chat Completion
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
        
        MockURLProtocol.mockData = mockResponseString.data(using: .utf8)
        
        let messages = [
            ChatMessage(role: .system, content: "You are a helpful assistant."),
            ChatMessage(role: .user, content: "What is the capital of Indonesia?")
        ]
        
        let completion = try await chat.send(model: "gpt-4o", messages: messages)
        
        XCTAssertEqual(completion.id, "chatcmpl-123")
        XCTAssertEqual(completion.object, "chat.completion")
        XCTAssertEqual(completion.created, 1694268190)
        XCTAssertEqual(completion.model, "gpt-4o")
        XCTAssertEqual(completion.choices.count, 1)
        
        if let firstChoice = completion.choices.first {
            XCTAssertEqual(firstChoice.index, 0)
            XCTAssertEqual(firstChoice.finishReason, .stop)
            XCTAssertEqual(firstChoice.message.role, "assistant")
            XCTAssertEqual(firstChoice.message.content, "The capital of Indonesia is Jakarta.")
        } else {
            XCTFail("No choices found in the completion")
        }
        
        XCTAssertEqual(completion.usage?.promptTokens, 5)
        XCTAssertEqual(completion.usage?.completionTokens, 10)
        XCTAssertEqual(completion.usage?.totalTokens, 15)
    }
    
    func testStreamChatCompletion() async throws {
        MockURLProtocol.mockStreamData = [
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"The capital\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\" of Indonesia\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\" is Jakarta.\"},\"finish_reason\":\"stop\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        
        let messages = [
            ChatMessage(role: .system, content: "You are a helpful assistant."),
            ChatMessage(role: .user, content: "What is the capital of Indonesia?")
        ]
        
        var receivedContent = ""
        
        for try await chunk in chat.stream(model: "gpt-4o", messages: messages) {
            if let content = chunk.choices.first?.delta.content {
                receivedContent += content
            }
        }
        
        XCTAssertEqual(receivedContent, "The capital of Indonesia is Jakarta.")
    }
    
    // MARK: - Model
    func testRetrieveModels() async throws {
        let mockResponseString = """
        {
            "object": "list",
            "data": [
                {
                    "id": "gpt-4o",
                    "object": "model",
                    "created": 1694268190,
                    "owned_by": "openai"
                },
                {
                    "id": "gpt-3.5-turbo",
                    "object": "model",
                    "created": 1694268190,
                    "owned_by": "openai"
                }
            ]
        }
        """
        
        MockURLProtocol.mockData = mockResponseString.data(using: .utf8)
        
        let models = try await chat.models()
        XCTAssertEqual(models.data.count, 2)
        
        XCTAssertEqual(models.data[0].id, "gpt-4o")
        XCTAssertEqual(models.data[0].object, "model")
        XCTAssertEqual(models.data[0].created, 1694268190)
        XCTAssertEqual(models.data[0].ownedBy, "openai")
        
        XCTAssertEqual(models.data[1].id, "gpt-3.5-turbo")
        XCTAssertEqual(models.data[1].object, "model")
        XCTAssertEqual(models.data[1].created, 1694268190)
        XCTAssertEqual(models.data[1].ownedBy, "openai")
    }
    
    // MARK: - Multimodal
    func testMultimodalInput() async throws {
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
                        "content": "The image shows a cute kitten or young cat."
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 50,
                "completion_tokens": 80,
                "total_tokens": 130
            }
        }
        """
        
        MockURLProtocol.mockData = mockResponseString.data(using: .utf8)
        
        let messages = [
            ChatMessage(
                role: .user,
                content: [
                    .image("https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg", detail: .high),
                    .text("What is in this image?")
                ]
            )
        ]
        
        let completion = try await chat.send(model: "gpt-4o", messages: messages)
        
        XCTAssertTrue(completion.choices.first?.message.content?.contains("kitten") ?? false)
    }
    
    func testMultimodalInputStreaming() async throws {
        MockURLProtocol.mockStreamData = [
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"The image shows\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\" a cute kitten\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\" or young cat.\"},\"finish_reason\":\"stop\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        
        let messages = [
            ChatMessage(
                role: .user,
                content: [
                    .image("https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg", detail: .high),
                    .text("What is in this image?")
                ]
            )
        ]
        
        var receivedContent = ""
        
        for try await chunk in chat.stream(model: "gpt-4o", messages: messages) {
            if let content = chunk.choices.first?.delta.content {
                receivedContent += content
            }
        }
        
        XCTAssertTrue(receivedContent.contains("kitten"))
        XCTAssertTrue(receivedContent.contains("young cat"))
    }
    
    // MARK: - Tool Calling
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
        
        MockURLProtocol.mockData = mockResponseString.data(using: .utf8)
        
        let messages = [
            ChatMessage(role: .user, content: "Recommend a book similar to '1984'")
        ]
        
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
        
        let options = ChatOptions(tools: [recommendBookTool])
        
        let completion = try await chat.send(model: "gpt-4o", messages: messages, options: options)
        let toolCall = completion.choices.first?.message.toolCalls?.first
        
        XCTAssertEqual(toolCall?.function.name, "recommend_book")
        XCTAssertTrue(toolCall?.function.arguments.contains("1984") ?? false)
        XCTAssertTrue(toolCall?.function.arguments.contains("fiction") ?? false)
    }
    
    func testToolCallingStreaming() async throws {
        MockURLProtocol.mockStreamData = [
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":null,\"tool_calls\":[{\"index\":0,\"id\":\"call_abc123\",\"type\":\"function\",\"function\":{\"name\":\"recommend_book\",\"arguments\":\"\"}}]},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"tool_calls\":[{\"index\":0,\"function\":{\"arguments\":\"{\\n  \\\"reference_book\\\": \\\"1984\\\",\\n  \\\"genre\\\": \\\"fiction\\\"\\n}\"}}]},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{},\"finish_reason\":\"stop\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        
        let messages = [
            ChatMessage(role: .user, content: "Recommend a book similar to '1984'")
        ]
        
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
        
        let options = ChatOptions(tools: [recommendBookTool])
        
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
    
    // MARK: - Response Format
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
        
        MockURLProtocol.mockData = mockResponseString.data(using: .utf8)
        
        let messages = [
            ChatMessage(role: .system, content: "You are a helpful assistant. Respond with a JSON object containing the book title and author."),
            ChatMessage(role: .user, content: "Can you recommend a philosophy book?")
        ]
        
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
        
        let options = ChatOptions(responseFormat: responseFormat)
        
        let completion = try await chat.send(model: "gpt-4o", messages: messages, options: options)
        let content = completion.choices.first?.message.content ?? ""
        
        XCTAssertTrue(content.contains("The Republic"))
        XCTAssertTrue(content.contains("Plato"))
    }
    
    func testResponseFormatStreaming() async throws {
        MockURLProtocol.mockStreamData = [
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"{\\\"title\\\":\\\"\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"The Republic\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"\\\",\\\"author\\\":\\\"Plato\\\"}\"},\"finish_reason\":\"stop\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        
        let messages = [
            ChatMessage(role: .system, content: "You are a helpful assistant. Respond with a JSON object containing the book title and author."),
            ChatMessage(role: .user, content: "Can you recommend a philosophy book?")
        ]
        
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
        
        let options = ChatOptions(responseFormat: responseFormat)
        
        var receivedContent = ""
        for try await chunk in chat.stream(model: "gpt-4o", messages: messages, options: options) {
            if let content = chunk.choices.first?.delta.content {
                receivedContent += content
            }
        }
        
        XCTAssertTrue(receivedContent.contains("The Republic"))
        XCTAssertTrue(receivedContent.contains("Plato"))
    }
}

// MARK: - Mocks
class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockError: Error?
    static var mockStreamData: [String]?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let client = client else { return }
        
        if let error = MockURLProtocol.mockError {
            client.urlProtocol(self, didFailWithError: error)
            return
        }
        
        if let streamData = MockURLProtocol.mockStreamData {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            for line in streamData {
                client.urlProtocol(self, didLoad: Data(line.utf8))
            }
        } else if let data = MockURLProtocol.mockData {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: data)
        } else {
            client.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock data available"]))
            return
        }
        
        client.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
