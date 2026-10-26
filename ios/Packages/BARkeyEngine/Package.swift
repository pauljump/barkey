// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BARkeyEngine",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "BARkeyEngine", targets: ["BARkeyEngine"]),
        .executable(name: "barkey-eval", targets: ["barkey-eval"]),
    ],
    targets: [
        .target(
            name: "BARkeyEngine",
            resources: [.copy("Resources/en.lexicon"), .copy("Resources/en.phrases"), .copy("Resources/LEXICON-LICENSE")]
        ),
        .executableTarget(name: "barkey-eval", dependencies: ["BARkeyEngine"]),
        .testTarget(name: "BARkeyEngineTests", dependencies: ["BARkeyEngine"]),
    ]
)
