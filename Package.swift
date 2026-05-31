// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VXWalkthrough",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        // macOS is supported so the core models and SwiftUI views can be built
        // and unit-tested from the command line (`swift test`) and in CI.
        // The shipping product targets iOS / iPadOS / Mac Catalyst.
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "VXWalkthrough",
            targets: ["VXWalkthrough"]
        ),
        .library(
            name: "VXWalkthroughScanner",
            targets: ["VXWalkthroughScanner"]
        ),
        .library(
            name: "VXWalkthroughUIKit",
            targets: ["VXWalkthroughUIKit"]
        ),
    ],
    targets: [
        .target(
            name: "VXWalkthrough",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "VXWalkthroughScanner",
            dependencies: ["VXWalkthrough"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "VXWalkthroughUIKit",
            dependencies: ["VXWalkthrough"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "VXWalkthroughTests",
            dependencies: ["VXWalkthrough"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "VXWalkthroughScannerTests",
            dependencies: ["VXWalkthroughScanner"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
