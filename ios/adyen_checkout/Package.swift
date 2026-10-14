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
        // adyen-ios develop pinned to the last commit of Friday 2026-10-09.
        // Advance the revision to move the pin forward.
        .package(url: "https://github.com/Adyen/adyen-ios", revision: "80b19608532715b0cb157cbbab0e3396e38199ad")
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
