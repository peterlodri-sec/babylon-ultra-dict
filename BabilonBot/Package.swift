// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BabilonBot",
    platforms: [.macOS(.v14), .iOS(.v18)],
    products: [
        .executable(name: "babilonbot", targets: ["BabilonBot"]),
        .library(name: "BabilonBotLib", targets: ["BabilonBotLib"]),
    ],
    targets: [
        .executableTarget(
            name: "BabilonBot",
            dependencies: ["BabilonBotLib"],
            path: "Sources/BabilonBot"
        ),
        .target(
            name: "BabilonBotLib",
            path: "Sources/BabilonBotLib"
        ),
    ]
)
