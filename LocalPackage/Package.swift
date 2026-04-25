// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalPackage",
    platforms: [.iOS(.v17), .macOS(.v15)],
    products: [
        .library(
            name: "HometeDomain",
            targets: ["HometeDomain"]
        ),
        .library(
            name: "HometeUI",
            targets: ["HometeUI"]
        ),
        .library(
            name: "HometeResources",
            targets: ["HometeResources"]
        ),
        .library(
            name: "AuthFeature",
            targets: ["AuthFeature"]
        ),
        .library(
            name: "SettingFeature",
            targets: ["SettingFeature"]
        ),
        .library(
            name: "HomeFeature",
            targets: ["HomeFeature"]
        ),
        .library(
            name: "HouseworkFeature",
            targets: ["HouseworkFeature"]
        ),
        .library(
            name: "HometeInfrastructure",
            targets: ["HometeInfrastructure"]
        ),
        .library(
            name: "AppRoot",
            targets: ["AppRoot"]
        ),
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.2"),
        .package(url: "https://github.com/BarredEwe/Prefire.git", exact: "5.4.1"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0"),
    ],
    targets: [
        
        // MARK: Targets
        
        .target(
            name: "HometeDomain",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "HometeUI",
            dependencies: [
                "HometeDomain",
                "HometeResources",
                .product(name: "Prefire", package: "Prefire", condition: .when(platforms: [.iOS])),
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "HometeResources",
            resources: [
                .process("Resources/Colors.xcassets"),
                .process("Resources/Image.xcassets"),
            ],
            plugins: [
                .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin")
            ]
        ),
        .target(
            name: "AuthFeature",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "HometeResources",
            ],
            path: "./Sources/Features/AuthFeature",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "SettingFeature",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "HometeResources",
            ],
            path: "./Sources/Features/SettingFeature",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "HomeFeature",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "HometeResources",
            ],
            path: "./Sources/Features/HomeFeature",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "HouseworkFeature",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "HometeResources",
            ],
            path: "./Sources/Features/HouseworkFeature",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "ContributionFeature",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "HometeResources",
            ],
            path: "./Sources/Features/ContributionFeature",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "HometeInfrastructure",
            dependencies: [
                "HometeDomain",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "AppRoot",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "AuthFeature",
                "SettingFeature",
                "HomeFeature",
                "HouseworkFeature",
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        
        // MARK: Test Targets
        
        .testTarget(
            name: "HometeDomainTests",
            dependencies: [
                "HometeDomain",
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .testTarget(
            name: "HouseworkFeatureTests",
            dependencies: [
                "HouseworkFeature",
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
    ]
)
