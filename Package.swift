// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "OS1",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "OS1",
            targets: ["OS1App"]
        ),
        .executable(
            name: "os1-cli",
            targets: ["os1-cli"]
        ),
        .library(
            name: "OS1Core",
            targets: ["OS1Core"]
        )
    ],
    dependencies: [
        .package(path: "Vendor/SwiftTerm"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.65.0")
    ],
    targets: [
        .target(
            name: "OS1Core",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ],
            path: "Sources/OS1",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "OS1App",
            dependencies: ["OS1Core"],
            path: "Sources/OS1App"
        ),
        .executableTarget(
            name: "os1-cli",
            dependencies: [
                "OS1Core",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/os1-cli"
        ),
        .testTarget(
            name: "OS1Tests",
            dependencies: ["OS1Core"],
            path: "Tests/OS1Tests"
        )
    ]
)
