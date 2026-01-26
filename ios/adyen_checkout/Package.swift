// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "adyen_checkout",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "adyen-checkout", targets: ["adyen_checkout"])
    ],
    dependencies: [
        .package(url: "https://github.com/Adyen/adyen-ios", revision: "5cf8045bae0489084d5c0b6a1f4387f520c68ee0")
    ],
    targets: [
        .target(
            name: "adyen_checkout",
            dependencies: [
                .product(name: "AdyenCheckout", package: "adyen-ios"),
                .product(name: "AdyenDropIn", package: "adyen-ios"),
                .product(name: "AdyenSession", package: "adyen-ios"),
                .product(name: "AdyenCard", package: "adyen-ios"),
                .product(name: "AdyenComponents", package: "adyen-ios"),
                .product(name: "AdyenActions", package: "adyen-ios")
            ],
            resources: []
        )
    ]
)
