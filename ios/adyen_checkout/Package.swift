// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "adyen_checkout",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(name: "adyen-checkout", targets: ["adyen_checkout"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/Adyen/adyen-ios", exact: "6.0.0-alpha.1")
    ],
    targets: [
        .target(
            name: "adyen_checkout",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "Adyen", package: "adyen-ios"),
                .product(name: "AdyenActions", package: "adyen-ios"),
                .product(name: "AdyenCard", package: "adyen-ios"),
                .product(name: "AdyenCheckout", package: "adyen-ios"),
                .product(name: "AdyenComponents", package: "adyen-ios"),
                .product(name: "AdyenEncryption", package: "adyen-ios"),
                .product(name: "AdyenSession", package: "adyen-ios")
            ],
            resources: []
        )
    ]
)
