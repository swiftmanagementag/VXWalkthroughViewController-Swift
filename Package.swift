// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VXWalkthroughViewController-Swift",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "VXWalkthrough",
            targets: ["VXWalkthrough"]
        ),
    ],
	dependencies: [
		.package(url: "https://github.com/yannickl/QRCodeReader.swift", from: "10.0.1")
	],
	targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "VXWalkthrough",
			dependencies: [
				.product(name: "QRCodeReader", package: "QRCodeReader.swift")
			],
			resources: [
				// .copy("Resources/Media.assets"),
				// .copy("Media.xcassets"),
				.process("Resources"),
				// .process("Resources/VXWalkthroughViewControllerGo@2x.png"),
				// .process("Resources/VXWalkthroughViewControllerLeftArrow@2x.png"),
				// .process("Resources/VXWalkthroughViewControllerRightArrow@2x.png"),
				// .process("Resources/VXWalkthroughViewControllerScan@2x.png"),
			]),
	],
	swiftLanguageVersions: [.v5]
)
