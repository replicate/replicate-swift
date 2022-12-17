// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Replicate",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Replicate",
            targets: ["Replicate"]),
        .executable(
            name: "generate-replicate-model",
            targets: ["generate-replicate-model"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMinor(from: "0.6.6")),
        .package(url: "https://github.com/mattt/OpenAPIKit", revision: "86e2a2a762efae13b482ad64b2abe416a7c85cd8"),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.1.4")),
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "0.50700.00"),
        .package(url: "https://github.com/apple/swift-format.git", exact: "0.50700.00"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Replicate",
            dependencies: [
                .product(name: "AnyCodable", package: "AnyCodable"),
            ]
        ),
        .executableTarget(
            name: "generate-replicate-model",
            dependencies: [
                "Replicate",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftFormat", package: "swift-format"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit")
            ]),
        .testTarget(
            name: "ReplicateTests",
            dependencies: [
                "Replicate",
                .product(name: "AnyCodable", package: "AnyCodable"),
            ]),
    ]
)
