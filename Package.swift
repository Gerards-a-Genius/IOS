// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "N8NCommandCenter",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "N8NCommandCenter",
            targets: ["N8NCommandCenter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.0"),
    ],
    targets: [
        .target(
            name: "N8NCommandCenter",
            dependencies: [
                "Alamofire",
                .product(name: "Markdown", package: "swift-markdown"),
                "CryptoSwift",
                "Kingfisher"
            ],
            path: "N8NCommandCenter"
        ),
        .testTarget(
            name: "N8NCommandCenterTests",
            dependencies: ["N8NCommandCenter"]),
    ]
)