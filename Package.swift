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
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-3.0.2.zip",
            checksum: "bf0601aef2b15a3771d3e8d1f2cdeeba311a255f0283f6b61530dfa1c8be9bdb"
        )
    ]
)