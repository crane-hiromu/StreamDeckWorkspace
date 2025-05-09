// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamDeckPlugin",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/emorydunn/StreamDeckPlugin.git", from: "0.5.1")
    ],
    targets: [
        .executableTarget(
            name: "StreamDeckPlugin",
            dependencies: [
                .product(name: "StreamDeckPlugin", package: "StreamDeckPlugin")
            ]
        ),
    ]
)
