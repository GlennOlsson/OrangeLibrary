// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

let package = Package(
    name: "mail-collect",
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.14.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "mail-collect",
            dependencies: [
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "Vapor", package: "vapor")
            ],
            resources: [
                // Relative to Sources/mail-collect
                .process("Resources/secrets.txt")
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "mail-collect")]),
        .testTarget(
            name: "mail-collectTests",
            dependencies: ["mail-collect"]
        ),
    ]
)
