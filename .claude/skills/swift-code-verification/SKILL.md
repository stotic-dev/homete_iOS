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

### サンドボックスの扱い（重要）

プロジェクトの `.claude/settings.local.json` では**サンドボックスが有効**（`sandbox.enabled: true`、`autoAllowBashIfSandboxed: true`）。

SwiftPM は Package.swift のマニフェスト評価を自前の `sandbox-exec` で行うため、Claude のサンドボックス内で実行するとネストになり失敗する:

```
sandbox-exec: sandbox_apply: Operation not permitted
error: invalid manifests at [...]
```

**解決策は SwiftPM 側のサンドボックスを切ること（`--disable-sandbox`）であって、Claude 側のサンドボックスを切ること（`dangerouslyDisableSandbox: true`）ではない。**

理由が重要で、`dangerouslyDisableSandbox: true` は allow ルールの有無に関係なく**必ず許可ゲートを通る**。`Bash(swift *)` が許可済みでも、この引数を付けた瞬間に毎回ユーザーへの確認（auto mode なら分類器）が走る。つまりこれを使い続ける限り、許可ルールをいくら足しても自律実行にならない。

一方 `--disable-sandbox` は SwiftPM に渡す普通のフラグなので、コマンドは Claude のサンドボックス**内**で完結し、`autoAllowBashIfSandboxed: true` によって無確認で実行される。ネットワーク・ファイルシステムの隔離もそのまま効いたままになる。

```bash
swift build --package-path "$(pwd)/LocalPackage" --disable-sandbox ...
swift test  --package-path "$(pwd)/LocalPackage" --disable-sandbox ...
```

`make build-local-package` / `make test-packages` / `make format` には既に `--disable-sandbox` が入っているので、これらを使う場合は何も足さなくてよい。

SwiftPM と SwiftLint はホームディレクトリ配下のキャッシュに書き込む。以下は `settings.local.json` の `sandbox.filesystem.allowWrite` で許可済み:

- `~/Library/org.swift.swiftpm`、`~/Library/Caches/org.swift.swiftpm`（マニフェストキャッシュ。無いとビルドが毎回遅くなる）
- `~/Library/Caches/SwiftLint`（SwiftLintプラグインのキャッシュ。無いとビルドが失敗する）
- `~/Library/Developer/Xcode/DerivedData`（xcodebuild用）

`attempt to write a readonly database` や `You don't have permission to save the file ...` が出たら、書き込み先を特定して `allowWrite` に足す。**この設定はセッション開始時にしか読まれない**ので、追加後は再起動が必要。

他のコマンド（swiftlint 単体実行など）はサンドボックス内でそのまま動く。`dangerouslyDisableSandbox: true` は最後の手段であり、まず「サンドボックス内で動かすには何を許可すればよいか」を考えること。

---

## 検証手順

### 0. stale な swift-test プロセスの掃除（必須）

`.build` ディレクトリは SwiftPM が排他ロックを取るため、過去セッションから残っている `swift-test` / `swiftpm-testing-helper` プロセスがあると、新しい `swift test` が "Another instance of SwiftPM ... is already running" で待機状態になり、永遠に進まなくなる。

**worktreeで並列作業している場合、他worktreeのプロセスを誤って kill しないよう、`--package-path` は必ず現在のworktreeの絶対パスで指定する**（相対パス `LocalPackage` だとどのworktreeでもコマンドライン文字列が同じになり、`pkill -f` が他worktreeのプロセスまで巻き込んでしまう）。以降の手順1・3のコマンドも同様に絶対パスを使うこと。

**`make test-packages` / `make build-local-package` は `$(CURDIR)` 基準で同じ掃除を先頭で実行するので、make 経由なら手順0は不要。** `swift` を直接叩く場合のみ以下を実行する:

```bash
# 現在のworktreeのLocalPackage絶対パスを基準にする
LOCAL_PACKAGE_PATH="$(pwd)/LocalPackage"
# このworktreeに紐づく古いプロセスのみを kill する（絶対パスで一致するため他worktreeは触らない）
pkill -f "swift-test --package-path ${LOCAL_PACKAGE_PATH}" 2>/dev/null
pkill -f "${LOCAL_PACKAGE_PATH}/.build" 2>/dev/null
# 残骸が無くなったか確認
ps aux | grep -E "swift-test|swiftpm-testing-helper" | grep "${LOCAL_PACKAGE_PATH}" | grep -v grep
```

最後のチェックで何も出力されなければ OK。残っていた場合は PID を確認して `kill <PID>` する。

### 1. ビルド確認

**LocalPackage配下のファイルを変更した場合（通常）:**

```bash
swift build --package-path "$(pwd)/LocalPackage" --disable-sandbox --sdk $(xcrun --sdk iphonesimulator --show-sdk-path) --triple arm64-apple-ios26.2-simulator
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
swift test --package-path "$(pwd)/LocalPackage" --disable-sandbox --enable-code-coverage
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

### SwiftLint `file_length` 警告について

`#Preview` によってファイル行数が400行を超えた `file_length` 警告は **別ファイルに切り出して解消しない**。Preview は元のView定義と同一ファイルに置く方が読みやすいというのがユーザーの意向。`file_length` 警告は警告のまま残してよい（コミットを止めない）。本体ロジックが膨らんでいる場合に限り責務分割を検討する。

## 並列実行のヒント

ビルドとSwiftLintは独立に走らせて問題ない。Bashの並列ツール呼び出しで時間短縮できる。
ただし、テストはビルドを前提とするので並列化しない。
