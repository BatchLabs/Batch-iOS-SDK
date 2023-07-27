// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tools",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/nicklockwood/SwiftFormat", exact: "0.51.7"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Tools",
            dependencies: []),
    ]
)
