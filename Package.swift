// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Batch",
    platforms: [
        .iOS(.v10)
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
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-1.21.1.zip",
            checksum: "0b4a80df826d46be24d71eb77e41517a6545663f15b1e44d4ef46038df175232"
        )
    ]
)