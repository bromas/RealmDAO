// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RealmDAO",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "RealmDAO",
            targets: ["RealmDAO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift", from: "10.25.1"),
    ],
    targets: [
        .target(
            name: "RealmDAO",
            dependencies: [
                .productItem(name: "Realm", package: "realm-swift", condition: .none),
                .productItem(name: "RealmSwift", package: "realm-swift", condition: .none)
            ]),
        .testTarget(
            name: "RealmDAOTests",
            dependencies: ["RealmDAO"]),
    ]
)
