import Danger
import DangerSwiftCoverage

let danger = Danger()

// PR自体のレビュー

if let github = danger.github {
    
    let changeLineCount = (github.pullRequest.additions ?? .zero) + (github.pullRequest.deletions ?? .zero)
    if changeLineCount >= 500 {
        
        warn("PRの変更行が多すぎます。500行以内にしてね！理想は400行！")
    }
    
    // VRTのsnapshotから画像の差分を表示する
    let vrtSnapshotDir = "hometeSnapshotTests/__Snapshots__/PreviewTests.generated"
    let changedSnapshotFiles = danger.git.modifiedFiles.filter{ $0.contains(vrtSnapshotDir) && $0.lowercased().hasSuffix(".png")
    }

    for imagePath in changedSnapshotFiles {
        let repoSlug = danger.github.pullRequest.base.repo.fullName // 例: "owner/repo"
        let headCommitSha = danger.github.pullRequest.head.sha // 変更後
        let baseCommitSha = danger.github.pullRequest.base.sha // 変更前
        
        // GitHubのraw URLを構築
        let beforeImageUrl = "https://raw.githubusercontent.com/\(repoSlug)/\(baseCommitSha)/\(imagePath)"
        let afterImageUrl = "https://raw.githubusercontent.com/\(repoSlug)/\(headCommitSha)/\(imagePath)"
        
        markdown("""
        ### snapshotの変更: `\(imagePath)`
        | before | after |
        | ------ | ----- |
        | ![image](\(beforeImageUrl)) | ![image](\(afterImageUrl)) |
        """)
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

let resultBundlePath = "Build/test.xcresult"

// Code Coverageの確認

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
