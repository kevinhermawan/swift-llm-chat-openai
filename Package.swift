// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LLMChatOpenAI",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "LLMChatOpenAI",
            targets: ["LLMChatOpenAI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kevinhermawan/swift-json-schema.git", .upToNextMajor(from: "2.0.1")),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.4.3"))
    ],
    targets: [
        .target(
            name: "LLMChatOpenAI",
            dependencies: [.product(name: "JSONSchema", package: "swift-json-schema")]
        ),
        .testTarget(
            name: "LLMChatOpenAITests",
            dependencies: ["LLMChatOpenAI"]
        )
    ]
)
