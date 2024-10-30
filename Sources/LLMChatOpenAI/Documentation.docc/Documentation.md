# ``LLMChatOpenAI``

Interact with OpenAI and OpenAI-compatible chat completion APIs in a simple and elegant way.

### Overview

``LLMChatOpenAI`` is a simple yet powerful Swift package that elegantly encapsulates the complexity of interacting with OpenAI and OpenAI-compatible chat completion APIs. It offers a complete set of Swift-idiomatic methods for sending chat completion requests and streaming responses.

## Usage

#### Initialization

```swift
import LLMChatOpenAI

// Basic initialization
let chat = LLMChatOpenAI(apiKey: "<YOUR_OPENAI_API_KEY>")

// Initialize with custom endpoint and headers
let chat = LLMChatOpenAI(
    apiKey: "<YOUR_API_KEY>",
    endpoint: URL(string: "https://custom-api.example.com/v1/chat/completions")!,
    headers: ["Custom-Header": "Value"]
)
```

#### Sending Chat Completion

```swift
let messages = [
    ChatMessage(role: .system, content: "You are a helpful assistant."),
    ChatMessage(role: .user, content: "What is the capital of Indonesia?")
]

let task = Task {
    do {
        let completion = try await chat.send(model: "gpt-4o", messages: messages)

        print(completion.choices.first?.message.content ?? "No response")
    } catch {
        print(String(describing: error))
    }
}

// To cancel completion
task.cancel()
```

#### Streaming Chat Completion

```swift
let messages = [
    ChatMessage(role: .system, content: "You are a helpful assistant."),
    ChatMessage(role: .user, content: "What is the capital of Indonesia?")
]

let task = Task {
    do {
        for try await chunk in chat.stream(model: "gpt-4o", messages: messages) {
            if let content = chunk.choices.first?.delta.content {
                print(content, terminator: "")
            }
        }
    } catch {
        print(String(describing: error))
    }
}

// To cancel completion
task.cancel()
```

#### Using Fallback Models (OpenRouter only)

```swift
Task {
    do {
        let completion = try await chat.send(models: ["openai/gpt-4o", "mistralai/mixtral-8x7b-instruct"], messages: messages)

        print(completion.choices.first?.message.content ?? "No response")
    } catch {
        print(String(describing: error))
    }
}

Task {
    do {
        for try await chunk in chat.stream(models: ["openai/gpt-4o", "mistralai/mixtral-8x7b-instruct"], messages: messages) {
            if let content = chunk.choices.first?.delta.content {
                print(content, terminator: "")
            }
        }
    } catch {
        print(String(describing: error))
    }
}
```

> **Note**: Fallback model functionality is only supported when using OpenRouter. If you use the fallback models method (`send(models:)` or `stream(models:)`) with other providers, only the first model in the array will be used, and the rest will be ignored. To learn more about fallback models, check out the [OpenRouter documentation](https://openrouter.ai/docs/model-routing).

### Advanced Usage

#### Vision

```swift
let messages = [
    ChatMessage(
        role: .user,
        content: [
            .image("https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg", detail: .high),
            .text("What is in this image?")
        ]
    )
]

Task {
    do {
        let completion = try await chat.send(model: "gpt-4o", messages: messages)

        print(completion.choices.first?.message.content ?? "")
    } catch {
        print(String(describing: error))
    }
}
```

To learn more about vision, check out the [OpenAI documentation](https://platform.openai.com/docs/guides/vision).

#### Function Calling

```swift
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
            required: ["reference_book", "genre"],
            additionalProperties: .boolean(false)
        ),
        strict: true
    )
)

let options = ChatOptions(tools: [recommendBookTool])

Task {
    do {
        let completion = try await chat.send(model: "gpt-4o", messages: messages, options: options)

        if let toolCalls = completion.choices.first?.message.toolCalls {
            print(toolCalls.first?.function.arguments ?? "")
        }
    } catch {
        print(String(describing: error))
    }
}
```

To learn more about function calling, check out the [OpenAI documentation](https://platform.openai.com/docs/guides/function-calling).

#### Structured Outputs

```swift
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

Task {
   do {
       let completion = try await chat.send(model: "gpt-4o", messages: messages, options: options)

       print(completion.choices.first?.message.content ?? "")
   } catch {
       print(String(describing: error))
   }
}
```

To learn more about structured outputs, check out the [OpenAI documentation](https://platform.openai.com/docs/guides/structured-outputs/introduction).

### Error Handling

``LLMChatOpenAI`` provides structured error handling through the ``LLMChatOpenAIError`` enum. This enum contains three cases that represent different types of errors you might encounter:

```swift
let messages = [
    ChatMessage(role: .system, content: "You are a helpful assistant."),
    ChatMessage(role: .user, content: "What is the capital of Indonesia?")
]

do {
    let completion = try await chat.send(model: "gpt-4o", messages: messages)

    print(completion.choices.first?.message.content ?? "No response")
} catch let error as LLMChatOpenAIError {
    switch error {
    case .serverError(let message):
        // Handle server-side errors (e.g., invalid API key, rate limits)
        print("Server Error: \(message)")
    case .networkError(let error):
        // Handle network-related errors (e.g., no internet connection)
        print("Network Error: \(error.localizedDescription)")
    case .decodingError(let error):
        // Handle errors that occur when the response cannot be decoded
        print("Decoding Error: \(error.localizedDescription)")
    case .streamError:
        // Handle errors that occur when streaming responses
        print("Stream Error")
    case .cancelled:
        // Handle requests that are cancelled
        print("Request was cancelled")
    }
} catch {
    // Handle any other errors
    print("An unexpected error occurred: \(error)")
}
```

## Related Packages

- [swift-ai-model-retriever](https://github.com/kevinhermawan/swift-ai-model-retriever)
- [swift-json-schema](https://github.com/kevinhermawan/swift-json-schema)
- [swift-llm-chat-anthropic](https://github.com/kevinhermawan/swift-llm-chat-anthropic)
