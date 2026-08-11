---
paths:
  - "**/*.swift"
---

# Swiftコード変更後の検証ルール

Swiftファイル（`*.swift`）を編集・作成・削除した後は、必ず `swift-code-verification` スキルに従って検証を実行すること。

検証フロー（ビルド → SwiftLint → ユニットテスト）の詳細は当該スキルに集約されている:
- `.claude/skills/swift-code-verification/SKILL.md`

**ユニットテストは省略不可。必ず実行すること。**

**VRT（スナップショットテスト）はローカルで実行しない。** Xcode Cloud の `VRT` ワークフローで回す運用のため、SwiftUIのViewを変更した場合も参照スナップショットの更新はCIに任せる。理由と、誤って生成してしまったPNGの扱いはスキル参照。

許可ツール（プロジェクトの `.claude/settings.local.json` に登録済み）:
- `Bash(swift build:*)`, `Bash(swift test:*)`, `Bash(xcodebuild:*)`, `Bash(ProjectTools/.build/arm64-apple-macosx/debug/swiftlint lint:*)`
- **サンドボックスは有効**（`sandbox.enabled: true`）。SwiftPM系コマンドには **`--disable-sandbox` フラグ**を付けて、Claudeのサンドボックス**内**で実行すること。`dangerouslyDisableSandbox: true` は原則使わない（allowルールを迂回して必ず許可プロンプトが出るため、自律実行が止まる）。理由と許可済みキャッシュパス、および Build Tool Plugin が `.build` に書けない既知症状の切り分け・例外条件はスキル参照
- `make build-local-package` / `make test-packages` / `make format` には `--disable-sandbox` が既に入っている

## 自動検証（Stopフック）

ターン終了時に `scripts/claude-verify-swift.sh` が走り、Swiftに変更があれば `make test-packages` を実行する。失敗すると exit 2 で作業が差し戻されるので、**手順を飛ばしても最終的には検証される**。ただし差し戻しは遅く、3回連続失敗で自動検証は止まるため、フックに頼らず上記の手順を自分で実行すること。設計は [ADR-0006](../../doc/adr/0006-claude-code-autonomous-execution.md)。
