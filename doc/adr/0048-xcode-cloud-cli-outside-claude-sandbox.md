## タイトル: Xcode Cloudの確認スクリプトだけをClaude Codeのサンドボックス外で動かす

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-10-18
* 技術的背景やその他関連チケット No: PR #458 のVRT失敗の調査 / [ADR-0036](0036-swiftpm-dependency-fetch-under-claude-sandbox.md) と同じ方式

## 文脈、背景や問題点の説明

PR #458 のVRTが失敗したとき、ユーザーがApp Store Connectからログとxcresultのzipを手でダウンロードしてClaudeに渡していた。Xcode MCPではXcode Cloudの状態もログも取れない。App Store Connect APIの `ciBuildRuns` / `ciBuildActions` で取れるので、`scripts/appstoreconnect.sh` のJWT生成を流用した `scripts/xcode-cloud.sh` を作った。

ただし、Claude Codeのサンドボックス内では動かない。

* 秘密鍵（`private_keys/` 配下の `.p8`）の読み取りが `**/private_keys` のdenyで拒否される
* `api.appstoreconnect.apple.com` と、artifactの署名付きダウンロードURLのホスト（`cvws.icloud-content.com`）が許可ドメインに無い

`dangerouslyDisableSandbox: true` で流すと毎回許可プロンプトで自律実行が止まる。サンドボックスにも許可プロンプトにも止められずに、このスクリプトだけを実行できるようにしたい。

## 決定事項

* **`.claude/settings.json` の `sandbox.excludedCommands` に `scripts/xcode-cloud.sh *` だけを登録する**
  * 許可プロンプトを出さないため、同じパターンの `Bash(scripts/xcode-cloud.sh *)` を `permissions.allow` に置く。除外とセットでないと意味がないので、個人用の `settings.local.json` ではなくチーム共有の `settings.json` に置く
  * スキル（`.claude/skills/xcode-cloud-check/`）には「サンドボックス外で動く設定済み、`dangerouslyDisableSandbox` は不要」「単独で呼ぶ」と書く
* **makeターゲット（`make xcode-cloud ARGS=...`）は人間用の入口として用意するが、除外対象には入れない**（理由は下記）
* スクリプト側で、サンドボックス外で動くことを前提に書き込みの範囲を狭めておく
  * `download --out` は存在しないか空のディレクトリだけ受け付ける（既存のファイルを上書きしない）。省略時は `$TMPDIR` に新しく作る
  * artifactのzipはファイルごとに新しいディレクトリへ展開し、シンボリックリンクを含むzipは展開しない
  * 署名付きのダウンロードURLは表示しない

### `excludedCommands` の一致のしかた（2026-10 時点の公式ドキュメント）

* パターンは `Bash(...)` の許可ルールと同じ書式で、**呼び出しに含まれる全コマンドが一致したときだけ**サンドボックス外になる。`scripts/xcode-cloud.sh status 458 | grep x` は `grep` が一致しないのでサンドボックス内に留まる
  * [ADR-0012](0012-swiftpm-build-lock-based-stale-cleanup.md) には「複合コマンドの一部が一致すれば全体が非サンドボックス」と書いたが、現在の仕様はこの逆
* リダイレクト（`2>&1` を除く）・`cd`・`$(...)`・サブシェル・`if`/`for` を含む呼び出しもサンドボックス内に留まる
* 一致はコマンドの文字列で見るので、`./scripts/xcode-cloud.sh` や絶対パスでの呼び出しは一致しない
* 除外されたコマンドも通常の許可フローは通る（allowルールに一致すれば無確認、auto modeでは分類器が判定）

### ADR-0036 の設定が入っていなかった件

ADR-0036 は `make resolve-packages` を `excludedCommands` に、`enableWeakerNetworkIsolation: true` を `sandbox` に入れると決めたが、現在の `.claude/settings.json` にはどちらも無い。PR #371 の時点で `.claude/settings.json` の編集がauto modeの分類器に「Claude自身の権限拡大」として拒否され、PRの説明に「マージ前に手で追加する」と書いたまま適用されずにマージされていた（ADR-0036のステータスが「提案済」のままなのはこのため）。今回は `.claude/settings.json` をEditツールで編集し、許可プロンプトでユーザーの承認を得て入れた。ADR-0036 側の設定は今回の対象外とし、入れるかは別途判断する。

## 考慮した選択肢

* **`sandbox.filesystem.allowRead` で `private_keys` を開け、`allowedDomains` に通信先を足す** — 鍵を読めるのがこのスクリプトだけでなく、サンドボックス内の全コマンドになる。App Store ConnectのAPIキーはアプリのメタデータや課金設定まで操作できるため不採用
* **makeターゲットも `excludedCommands` に入れる（`make xcode-cloud *`）** — パターンの末尾の `*` が任意の引数に一致するため、`make xcode-cloud format`（別ターゲットの同時実行）、`make xcode-cloud -f <別のMakefile>`、`make xcode-cloud SHELL=...` まで外に出る。実質 `make *` の除外に近くなるため不採用。スクリプトを直接除外すれば、引数はスクリプト自身の引数解析にしか届かない
* **`scripts/*` を除外する** — 他のスクリプト（`appstoreconnect.sh` の書き込み系や `revenuecat.sh`）まで外に出る。不採用
* **現状維持（都度 `dangerouslyDisableSandbox: true`）** — 許可プロンプトで自律実行が止まる。VRTの失敗確認や `wait` での完了待ちのように繰り返し使う用途に合わない。不採用

## 決定結果

### 決定にあたり考慮したメリット

* Xcode Cloudの状態・失敗したテスト・ログ・xcresultを、人手のダウンロードなしにClaudeが取れる
* 秘密鍵を読めるのはこのスクリプトだけで、サンドボックス内の他のコマンドからは引き続き読めない
* 除外が1パターンに限られ、何がサンドボックス外で動くかが設定から読み取れる

### 決定にあたり考慮したデメリット

* 除外は「このファイルのパスで呼んだコマンド」に効くので、`scripts/xcode-cloud.sh`・source している `scripts/appstoreconnect.sh`・`scripts/appstoreconnect.env` の中身を書き換えればサンドボックス外で任意のコードが動く。公式ドキュメントも作業ディレクトリ内のスクリプトを除外する危険を警告している。これらの変更はレビューで見る前提で許容する（ADR-0036 の `make resolve-packages` も同じ性質）
* 呼び出し方の制約（単独で呼ぶ、パイプ・リダイレクトをしない）をスキルに書いて守ってもらう必要がある
* `sandbox.*` の設定はセッション開始時にしか読まれないため、反映の確認は再起動後になる

## 参考

* [Claude Code sandboxing — Run commands outside the sandbox with excludedCommands](https://code.claude.com/docs/en/sandboxing)
* [settings reference — sandbox.excludedCommands](https://code.claude.com/docs/en/settings-reference#sandbox-excludedcommands)
* [App Store Connect API — Xcode Cloud Workflows and Builds](https://developer.apple.com/documentation/appstoreconnectapi)
* `.claude/skills/xcode-cloud-check/SKILL.md`
