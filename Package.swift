// swift-tools-version: 5.8
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
        .package(url: "https://github.com/kevinhermawan/swift-json-schema.git", exact: "1.0.3"),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.3.0"))
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
