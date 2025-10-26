//
//  Package.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/anthropics/claude-code-sdk-swift", from: "1.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0")
    ],
    targets: [
        .target(
            name: "YourProject",
            dependencies: ["ClaudeCodeSDK", "Alamofire"]
        )
    ]
)
