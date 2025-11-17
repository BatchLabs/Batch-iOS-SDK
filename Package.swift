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
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-3.2.0.zip",
            checksum: "e34cd08076dd191de59f2a5b27e78df14d7b6b0ee3f0ebe461a2288b2572b70a"
        )
    ]
)