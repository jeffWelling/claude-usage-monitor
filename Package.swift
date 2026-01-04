// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ClaudeUsageMonitor",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "ClaudeUsageMonitor",
            path: "ClaudeUsageMonitor"
        )
    ]
)
