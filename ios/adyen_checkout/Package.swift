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
        // adyen-ios develop pinned to the latest commit on 2026-11-09 (committed 2026-11-06).
        // Advance the revision to move the pin forward.
        .package(url: "https://github.com/Adyen/adyen-ios", revision: "e3092053f15139146b248d1a90ecef0cf0adbf70")
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
                .product(name: "AdyenDropIn", package: "adyen-ios"),
                .product(name: "AdyenEncryption", package: "adyen-ios"),
                .product(name: "AdyenSession", package: "adyen-ios")
            ],
            resources: []
        )
    ]
)
