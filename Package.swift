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
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-1.17.2.zip",
            checksum: "e2c08e708008c03cfa3f3aed98aeeda08c46a662b25329ad627c1fc4763a9bc8"
        )
    ]
)