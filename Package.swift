// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MsgStream",
    products: [
        .library(
            name: "MsgStream",
            targets: ["MsgStream"]),
    ],
    targets: [
        .target(
            name: "MsgStream",
            dependencies: ["CMsgStream"]
            ),
        .target(
            name: "CMsgStream",
            sources: ["./src"]
        ),
        .testTarget(
            name: "MsgStreamTests",
            dependencies: ["MsgStream"]),
    ]
)
