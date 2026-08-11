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

ビルドツールが書き込む先は `settings.local.json` の `sandbox.filesystem.allowWrite` で許可済み:

- `/var/folders/<user-hash>/T`・`/C`（`/private/var/folders/...` 版も）— **最重要**。下記参照
- `~/Library/org.swift.swiftpm`、`~/Library/Caches/org.swift.swiftpm`（マニフェストキャッシュ。無いとビルドが毎回遅くなる）
- `~/Library/Caches/SwiftLint`、`~/Library/Caches/com.charcoaldesign.swiftformat`（lint/formatキャッシュ）
- `~/Library/Developer/Xcode/DerivedData`（xcodebuild用）

### `You don't have permission to save the file ...` の正体

Claudeのサンドボックスは `TMPDIR` を `/tmp/claude-501` に差し替えるが、Foundation の atomic write
（`write(atomically: true)` 系）は `TMPDIR` を見ず `confstr(_CS_DARWIN_USER_TEMP_DIR)`＝
`/var/folders/<user-hash>/T/TemporaryItems/` に中間ファイルを作ってから rename する。
ここが不許可だと、**書き込み先ディレクトリ自体はサンドボックス的に書けるのに EPERM で落ちる**。
`touch` は通るのに SwiftPM・SwiftGen・SwiftLint が「保存する権限がありません」で落ちる、という一見矛盾した症状はこれ。
clangのモジュールキャッシュ（`/var/folders/<user-hash>/C/clang/ModuleCache`）も同じ理由で `/C` の許可が要る。

実際の拒否内容はカーネルログで確認できる（`dangerouslyDisableSandbox: true` が必要）:

```bash
/usr/bin/log show --predicate 'senderImagePath CONTAINS "Sandbox"' --last 10m --style compact | grep deny
```

`deny(1) sysctl-read kern.iossupportversion` は大量に出るが無害（ビルドは通る）。

**`sandbox` の設定はセッション開始時にしか読まれない**ので、追加後は再起動が必要。

他のコマンド（swiftlint 単体実行など）はサンドボックス内でそのまま動く。`dangerouslyDisableSandbox: true` は最後の手段であり、まず「サンドボックス内で動かすには何を許可すればよいか」を考えること。

---

## 出力の絞り方（再実行しないために）

検証コマンドは1回が高コスト（ビルド約80秒、`make test-packages` は5つのテストターゲットを順に実行）。
**絞り方を誤って結果が読めず「もう一度流す」のは、待ち時間が丸ごと無駄になる。** 実行する前にフィルタを決め、
どう転んでも1回で合否を判定できる形にする。

### ログをファイルに残してからフィルタする

`tee` を挟んでおけば、絞り方を間違えてもコマンドを流し直さずログを読み直すだけで済む。判断に必要な情報が
足りないと分かった時点では既にビルド成果物もログも手元にあるので、再実行する理由はない。

```bash
LOG="$TMPDIR/verify-test.log"
make test-packages 2>&1 | tee "$LOG" | grep -E "Test run with|✘|error:|failed"
# 情報が足りなければ、再実行せず保存済みログを読む
grep -n -B5 -A20 "✘" "$LOG"
```

### `tail` を合否判定に使わない

`make test-packages` はテストターゲットごとに `Test run with N tests in M suites passed` を出す。
`tail -25` だと最後のターゲットの出力しか映らず、**残りが通ったのか落ちたのか分からない**。
`tail` が妥当なのは、末尾にだけ結論が出るコマンド（`swift build` の `Build complete!` など）に限る。

### コマンド別の推奨フィルタ

- `swift build` / `make build-local-package`
  → `grep -E "error:|Build complete"`。`Build complete!` が出ていれば OK
- `make test-packages` / `swift test`
  → `grep -E "Test run with|✘|error:"`。`Test run with ... passed` がテストターゲットの数だけ並べば OK
  （現在は HometeDomainTests / HouseworkFeatureTests / HouseworkTemplateFeatureTests / SettingFeatureTests /
  ContributionFeatureTests の5行。1行でも欠けていたらログ本体を確認する）
- `swiftlint lint`
  → 元々短いので絞らなくてよい。絞るなら `grep -E "warning:|error:"` で、自分が触ったファイルの行が無いことを見る
- `xcodebuild ... -quiet`
  → `grep -E "error:|\*\* TEST|\*\* BUILD"`。`** BUILD SUCCEEDED **` / `** TEST SUCCEEDED **` を確認

grep はマッチ0件で終了コード1を返すため、コマンド全体が失敗したように見えることがある。合否は終了コードでは
なく出力内容で判断する（気になるなら `|| true` を付ける）。

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
