// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "selection-translator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SelectionTranslator", targets: ["SelectionTranslator"])
    ],
    targets: [
        .executableTarget(
            name: "SelectionTranslator"
        ),
    ],
    swiftLanguageModes: [.v6]
)
