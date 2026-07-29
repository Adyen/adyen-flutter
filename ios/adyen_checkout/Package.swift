// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        // Alpha release integration is active. DropIn has no public API on iOS in 6.0.0-alpha.1
        // (DropInComponent is `package`-access; Checkout.createDropIn() is disabled in the SDK
        // itself), so DropIn-related plugin code is commented out below until that gap closes.
        .package(url: "https://github.com/Adyen/adyen-ios", exact: "6.0.0-alpha.1")
        // .package(url: "https://github.com/Adyen/adyen-ios", revision: "e91a148b0fbf0edbf825937998707627a10dc63e")
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
