// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VisualMesh",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "VisualMesh", targets: ["VisualMesh"]),
        .library(name: "VisualMeshExamples", targets: ["VisualMeshExamples"]),
    ],
    targets: [
        .target(name: "VisualMesh"),
        .target(name: "VisualMeshExamples", dependencies: ["VisualMesh"]),
        .testTarget(name: "VisualMeshTests", dependencies: ["VisualMesh"]),
    ]
)
