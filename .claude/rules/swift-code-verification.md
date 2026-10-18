---
paths:
  - "**/*.swift"
---

# Swiftコード変更後の検証ルール

Swiftファイル（`*.swift`）を編集・作成・削除した後は、必ず `swift-code-verification` スキルに従って検証を実行すること。

検証フロー（影響範囲の判定 → ビルド → SwiftLint → ユニットテスト → 必要ならローカルVRT）の詳細は当該スキルに集約されている:
- `.claude/skills/swift-code-verification/SKILL.md`

**最初に `make affected` で影響範囲を割り出し、その範囲だけを検証する。** 全体ビルド（`make build-local-package`）や全テスト（`make test-packages-fast`）は流さず、`make build-affected` / `make test-affected` を使う。
変更に関係するテストターゲットがある限り、ユニットテストは省略不可。全部「なし」ならSwiftのビルドに影響しない変更なので、変更したもの自体の動作だけを最小限で確かめる。

**同じ検証コマンドを2回流さない。** 検証は1回が高コストなので、出力は `tee` でログに残してからフィルタし、絞り方が足りなければ再実行ではなく保存済みログを読み直す。
`tail` はテスト結果の判定には使わない（最後のターゲットしか映らず他が見えない）。フィルタの具体例はスキル参照。

**VRT（スナップショットテスト）は、直接変えたHometeUI・FeatureのViewの見た目に関わる変更のときだけ `make snapshot-affected` でローカル実行する。** 必ずiOS 27.0のiPhone 16で流す（CIと同じマイナーバージョンでないと描画に差分が出る。他のシミュレータで代用しない）。参照スナップショットの更新はCIに任せる。詳細はスキル参照。

許可ツール（プロジェクトの `.claude/settings.local.json` に登録済み）:
- `Bash(swift build:*)`, `Bash(swift test:*)`, `Bash(xcodebuild:*)`, `Bash(ProjectTools/.build/arm64-apple-macosx/debug/swiftlint lint:*)`
- **サンドボックスは有効**（`sandbox.enabled: true`）。SwiftPM系コマンドには **`--disable-sandbox` フラグ**を付けて、Claudeのサンドボックス**内**で実行すること。`dangerouslyDisableSandbox: true` は原則使わない（allowルールを迂回して必ず許可プロンプトが出るため、自律実行が止まる）。理由と許可済みキャッシュパス、および Build Tool Plugin が `.build` に書けない既知症状の切り分け・例外条件はスキル参照
- `make build-affected` / `make test-affected` / `make format` などSwiftPMを呼ぶmakeターゲットには `--disable-sandbox` が既に入っている（`make snapshot-affected` はxcodebuildを使うのでサンドボックス外で流す）

## 自動検証（Stopフック）

ターン終了時に `scripts/claude-verify-swift.sh` が走り、Swiftに変更があれば `make check-previews` を実行する。失敗すると exit 2 で作業が差し戻される。3回連続失敗で自動検証は止まる。

**フックが見るのは `#Preview` の静的検査だけで、ビルド・SwiftLint・ユニットテストは実行されない。** これらはローカルで落ちるので Claude 自身が上記の手順で実行すればよく、フックで重ねると SwiftPM の `.build` ロックが手動実行とぶつかるうえ、ターン終了が数分単位で伸びるため。逆に `#Preview` の誤りはローカルのビルドでは絶対に落ちず Xcode Cloud の VRT まで気付けないので、フック側に残している。

設計は [ADR-0006](../../doc/adr/0006-claude-code-autonomous-execution.md) と [ADR-0010](../../doc/adr/0010-stop-hook-scope-preview-check-only.md)。
