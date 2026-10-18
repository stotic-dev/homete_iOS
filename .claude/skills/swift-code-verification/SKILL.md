---
name: swift-code-verification
description: homete iOSプロジェクトのSwiftコード変更後の検証フロー。`make affected` で変更に関係するモジュールを割り出し、そのモジュールだけをビルド・SwiftLint・ユニットテストする（全体ビルド・全テストは流さない）。HometeUI・FeatureのViewを変えたときは、そのモジュールのプレビューだけローカルでVRTを流す（iOS 27.0のiPhone 16限定）。Swiftファイルを編集・作成・削除した直後に必ず使う。ビルド・テストを流すか迷ったとき（Package.swiftやツール設定の変更など）も、影響範囲から要否を判断するためにこのスキルを参照する。
---

# Swiftコード変更後の検証スキル

## 対象タイミング

Swiftファイル（`*.swift`）を編集・作成・削除した後は、以下の検証を順番に実行する。
**変更に関係するテストターゲットがある限り、ユニットテスト（手順3）は省略不可。**

### 影響範囲を割り出してから流す（全体ビルド・全テストはしない）

検証は1回が高コスト（初回ビルドは10分以上）。マルチモジュールなので、変更が届くモジュールはパッケージの依存関係から決まる。
関係ないモジュールまでビルド・テストすると、待ち時間が丸ごと無駄になる。**最初に `make affected` を流し、出た範囲だけを検証する。**

```bash
make affected   # BASE=<ref> で起点を変えられる（既定は origin/main。分岐点以降のコミット＋未コミットの変更を見る）
```

```
変更されたターゲット: HouseworkFeature
テスト: HometeAppIntentsTests, HouseworkFeatureTests
iOS向けビルド: HomeFeature, HometeAppIntents
InfraPackageのビルド: 要
アプリ本体のビルド: 不要
ローカルVRT: HouseworkFeature
```

判定は `scripts/affected-modules.py` が行う。変更されたターゲットと、それに推移的に依存するターゲット（LocalPackage・InfraPackageの
`Package.swift`から読む）を影響範囲とする。たとえば `HouseworkFeature` を変えると、依存している `HometeAppIntents` のテストも流れる。
`HometeDomain` を変えればほぼ全部が対象になるが、それは実際に全部へ届くからで、絞れないのは正しい。

各行と、それを受けて流すコマンド:

| 行 | 流すもの |
|---|---|
| iOS向けビルド / InfraPackageのビルド | 手順1の `make build-affected`（両方まとめて面倒を見る） |
| アプリ本体のビルド: 要 | 手順1の `xcodebuild`（`homete/`・`hometeNotificationService/`・`homete.xcodeproj` を変えたときだけ） |
| テスト | 手順3の `make test-affected` |
| ローカルVRT | 手順4の `make snapshot-affected`（Viewの見た目に関わる変更のときだけ） |

全部「なし」「不要」なら、Swiftのビルドに影響しない変更なので、このスキルの検証は不要。`.claude/`・`doc/`・`CLAUDE.md`・
`firebase/functions/`・GitHub Actions・ツール設定などがこれに当たる。

`make build-local-package` / `make test-packages-fast` は全ターゲットが対象なので、`make affected` の判定が当てにならない場合
（`scripts/affected-modules.py` 自体を直したときなど）や、ユーザーに頼まれたときだけ使う。

Swiftに影響しない変更では、ビルドやテストの代わりに**変更したもの自体が動くか**を最小限で確かめる。例:

- wtのフック設定 → `wt hook show` でパースできるか、`wt hook <type> --dry-run` で展開結果が正しいか。重いフック（LocalPackageの初回ビルドなど）を実際に最後まで流す必要はない
- シェルスクリプト → `bash -n` での構文チェック、または対象コマンド単体の実行
- JSON / YAML → `jq` などでのパース確認

迷ったら「このファイルがSwiftのコンパイル・リンク・lintの入力になるか」で判断する。ならないなら流さない。

このスキルは Bash コマンドを以下の許可ルール下で実行する想定（プロジェクトの `.claude/settings.local.json` に登録済み）:
- `Bash(swift build:*)`, `Bash(swift test:*)`, `Bash(xcodebuild:*)`, `Bash(ProjectTools/.build/arm64-apple-macosx/debug/swiftlint lint:*)`

### サンドボックスの扱い（重要）

> staleプロセスの掃除を `ps` 依存から SwiftPM のビルドロック依存に切り替えた経緯は [ADR-0012](../../../doc/adr/0012-swiftpm-build-lock-based-stale-cleanup.md) を参照。

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

`make build-local-package` / `make test-packages-fast` / `make format` には既に `--disable-sandbox` が入っているので、これらを使う場合は何も足さなくてよい。

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

#### 依存の再取得が絡むエラーの切り分け

新規worktreeに限らず、**依存の更新（Dependabotのマージ後など）で SwiftPM が依存を取り直すたびに**起きる。

| エラー | 原因 | 対処 |
|---|---|---|
| `'<pkg>': You don't have permission to save the file "config" in the folder ".git"` | サンドボックスは**プロジェクト配下の `.git/config`・`.git/hooks` への書き込みを必ず拒否する**（gitフック注入対策の必須deny）。`.build/checkouts/<pkg>/.git/config` も対象。パス不足ではないので `allowWrite` では開けない | `make resolve-packages` を**1回だけ**流し、元のコマンドをサンドボックス内で再実行する。`.claude/settings.json` の `sandbox.excludedCommands` に登録してあるので、`dangerouslyDisableSandbox` を付けなくてもサンドボックス外で動く |
| `The signature of "xxx.xcframework" cannot be verified` / `ProcessXCFramework ... failed` | `codesign` が証明書チェーンの検証に使う `com.apple.trustd.agent` への mach-lookup がサンドボックスで拒否される（`gh` の `x509: OSStatus -26276` も同じ原因） | `.claude/settings.json` の `sandbox.enableWeakerNetworkIsolation: true`。セッション開始時にしか読まれない |
| `file '...FIRFieldValue.h' has been modified since the module file '...SwiftExplicitPrecompiledModules/*.pcm' was built` | 依存の取得・ビルドが途中で中断され、ヘッダだけ新しくなってモジュールキャッシュが古いまま残った | `rm -rf LocalPackage/.build/out/ModuleCache.noindex LocalPackage/.build/out/Intermediates.noindex/SwiftExplicitPrecompiledModules` してから再ビルド（サンドボックス内で可） |

`.build` ごと消すと次のビルドで必ず1行目を踏むので、キャッシュ破損の対処で `.build` 全体を消さないこと。

`.git/config` の拒否はサンドボックスの外側（`$TMPDIR`・`~/Library/Caches/org.swift.swiftpm` など）では起きない。プロジェクトディレクトリ配下だけが対象。

#### プロセス一覧（`ps` / `pgrep`）は使えない

サンドボックス下ではプロセス一覧の取得手段が**すべて**塞がれている。

| コマンド | 症状 |
| --- | --- |
| `ps` | `/bin/ps: Operation not permitted` |
| `pgrep` / `pkill` | `sysmond service not found` → `Cannot get process list` |
| `sysctl kern.proc.all` | `Operation not permitted` |

**これを許可する `sandbox.*` 設定は存在しない。** `filesystem.allowWrite` のようにプロセス情報だけを開ける項目は無く、唯一の回避策は `sandbox.excludedCommands` に `make *` を入れて make 実行全体をサンドボックス外に出すことだが、それではファイルシステム・ネットワークの隔離ごと失われるため採用していない。

そのため「残骸プロセスを探して kill する」系の手順は、Claude が実行する限り機能しない。代わりに **SwiftPM のビルドロック `LocalPackage/.build/.lock`** を見る。SwiftPM は自身の PID をこのファイルに書いてから `flock(2)` で排他するので、プロセス一覧なしでも保持者が分かる:

```bash
python3 scripts/swiftpm-build-lock.py "$(pwd)/LocalPackage/.build"
# held <pid> = 保持されている / free = 空き / absent = .lock が無い
```

#### Build Tool Plugin が `.build` に書けない場合（既知の症状）

Xcode 27 / Swift 6.2 環境で、`--disable-sandbox` を付けていても **SwiftPM の prebuild plugin（SwiftGenPlugin / SwiftLintPlugin）だけが書き込みに失敗する**ことがある:

```
error: failed: PrebuildCommand(... displayName: Optional("SwiftGen BuildTool Plugin") ...)
Error: You don’t have permission to save the file “Assets.swift” in the folder “SwiftGenPlugin”.
```

`allowWrite` の不足ではない。切り分け方は次の2つで、**どちらも成功するのに `swift build` 経由だけ失敗するなら nested sandbox が原因**:

```bash
# 1) シェルから同じディレクトリに直接書けるか
touch LocalPackage/.build/plugins/outputs/localpackage/HometeResources/destination/SwiftGenPlugin/__probe.txt
# 2) プラグインのバイナリを手で叩いて同じ出力先に書けるか
LocalPackage/.build/artifacts/.../swiftlint lint --cache-path "LocalPackage/.build/plugins/.../Cache" <file.swift>
```

対処は `settings.local.json` の `sandbox.enableWeakerNestedSandbox: true`（設定済み）。**セッション開始時にしか読まれない**ので、追加直後のセッションでは効かない。

それでも失敗し、かつ上記の切り分けで nested sandbox が原因と確認できた場合に限り、その1コマンドだけ `dangerouslyDisableSandbox: true` で実行してよい。ただし**許可プロンプトが出て自律実行が止まる**ため、常用しないこと。恒久対応が必要になったら `sandbox.excludedCommands` に `swift` / `make` を入れる方を検討する。

---

## 出力の絞り方（再実行しないために）

検証コマンドは1回が高コスト（ビルド約80秒、テストはテストターゲットを順に実行）。
**絞り方を誤って結果が読めず「もう一度流す」のは、待ち時間が丸ごと無駄になる。** 実行する前にフィルタを決め、
どう転んでも1回で合否を判定できる形にする。

### ログをファイルに残してからフィルタする

`tee` を挟んでおけば、絞り方を間違えてもコマンドを流し直さずログを読み直すだけで済む。判断に必要な情報が
足りないと分かった時点では既にビルド成果物もログも手元にあるので、再実行する理由はない。

```bash
LOG="$TMPDIR/verify-test.log"
make test-affected 2>&1 | tee "$LOG" | grep -E "テスト対象|Test run with|✘|error:|failed"
# 情報が足りなければ、再実行せず保存済みログを読む
grep -n -B5 -A20 "✘" "$LOG"
```

### `tail` を合否判定に使わない

`make test-affected` / `make test-packages-fast` はテストターゲットごとに `Test run with N tests in M suites passed` を出す。
`tail -25` だと最後のターゲットの出力しか映らず、**残りが通ったのか落ちたのか分からない**。
`tail` が妥当なのは、末尾にだけ結論が出るコマンド（`swift build` の `Build complete!` など）に限る。

### コマンド別の推奨フィルタ

- `make build-affected` / `swift build`
  → `grep -E "^===|error:|Build complete|InfraPackage"`。ビルドしたターゲットの数だけ `Build complete!` が出ていれば OK
- `make test-affected` / `swift test`
  → `grep -E "テスト対象|Test run with|✘|error:"`。`Test run with ... passed` が、`テスト対象` に出たテストターゲットの
  数だけ並べば OK（1行でも欠けていたらログ本体を確認する）
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

**`make test-affected` / `make build-affected` などLocalPackageを触るmakeターゲットは `$(CURDIR)` 基準のロック（`scripts/with-local-package-lock.sh`）で排他制御されるので、make 経由なら手順0は不要。** 同じworktreeで既に別の `make test-packages-fast`/`build-local-package` が走っている場合は pkill せず完了を待つ（誤って現在進行中のプロセスを殺さないため）。真にstale（保持プロセスが死んでいる）なロックだけを自動で掃除する。

make 経由なら、他プロセスがビルドロックを握っている場合に実行前へ次の警告が出る。**これが出たら待ち時間はハングではなくロック待ちなので、タイムアウトまで放置せず PID を kill する。**

```
SwiftPMのビルドロック(.../LocalPackage/.build/.lock)を別プロセスが保持しています。
解放されるまでswiftコマンドは何も出力せずに待機します（ハングではありません）。
保持者: PID 12345。前セッションの残骸であれば kill 12345 で解消します。
```

`swift` を直接叩く場合のみ、以下で残骸を確認・掃除する。**サンドボックス下では `ps` / `pgrep` が使えない**（[プロセス一覧（`ps` / `pgrep`）は使えない](#プロセス一覧ps--pgrepは使えない)）ため、ロックファイルから保持者を特定する:

```bash
# 現在のworktreeのLocalPackage絶対パスを基準にする（他worktreeを巻き込まないため）
LOCAL_PACKAGE_PATH="$(pwd)/LocalPackage"
python3 scripts/swiftpm-build-lock.py "${LOCAL_PACKAGE_PATH}/.build"
```

`free` / `absent` なら OK。`held <pid>` が出たら、そのPIDが現在進行中の作業でないことを確認して `kill <pid>` する。

### 1. ビルド確認

```bash
make build-affected
```

`make affected` の「iOS向けビルド」に出たLocalPackageのターゲットを、iOSシミュレーター向けに1つずつ `swift build --target` する。
他の対象の依存に含まれるターゲットは省くので、ビルドの範囲は影響範囲と同じになる。続けて、影響範囲がInfraPackageに届いていれば
`make build-infra-package` も流す。

InfraPackageは`AppRoot`経由で全Featureに依存しているので、LocalPackage側の変更で壊れるのはこちら。テストでは気付けない。
`.build`はLocalPackageと別（`InfraPackage/.build`）なので、新しいworktreeでの初回ビルドや依存の更新後は、Firebase・AdMobの
xcframeworkの署名検証でサンドボックス内だと落ちる（`The signature of "….xcframework" cannot be verified`）。
初回だけ `make build-infra-package` をサンドボックス外で流せば、以降はサンドボックス内で通る。

**「アプリ本体のビルド: 要」のときだけ（`homete/`・`hometeNotificationService/`・`homete.xcodeproj` を変更した場合）:**

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

このパスが無い場合は先に `make setup-project` または `swift build --package-path ProjectTools --scratch-path ProjectTools/.build` を実行する。ただし SwiftLint はソースからビルドされるのではなく artifactbundle で配布されるため、`swift build` してもこのシンボリックリンクは作られないことがある。その場合は実体を直接叩く:

```bash
ProjectTools/.build/artifacts/projecttools/SwiftLintPluginBinary/SwiftLintBinary.artifactbundle/swiftlint-0.59.1-macos/bin/swiftlint lint
```

なお手順1のビルドが通っていれば SwiftLintPlugin が同じ lint を実行済みなので、この手順は「ビルド対象外のファイル（`homete/` 配下など）も含めて全体を確認する」ためのもの。

### 3. ユニットテスト実行（対象があれば省略不可）

```bash
make test-affected
```

`make affected` の「テスト」に出たテストターゲットだけを `swift test --filter` で実行する。対象が無ければ何も流さずに終わる
（そのときは変更を確かめるテストが存在しないということなので、手順1のビルドが通れば十分）。

SwiftPMはテストを1つのテストバンドルにまとめるので、`--filter` で絞っても**ビルドは全テストターゲット分**かかる。
ただし差分ビルドなので、変更していないモジュールはコンパイルし直さない。絞れるのは実行の方で、関係ないテストの実行と失敗の読み解きを省ける。

特定のSuiteだけ流したいときは `make test-packages-fast FILTER=<テストターゲット名またはSuite名>` を使う
（例: `make test-packages-fast FILTER=HouseworkFeatureTests`）。

ローカルではカバレッジを付けない（`make test-packages` や `COVERAGE=1` は使わない）。カバレッジの有無でビルド成果物が別物になり、
切り替えるたびにLocalPackage全体のビルドがやり直しになる（差分ビルド約20秒が約4分になる）。カバレッジはCI（Dangerのレポート）だけで取る。

CI（`ci_local_package.yml`）もPRでは同じ判定で `make test-affected COVERAGE=1` を流す。mainへのpushでは全テストを流す。

### 4. UIデグレ確認（VRT / スナップショットテスト）

```bash
make snapshot-affected
```

**流すのは、`make affected` の「ローカルVRT」にモジュールが出ていて、かつViewの見た目に関わる変更をしたときだけ。**
StoreやUseCaseなどロジックだけの変更では流さない。全プレビューの確認と参照スナップショットの更新はXcode Cloudの`VRT`ワークフローの役目で、
ローカルは「直接変えたモジュールのプレビューが崩れていないか」をPRの前に確かめるためのもの。そのため、対象は
**直接変更したHometeUI・Featureのプレビューだけ**にしている（HometeUIやHometeDomainを変えても、依存するFeatureのプレビューまでは広げない）。
VRTの設定（`hometeVRT.xcodeproj`・`.prefire.yml`・テンプレートなど）を変えたときは全プレビューが対象になる。

`scripts/run-affected-snapshots.sh` が次のことをする:

- **iOS 27.0のiPhone 16でしか流さない。** 参照スナップショットはXcode CloudのiOS 27.0で記録しており、マイナーバージョンが
  違うだけで描画に差分が出る。iOS 27.0のiPhone 16が無ければエラーで止まるので、他のシミュレータで代用しない。
  ランタイムが無ければユーザーに入れてもらうか、ローカルVRTは飛ばしてCIに任せる
- テストのタイムゾーンを、Xcode Cloudのランナーと同じ太平洋時間（`America/Los_Angeles`）にする。東京時間で固定した日付（`previewDate`）の表示が1日ずれるのを防ぐため
- `hometeVRT.xcodeproj` をbuild-for-testingし、Prefireが生成したテストのうち対象モジュールのプレビューだけを `-only-testing` で流す
- **参照スナップショットは書き換えない。** 参照の無い新しいプレビューは、ライブラリが参照PNGを書き出したうえで失敗する。
  書き出されたPNGはスクリプトが消す（参照の記録はCIが `chore: VRT参照スナップショットを自動更新` で行う）。
  新しく足したプレビューの「No reference was found」は想定どおりの失敗なので、直す必要はない
- 差分が出たときの画像は `~/Library/Developer/Xcode/DerivedData/hometeVRT-affected/SnapshotFailures` に出る

xcodebuildはClaudeのサンドボックス内だと `sandbox_apply: Operation not permitted` で落ちるので、サンドボックス外で流す。

差分が出たら、意図した見た目の変更か、デグレかを差分画像で見分ける。意図した変更ならそのままPRを出し、CIに参照を更新させる。
デグレなら直してから流し直す。

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
