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
            targets: ["BatchXCFramework"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .binaryTarget(
            name: "BatchXCFramework",
            url: "https://download.batch.com/sdk/ios/spm/BatchSDK-ios_spm-xcframework-1.16.0.zip",
            checksum: "e027790d624a1341dfe08fa83dfea5c5048dfc660938dccb750f59f7b5e3a4f9"
        )
    ]
)