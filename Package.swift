// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TravelWorldMap",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TravelWorldMap",
            targets: ["TravelWorldMap"]
        ),
    ],

    targets: [
        .target(
            name: "TravelWorldMap",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
