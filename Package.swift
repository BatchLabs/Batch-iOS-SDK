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
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-1.20.0.zip",
            checksum: "90c5ed03fab1c1708f54eb6eaa8180962e14659cc76fe0bd7f561273818eec94"
        )
    ]
)