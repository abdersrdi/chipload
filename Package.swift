// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Chipload",
    products: [
        .library(name: "ChiploadCore", targets: ["ChiploadCore"])
    ],
    targets: [
        .target(name: "ChiploadCore"),
        .testTarget(name: "ChiploadCoreTests", dependencies: ["ChiploadCore"])
    ]
)
