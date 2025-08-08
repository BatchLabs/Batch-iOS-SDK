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
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-3.0.3.zip",
            checksum: "65ce974990ec245eb45f6e104affd8291b73bfcb530950f9d2f6d70d9d46d5e5"
        )
    ]
)