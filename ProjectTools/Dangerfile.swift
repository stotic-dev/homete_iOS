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
    let repoSlug = danger.github.pullRequest.base.repo.fullName // 例: "owner/repo"
    let headCommitSha = danger.github.pullRequest.head.sha // 変更後
    let baseCommitSha = danger.github.pullRequest.base.sha // 変更前
    let vrtSnapshotDir = "hometeSnapshotTests/__Snapshots__/PreviewTests.generated"

    markdown("## snapshotの変更")
    for imagePath in danger.git.modifiedFiles.filter({ $0.contains(vrtSnapshotDir) && $0.lowercased().hasSuffix(".png")
    }) {
        // GitHubのraw URLを構築
        let beforeImageUrl = "https://raw.githubusercontent.com/\(repoSlug)/\(baseCommitSha)/\(imagePath)"
        let afterImageUrl = "https://raw.githubusercontent.com/\(repoSlug)/\(headCommitSha)/\(imagePath)"
        
        markdown("""
        ### 更新ファイル: `\(imagePath.relativeImagePath(basePath: vrtSnapshotDir))`
        | before | after |
        | ------ | ----- |
        | ![image](\(beforeImageUrl)) | ![image](\(afterImageUrl)) |
        """)
    }
    
    markdown("## snapshotの追加")
    for imagePath in danger.git.createdFiles.filter({ $0.contains(vrtSnapshotDir) && $0.lowercased().hasSuffix(".png")
    }) {
        // GitHubのraw URLを構築
        let addedImageUrl = "https://raw.githubusercontent.com/\(repoSlug)/\(headCommitSha)/\(imagePath)"
        
        markdown("""
        ### 追加ファイル: `\(imagePath.relativeImagePath(basePath: vrtSnapshotDir))`
        | current |
        | ------ |
        | ![image](\(addedImageUrl)) |
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

extension String {
    func relativeImagePath(basePath: String) -> String {
        if let range = self.range(of: basePath) {
            var suffix = String(self[range.upperBound...])
            if suffix.hasPrefix("/") { suffix.removeFirst() }
            return suffix
        } else {
            return self
        }
    }
}
