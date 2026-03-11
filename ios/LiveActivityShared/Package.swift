// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiveActivityShared",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "LiveActivityShared", targets: ["LiveActivityShared"])
    ],
    targets: [
        .target(
            name: "LiveActivityShared",
            path: "Sources/LiveActivityShared"
        )
    ]
)
