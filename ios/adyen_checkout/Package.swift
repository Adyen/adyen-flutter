// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        .iOS("13.0")
    ],
    products: [
        .library(name: "adyen-checkout", targets: ["adyen_checkout"])
    ],
    dependencies: [
        .package(url: "https://github.com/Adyen/adyen-ios", exact: "5.26.0")
    ] + flutterFrameworkDependencies,
    targets: [
        .target(
            name: "adyen_checkout",
            dependencies: flutterFrameworkTargetDependencies + [
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
