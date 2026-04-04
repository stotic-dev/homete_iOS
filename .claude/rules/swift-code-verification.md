---
applyTo: "**/*.swift"
---

# Swiftコード変更後の検証ルール

## 対象タイミング

Swiftファイルを編集・作成・削除した後は、必ず以下の検証を順番に実行する。
**ユニットテスト（手順3）は省略不可。必ず実行すること。**

## 検証手順

### 1. ビルド確認

**通常（LocalPackage配下のファイルを変更した場合）:**

```bash
swift build --package-path LocalPackage --sdk $(xcrun --sdk iphonesimulator --show-sdk-path) --triple arm64-apple-ios26.2-simulator
```

**メインターゲットを変更した場合のみ（`homete/`配下のファイルを変更した場合）:**

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

### 3. ユニットテスト実行（省略不可）

```bash
swift test --package-path LocalPackage --enable-code-coverage
```

### 4. UIデグレ確認（Viewを変更した場合のみ）

SwiftUIのViewファイルを変更した場合は、スナップショットテストでVRTを実行する。
シミュレーターは `.prefire.yml` の指定（`simulator_device: "iPhone17,3"`、`required_os: 26`）に従う。

```bash
xcodebuild test \
  -scheme homete \
  -testPlan snapshotTesting \
  -destination 'platform=iOS Simulator,id=$(xcrun simctl list devices | grep "iPhone 16" | grep "iOS 26" | head -1 | grep -oE "[0-9A-F-]{36}")' \
  -quiet \
  2>&1 | tail -30
```

## エラー発生時の対応

- 各ステップでエラーが発生した場合は、コマンドの出力から原因を特定し、自主的に修正する
- 修正後は該当ステップから再度検証を実行する
- 全ての検証が通るまで修正と再実行を繰り返す
- 自力で解決できないエラーのみユーザーに報告する
