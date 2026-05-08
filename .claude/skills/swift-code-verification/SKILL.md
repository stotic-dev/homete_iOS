---
name: swift-code-verification
description: homete iOSプロジェクトのSwiftコード変更後の検証フロー。ビルド・SwiftLint・ユニットテスト（および必要ならVRT）を順番に実行する。Swiftファイルを編集・作成・削除した直後に必ず使う。
---

# Swiftコード変更後の検証スキル

## 対象タイミング

Swiftファイル（`*.swift`）を編集・作成・削除した後は、必ず以下の検証を順番に実行する。
**ユニットテスト（手順3）は省略不可。必ず実行すること。**

このスキルは Bash コマンドを以下の許可ルール下で実行する想定（プロジェクトの `.claude/settings.local.json` に登録済み）:
- `Bash(swift build:*)`, `Bash(swift test:*)`, `Bash(xcodebuild:*)`, `Bash(ProjectTools/.build/arm64-apple-macosx/debug/swiftlint lint:*)`

サンドボックスはプロジェクト設定で無効化済み（Swift PM の sandbox-exec ネスト問題回避のため）。`dangerouslyDisableSandbox` を明示する必要はない。

---

## 検証手順

### 1. ビルド確認

**LocalPackage配下のファイルを変更した場合（通常）:**

```bash
swift build --package-path LocalPackage --sdk $(xcrun --sdk iphonesimulator --show-sdk-path) --triple arm64-apple-ios26.2-simulator
```

**メインターゲット（`homete/`配下）を変更した場合のみ:**

```bash
xcodebuild build \
  -scheme homete \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -quiet \
  2>&1 | tail -20
```

### 2. SwiftLint実行

```bash
ProjectTools/.build/arm64-apple-macosx/debug/swiftlint lint
```

`ProjectTools/.build/arm64-apple-macosx/debug/swiftlint` が存在しない場合は先に `make setup-project` または `swift build --package-path ProjectTools --scratch-path ProjectTools/.build` を実行。

### 3. ユニットテスト実行（省略不可）

```bash
swift test --package-path LocalPackage --enable-code-coverage
```

特定のテストだけ流したいときは `--filter "TestSuite名"` を追加する。

### 4. UIデグレ確認（SwiftUIのViewを変更した場合のみ）

`.prefire.yml` の指定（`simulator_device: "iPhone17,3"`、`required_os: 26`）に従う。

```bash
xcodebuild test \
  -scheme homete \
  -testPlan snapshotTesting \
  -destination 'platform=iOS Simulator,id=$(xcrun simctl list devices | grep "iPhone 16" | grep "iOS 26" | head -1 | grep -oE "[0-9A-F-]{36}")' \
  -quiet \
  2>&1 | tail -30
```

---

## エラー発生時の対応

- 各ステップでエラーが出た場合は、出力から原因を特定し、自主的に修正する
- 修正後は **該当ステップから** 再実行する（前のステップは通っているのでスキップ可）
- 全ての検証が通るまで修正と再実行を繰り返す
- 自力で解決できないエラーのみユーザーに報告する

## 並列実行のヒント

ビルドとSwiftLintは独立に走らせて問題ない。Bashの並列ツール呼び出しで時間短縮できる。
ただし、テストはビルドを前提とするので並列化しない。
