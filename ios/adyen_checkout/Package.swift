// swift-tools-version: 5.9

import Foundation
import PackageDescription

let hasFlutterFramework = FileManager.default.fileExists(
    atPath: URL(fileURLWithPath: Context.packageDirectory).appendingPathComponent("../FlutterFramework").path
)
let flutterFrameworkDependencies: [Package.Dependency] = hasFlutterFramework
    ? [.package(name: "FlutterFramework", path: "../FlutterFramework")]
    : []
let flutterFrameworkTargetDependencies: [Target.Dependency] = hasFlutterFramework
    ? [.product(name: "FlutterFramework", package: "FlutterFramework")]
    : []

let package = Package(
    name: "adyen_checkout",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(name: "adyen-checkout", targets: ["adyen_checkout"])
    ],
    dependencies: [
        // adyen-ios develop pinned to the latest commit on 2026-11-09 (committed 2026-11-06).
        // Advance the revision to move the pin forward.
        .package(url: "https://github.com/Adyen/adyen-ios", revision: "e3092053f15139146b248d1a90ecef0cf0adbf70")
    ] + flutterFrameworkDependencies,
    targets: [
        .target(
            name: "adyen_checkout",
            dependencies: flutterFrameworkTargetDependencies + [
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
