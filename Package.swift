// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//@f:0
let package = Package(
    name: "Z28",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .executable(name: "z28", targets: [ "Z28" ]),
    ],
    dependencies: [
        .package(name: "Rubicon", url: "https://github.com/GalenRhodes/Rubicon", .upToNextMinor(from: "0.2.51")),
        .package(name: "SourceKittenFramework", url: "https://github.com/GalenRhodes/SourceKittenFramework", .upToNextMinor(from: "0.31.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.4.3")),
    ],
    targets: [
        .executableTarget(name: "Z28", dependencies: [
            "Rubicon",
            "SourceKittenFramework",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ])
    ]
)
//@f:1
