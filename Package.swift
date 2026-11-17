// swift-tools-version:6.1
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
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-3.5.0.zip",
            checksum: "c2a04c678dfa8284a04d406213266f8bab0b01d45a455f707fe29f7ca922c6ef"
        )
    ]
)