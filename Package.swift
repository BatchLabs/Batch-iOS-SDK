// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Batch",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Batch",
            targets: ["Batch"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .binaryTarget(
            name: "Batch",
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-3.0.1.zip",
            checksum: "944de4c24f776923c69b848a67452fb81000ddd53415330cf94a708a6e1ebd3e"
        )
    ]
)