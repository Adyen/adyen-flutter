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
               .product(name: "AdyenDropIn", package: "adyen-ios"),
               .product(name: "AdyenSession", package: "adyen-ios")
            ],
            resources: []
        )
    ]
)
