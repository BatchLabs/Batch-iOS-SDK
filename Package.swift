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
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-1.19.3.zip",
            checksum: "5a56179647f66d34c0a4532f28f68241bc1e12e7c391d9593407e47998eabc67"
        )
    ]
)