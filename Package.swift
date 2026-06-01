// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
// 6.1 is required for package traits (used to make system permissions opt-in).

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
            name: "VXWalkthroughPermissions",
            targets: ["VXWalkthroughPermissions"]
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
    // Per-permission traits (default: none enabled). Enabling a trait compiles
    // the matching system backend in `VXWalkthroughPermissions` and links only
    // that framework. With no traits enabled, the core references no
    // privacy-sensitive APIs (avoids App Store ITMS-90683 for unused strings).
    traits: [
        "PermissionsNotifications",
        "PermissionsCamera",
        "PermissionsMicrophone",
        "PermissionsPhotos",
        "PermissionsLocation",
        "PermissionsContacts",
        "PermissionsTracking",
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
            name: "VXWalkthroughPermissions",
            dependencies: ["VXWalkthrough"],
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
            dependencies: ["VXWalkthrough", "VXWalkthroughUIKit"],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "VXWalkthroughPermissionsTests",
            dependencies: ["VXWalkthroughPermissions"],
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
