// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "MockGenerator",
	platforms: [.iOS(.v13), .macOS(.v11)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "MockGenerator",
			targets: ["MockGenerator"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-syntax.git", from: "509.1.1"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "MockGenerator",
			dependencies: 
				[
					.product(name: "SwiftSyntax", package: "swift-syntax"),
					.product(name: "SwiftParser", package: "swift-syntax")
				]
		),
		.testTarget(
			name: "MockGeneratorTests",
			dependencies: ["MockGenerator"]),
	]
)
