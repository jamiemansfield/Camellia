// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Camellia",
    products: [
        .library(
            name: "Camellia",
            targets: ["Camellia"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/ordo-one/benchmark",
            .upToNextMajor(from: "1.4.0")
        )
    ],
    targets: [
        .target(
            name: "Camellia",
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes")
            ]
        ),
        .testTarget(
            name: "CamelliaTests",
            dependencies: ["Camellia"]
        ),
        .executableTarget(
            name: "CamelliaBenchmarks",
            dependencies: [
                "Camellia",
                .product(name: "Benchmark", package: "benchmark"),
            ],
            path: "Benchmarks/CamelliaBenchmarks",
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes")
            ],
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "benchmark")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
