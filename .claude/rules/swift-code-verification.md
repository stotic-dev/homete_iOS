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
- **サンドボックスは有効**（`sandbox.enabled: true`）。SwiftPM系コマンドには **`--disable-sandbox` フラグ**を付けて、Claudeのサンドボックス**内**で実行すること。`dangerouslyDisableSandbox: true` は使わない（allowルールを迂回して必ず許可プロンプトが出るため、自律実行が止まる）。理由と許可済みキャッシュパスはスキル参照
- `make build-local-package` / `make test-packages` / `make format` には `--disable-sandbox` が既に入っている
