// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HomeOSSkills",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "HomeOSCore", targets: ["HomeOSCore"]),
        .library(name: "HomeOSSkills", targets: ["HomeOSSkills"]),
    ],
    targets: [
        // Core types, protocols, storage, LLM bridge
        .target(
            name: "HomeOSCore",
            path: "Sources/HomeOSCore"
        ),
        // All skill implementations
        .target(
            name: "HomeOSSkills",
            dependencies: ["HomeOSCore"],
            path: "Sources/Skills"
        ),
        // Tests
        .testTarget(
            name: "HomeOSCoreTests",
            dependencies: ["HomeOSCore"],
            path: "Tests/HomeOSCoreTests"
        ),
        .testTarget(
            name: "HomeOSSkillTests",
            dependencies: ["HomeOSSkills", "HomeOSCore"],
            path: "Tests/HomeOSSkillTests"
        ),
    ]
)
