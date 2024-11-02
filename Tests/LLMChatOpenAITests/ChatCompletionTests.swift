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
        URLProtocolMock.reset()
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
        let mockResponse = """
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
        
        URLProtocolMock.mockData = mockResponse.data(using: .utf8)
        let completion = try await chat.send(model: "gpt-4o", messages: messages)
        let choice = completion.choices.first
        let message = choice?.message
        
        XCTAssertEqual(completion.id, "chatcmpl-123")
        XCTAssertEqual(completion.model, "gpt-4o")
        
        // Content
        XCTAssertEqual(message?.role, "assistant")
        XCTAssertEqual(message?.content, "The capital of Indonesia is Jakarta.")
        
        // Usage
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
    
    func testSendChatCompletionWithFallbackModels() async throws {
        let mockResponse = """
        {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": 1694268190,
            "model": "openai/gpt-4o",
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
        
        URLProtocolMock.mockData = mockResponse.data(using: .utf8)
        let completion = try await chat.send(models: ["openai/gpt-4o", "mistralai/mixtral-8x7b-instruct"], messages: messages)
        let choice = completion.choices.first
        let message = choice?.message
        
        XCTAssertEqual(completion.id, "chatcmpl-123")
        XCTAssertEqual(completion.model, "openai/gpt-4o")
        
        // Content
        XCTAssertEqual(message?.role, "assistant")
        XCTAssertEqual(message?.content, "The capital of Indonesia is Jakarta.")
        
        // Usage
        XCTAssertEqual(completion.usage?.promptTokens, 5)
        XCTAssertEqual(completion.usage?.completionTokens, 10)
        XCTAssertEqual(completion.usage?.totalTokens, 15)
    }
    
    func testStreamChatCompletionWithFallbackModels() async throws {
        URLProtocolMock.mockStreamData = [
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"openai/gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"The capital\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"openai/gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\" of Indonesia\"},\"finish_reason\":null}]}\n\n",
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"openai/gpt-4o\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\" is Jakarta.\"},\"finish_reason\":\"stop\"}]}\n\n",
            "data: [DONE]\n\n"
        ]
        
        var receivedContent = ""
        
        for try await chunk in chat.stream(models: ["openai/gpt-4o", "mistralai/mixtral-8x7b-instruct"], messages: messages) {
            if let content = chunk.choices.first?.delta.content {
                receivedContent += content
            }
        }
        
        XCTAssertEqual(receivedContent, "The capital of Indonesia is Jakarta.")
    }
}

// MARK: - Error Handling
extension ChatCompletionTests {
    func testServerError() async throws {
        let mockErrorResponse = """
        {
            "error": {
                "message": "Invalid API key provided"
            }
        }
        """
        
        URLProtocolMock.mockData = mockErrorResponse.data(using: .utf8)
        URLProtocolMock.mockStatusCode = 401
        
        do {
            _ = try await chat.send(model: "gpt-4o", messages: messages)
            
            XCTFail("Expected serverError to be thrown")
        } catch let error as LLMChatOpenAIError {
            switch error {
            case .serverError(let statusCode, let message):
                XCTAssertEqual(statusCode, 401)
                XCTAssertEqual(message, "Invalid API key provided")
            default:
                XCTFail("Expected serverError but got \(error)")
            }
        }
    }
    
    func testNetworkError() async throws {
        URLProtocolMock.mockError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )
        
        do {
            _ = try await chat.send(model: "gpt-4o", messages: messages)
            
            XCTFail("Expected networkError to be thrown")
        } catch let error as LLMChatOpenAIError {
            switch error {
            case .networkError(let underlyingError):
                XCTAssertEqual((underlyingError as NSError).code, NSURLErrorNotConnectedToInternet)
            default:
                XCTFail("Expected networkError but got \(error)")
            }
        }
    }
    
    func testHTTPError() async throws {
        URLProtocolMock.mockData = "Rate limit exceeded".data(using: .utf8)
        URLProtocolMock.mockStatusCode = 429
        
        do {
            _ = try await chat.send(model: "gpt-4o", messages: messages)
            
            XCTFail("Expected serverError to be thrown")
        } catch let error as LLMChatOpenAIError {
            switch error {
            case .serverError(let statusCode, let message):
                XCTAssertEqual(statusCode, 429)
                XCTAssertTrue(message.contains("429"))
            default:
                XCTFail("Expected serverError but got \(error)")
            }
        }
    }
    
    func testDecodingError() async throws {
        let invalidJSON = "{ invalid json }"
        URLProtocolMock.mockData = invalidJSON.data(using: .utf8)
        
        do {
            _ = try await chat.send(model: "gpt-4o", messages: messages)
            
            XCTFail("Expected decodingError to be thrown")
        } catch let error as LLMChatOpenAIError {
            switch error {
            case .decodingError:
                break
            default:
                XCTFail("Expected decodingError but got \(error)")
            }
        }
    }
    
    func testCancellation() async throws {
        let task = Task {
            _ = try await chat.send(model: "gpt-4o", messages: messages)
        }
        
        task.cancel()
        
        do {
            _ = try await task.value
            
            XCTFail("Expected cancelled error to be thrown")
        } catch let error as LLMChatOpenAIError {
            switch error {
            case .cancelled:
                break
            default:
                XCTFail("Expected cancelled but got \(error)")
            }
        }
    }
}

// MARK: - Error Handling (Stream)
extension ChatCompletionTests {
    func testStreamServerError() async throws {
        URLProtocolMock.mockStreamData = ["data: {\"error\": {\"message\": \"Server error occurred\", \"type\": \"server_error\", \"code\": \"internal_error\"}}\n\n"]
        
        do {
            for try await _ in chat.stream(model: "gpt-4o", messages: messages) {
                XCTFail("Expected streamError to be thrown")
            }
        } catch let error as LLMChatOpenAIError {
            switch error {
            case .streamError:
                break
            default:
                XCTFail("Expected streamError but got \(error)")
            }
        }
    }
    
    func testStreamNetworkError() async throws {
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNetworkConnectionLost,
            userInfo: [NSLocalizedDescriptionKey: "The network connection was lost."]
        )
        
        URLProtocolMock.mockError = networkError
        
        do {
            for try await _ in chat.stream(model: "gpt-4o", messages: messages) {
                XCTFail("Expected networkError to be thrown")
            }
        } catch let error as LLMChatOpenAIError {
            switch error {
            case .networkError(let underlyingError):
                XCTAssertEqual((underlyingError as NSError).code, NSURLErrorNetworkConnectionLost)
            default:
                XCTFail("Expected networkError but got \(error)")
            }
        }
    }
    
    func testStreamHTTPError() async throws {
        URLProtocolMock.mockStreamData = [""]
        URLProtocolMock.mockStatusCode = 503
        
        do {
            for try await _ in chat.stream(model: "gpt-4o", messages: messages) {
                XCTFail("Expected serverError to be thrown")
            }
        } catch let error as LLMChatOpenAIError {
            switch error {
            case .serverError(let statusCode, let message):
                XCTAssertEqual(statusCode, 503)
                XCTAssertTrue(message.contains("503"))
            default:
                XCTFail("Expected serverError but got \(error)")
            }
        }
    }
    
    func testStreamDecodingError() async throws {
        URLProtocolMock.mockStreamData = ["data: { invalid json }\n\n"]
        
        do {
            for try await _ in chat.stream(model: "gpt-4o", messages: messages) {
                XCTFail("Expected decodingError to be thrown")
            }
        } catch let error as LLMChatOpenAIError {
            switch error {
            case .decodingError:
                break
            default:
                XCTFail("Expected decodingError but got \(error)")
            }
        }
    }
    
    func testStreamCancellation() async throws {
        URLProtocolMock.mockStreamData = Array(repeating: "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1694268190,\"model\":\"gpt-3.5-turbo-0613\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"test\"},\"finish_reason\":null}]}\n\n", count: 1000)
        
        let expectation = XCTestExpectation(description: "Stream cancelled")
        
        let task = Task {
            do {
                for try await _ in chat.stream(model: "gpt-4o", messages: messages) {
                    try await Task.sleep(nanoseconds: 100_000_000) // 1 second
                }
                
                XCTFail("Expected stream to be cancelled")
            } catch is CancellationError {
                expectation.fulfill()
            } catch {
                XCTFail("Expected CancellationError but got \(error)")
            }
        }
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
}
