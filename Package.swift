// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "Butter",
  platforms: [
    .iOS(.v14),
  ],
  products: [
    .library(
      name: "Butter",
      targets: ["Butter"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/SnapKit/SnapKit",
      from: "5.0.1")
  ],
  targets: [
    .target(
      name: "Butter",
      dependencies: ["SnapKit"])
  ]
)
