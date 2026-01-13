// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SkillsKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SkillsKit", targets: ["SkillsKit"])
    ],
    targets: [
        .target(
            name: "SkillsKit",
            dependencies: [],
            resources: [
                .copy("BundledSkills")
            ]
        ),
        .testTarget(
            name: "SkillsKitTests",
            dependencies: ["SkillsKit"]
        )
    ]
)
