//
//  RetrieveModelsTests.swift
//  LLMChatOpenAI
//
//  Created by Kevin Hermawan on 9/28/24.
//

import XCTest
@testable import LLMChatOpenAI

final class RetrieveModelsTests: XCTestCase {
    var chat: LLMChatOpenAI!
    
    override func setUp() {
        super.setUp()
        
        chat = LLMChatOpenAI(apiKey: "mock-api-key")
        
        URLProtocol.registerClass(URLProtocolMock.self)
    }
    
    override func tearDown() {
        chat = nil
        URLProtocolMock.mockData = nil
        URLProtocolMock.mockError = nil
        URLProtocolMock.mockStreamData = nil
        URLProtocol.unregisterClass(URLProtocolMock.self)
        
        super.tearDown()
    }
    
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
        
        URLProtocolMock.mockData = mockResponseString.data(using: .utf8)
        
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
}
