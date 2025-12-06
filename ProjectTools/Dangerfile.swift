import Danger
import DangerSwiftCoverage

let danger = Danger()

// PR自体のレビュー

if let github = danger.github {
    
    let changeLineCount = (github.pullRequest.additions ?? .zero) + (github.pullRequest.deletions ?? .zero)
    if changeLineCount >= 500 {
        
        warn("PRの変更行が多すぎます。500行以内にしてね！理想は400行！")
    }
}

// SwiftLintのレビュー

let swiftLintPath = SwiftLint.SwiftlintPath.bin(
    "ProjectTools/.build/artifacts/swiftlint/SwiftLintBinary/SwiftLintBinary.artifactbundle/swiftlint-0.59.1-macos/bin/swiftlint"
)
let lintTargets: [SwiftLintTarget] = [
    .init(targetPath: "homete"),
]

for targetInfo in lintTargets {
    
    SwiftLint.lint(
        .modifiedAndCreatedFiles(directory: targetInfo.targetPath),
        inline: true,
        configFile: targetInfo.configPath,
        swiftlintPath: swiftLintPath
    )
}

// Code Coverageの確認

let resultBundlePath = "Build/test.xcresult"
Coverage.xcodeBuildCoverage(
    .xcresultBundle(resultBundlePath),
    minimumCoverage: .zero
)

// MARK: - Definition

struct SwiftLintTarget {
    
    let targetPath: String
    let configPath: String
    
    init(targetPath: String,
         configPath: String = ".swiftlint.yml") {
        self.targetPath = targetPath
        self.configPath = configPath
    }
}
