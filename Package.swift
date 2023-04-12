// swift-tools-version: 5.7
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
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMinor(from: "0.6.6")),
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
        .testTarget(
            name: "ReplicateTests",
            dependencies: [
                "Replicate",
                .product(name: "AnyCodable", package: "AnyCodable"),
            ]),
    ]
)
