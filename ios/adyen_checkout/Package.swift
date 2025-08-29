// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "adyen_checkout",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "adyen-checkout", targets: ["adyen_checkout"])
    ],
    dependencies: [
        .package(url: "https://github.com/Adyen/adyen-ios", exact: "5.20.0")
    ],
    targets: [
        .target(
            name: "adyen_checkout",
            dependencies: [
                .product(name: "AdyenActions", package: "adyen-ios"),
                .product(name: "AdyenCard", package: "adyen-ios"),
                .product(name: "AdyenComponents", package: "adyen-ios"),
                .product(name: "AdyenDropIn", package: "adyen-ios"),
                .product(name: "AdyenEncryption", package: "adyen-ios"),
                .product(name: "AdyenSession", package: "adyen-ios")
            ],
            resources: [
                // TODO: If your plugin requires a privacy manifest
                // (e.g. if it uses any required reason APIs), update the PrivacyInfo.xcprivacy file
                // to describe your plugin's privacy impact, and then uncomment this line.
                // For more information, see:
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // TODO: If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)
