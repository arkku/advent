// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "advent",
    targets: [
        .executableTarget(
            name: "day11-swift",
            path: ".",
            sources: ["day11.swift"]
        ),
    ]
)
