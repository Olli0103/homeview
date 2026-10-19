// swift-tools-version: 6.2
import PackageDescription
let package = Package(name: "HomeViewCore", platforms: [.macOS(.v14)], products: [.library(name: "HomeViewCore", targets: ["HomeViewCore"])], dependencies: [.package(url: "https://github.com/nmdias/FeedKit.git", exact: "10.9.4")], targets: [.target(name: "HomeViewCore", dependencies: [.product(name: "FeedKit", package: "FeedKit")], path: "Sources/Core"), .testTarget(name: "HomeViewCoreTests", dependencies: ["HomeViewCore"], path: "Tests/CoreTests")])
