// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "FilePath",
    products: [
        .library(name: "FilePathFramework", targets: ["FilePathFramework"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "FilePathFramework", dependencies: []),
        .testTarget(name: "FilePathFrameworkTests", dependencies: ["FilePathFramework"]),
    ]
)
