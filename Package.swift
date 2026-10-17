// swift-tools-version: 6.2
import PackageDescription
let package = Package(name: "HomeViewCore", platforms: [.macOS(.v14)], products: [.library(name: "HomeViewCore", targets: ["HomeViewCore"])], targets: [.target(name: "HomeViewCore", path: "Sources/Core"), .testTarget(name: "HomeViewCoreTests", dependencies: ["HomeViewCore"], path: "Tests/CoreTests")])
