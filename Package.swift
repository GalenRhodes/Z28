// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//@f:0
let package = Package(
    name: "Z28",
    platforms: [
        .macOS(.v11_0),
    ],
    products: [
        .executable(name: "z28", targets: [ "Z28" ]),
    ],
    dependencies: [
        .package(name: "Rubicon", url: "https://github.com/GalenRhodes/Rubicon", .upToNextMinor(from: "0.2.46")),
        .package(name: "SourceKitten", url: "https://github.com/jpsim/SourceKitten", .upToNextMinor(from: "0.31.0")),
    ],
    targets: [
        .executableTarget(name: "Z28", dependencies: [ "Rubicon", "SourceKitten", ])
    ]
)
//@f:1
