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
  targets: [
    .target(
      name: "Butter")
  ]
)
