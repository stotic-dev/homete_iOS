---
paths:
  - "**/*.swift"
---

# Swiftコード変更後の検証ルール

Swiftファイル（`*.swift`）を編集・作成・削除した後は、必ず `swift-code-verification` スキルに従って検証を実行すること。

検証フロー（ビルド → SwiftLint → ユニットテスト → 必要ならVRT）の詳細は当該スキルに集約されている:
- `.claude/skills/swift-code-verification/SKILL.md`

**ユニットテストは省略不可。必ず実行すること。**

許可ツール（プロジェクトの `.claude/settings.local.json` に登録済み）:
- `Bash(swift build:*)`, `Bash(swift test:*)`, `Bash(xcodebuild:*)`, `Bash(ProjectTools/.build/arm64-apple-macosx/debug/swiftlint lint:*)`
- **サンドボックスは有効**（`sandbox.enabled: true`）。SwiftPM系コマンドは `dangerouslyDisableSandbox: true` を付けて実行すること（理由はスキル参照）
