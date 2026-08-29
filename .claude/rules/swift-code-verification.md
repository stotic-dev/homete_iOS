---
paths:
  - "**/*.swift"
---

# Swiftコード変更後の検証ルール

Swiftファイル（`*.swift`）を編集・作成・削除した後は、必ず `swift-code-verification` スキルに従って検証を実行すること。

検証フロー（ビルド → SwiftLint → ユニットテスト）の詳細は当該スキルに集約されている:
- `.claude/skills/swift-code-verification/SKILL.md`

**ユニットテストは省略不可。必ず実行すること。**

**同じ検証コマンドを2回流さない。** 検証は1回が高コスト（ビルド約80秒、`make test-packages` は5テストターゲット）
なので、出力は `tee` でログに残してからフィルタし、絞り方が足りなければ再実行ではなく保存済みログを読み直す。
`tail` はテスト結果の判定には使わない（最後のターゲットしか映らず他が見えない）。フィルタの具体例はスキル参照。

**VRT（スナップショットテスト）はローカルで実行しない。** Xcode Cloud の `VRT` ワークフローで回す運用のため、SwiftUIのViewを変更した場合も参照スナップショットの更新はCIに任せる。理由と、誤って生成してしまったPNGの扱いはスキル参照。

許可ツール（プロジェクトの `.claude/settings.local.json` に登録済み）:
- `Bash(swift build:*)`, `Bash(swift test:*)`, `Bash(xcodebuild:*)`, `Bash(ProjectTools/.build/arm64-apple-macosx/debug/swiftlint lint:*)`
- **サンドボックスは有効**（`sandbox.enabled: true`）。SwiftPM系コマンドには **`--disable-sandbox` フラグ**を付けて、Claudeのサンドボックス**内**で実行すること。`dangerouslyDisableSandbox: true` は原則使わない（allowルールを迂回して必ず許可プロンプトが出るため、自律実行が止まる）。理由と許可済みキャッシュパス、および Build Tool Plugin が `.build` に書けない既知症状の切り分け・例外条件はスキル参照
- `make build-local-package` / `make test-packages` / `make format` には `--disable-sandbox` が既に入っている

## 自動検証（Stopフック）

ターン終了時に `scripts/claude-verify-swift.sh` が走り、Swiftに変更があれば `make check-previews` を実行する。失敗すると exit 2 で作業が差し戻される。3回連続失敗で自動検証は止まる。

**フックが見るのは `#Preview` の静的検査だけで、ビルド・SwiftLint・ユニットテストは実行されない。** これらはローカルで落ちるので Claude 自身が上記の手順で実行すればよく、フックで重ねると SwiftPM の `.build` ロックが手動実行とぶつかるうえ、ターン終了が数分単位で伸びるため。逆に `#Preview` の誤りはローカルのビルドでは絶対に落ちず Xcode Cloud の VRT まで気付けないので、フック側に残している。

設計は [ADR-0006](../../doc/adr/0006-claude-code-autonomous-execution.md) と [ADR-0010](../../doc/adr/0010-stop-hook-scope-preview-check-only.md)。
