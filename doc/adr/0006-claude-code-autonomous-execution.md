## タイトル: Claude Codeの自律実行を成立させる（サンドボックス・許可モード・検証フック）

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-08-09
* 技術的背景: Claude Code v2.1.226 / [permission modes](https://code.claude.com/docs/en/permission-modes) / [sandboxing](https://code.claude.com/docs/en/sandboxing)

## 文脈、背景や問題点の説明

Claude Code に実装を任せても、`swift build` / `swift test` のたびに許可プロンプトが出て停止するため、開発者が張り付いていないと作業が進まなかった。許可ルール（`permissions.allow`）を追加し続けた結果 190 件超まで肥大したが、プロンプトは減らなかった。

原因は許可ルールの不足ではなく、**プロンプトの発生源が許可ルールの管轄外だったこと**にある。あわせて、検証手順がスキル・ルール上の「お願い」でしかなく、Claude が読み飛ばせばビルドが壊れたままターンが終わる構造も残っていた。

## 決定事項

* **SwiftPM は `--disable-sandbox`（SwiftPM 自身のフラグ）で Claude のサンドボックス内で実行する**。`dangerouslyDisableSandbox: true` は使わない
* **`permissions.defaultMode` を `auto` にする**（`~/.claude/settings.json`。project / local 設定では仕様上無視されるため）
* **`Stop` フックで `make test-packages` を実行し、失敗時は exit 2 で Claude を起こす**（`scripts/claude-verify-swift.sh`）
    * この決定は [ADR-0010](0010-stop-hook-scope-preview-check-only.md) で変更した。現在フックが実行するのは `make check-previews` のみ
* SwiftPM / SwiftLint のキャッシュ書き込み先を `sandbox.filesystem.allowWrite` で許可し、コミット対象の `.claude/settings.json` に置いてチームで共有する

### なぜ `dangerouslyDisableSandbox` が問題だったか

SwiftPM はマニフェスト評価を自前の `sandbox-exec` で行うため、Claude のサンドボックス内ではネストして失敗する。これを回避するため `dangerouslyDisableSandbox: true` を使う運用にしていたが、この引数は**サンドボックス外実行なので通常の許可フローに戻り、allow ルールの有無に関係なく毎回ゲートを通る**。`Bash(swift *)` を許可済みでも無意味だった。

`--disable-sandbox` は SwiftPM 側のサンドボックスだけを切るので、コマンドは Claude のサンドボックス内で完結し、`autoAllowBashIfSandboxed: true` により無確認で走る。ネットワーク・ファイルシステムの隔離は維持される。

## 考慮した選択肢

* **`sandbox.excludedCommands` に `swift` を追加** — SwiftPM をサンドボックス外で動かす。隔離が丸ごと外れるうえ、公式も「ツールに書き込みが必要なだけなら `allowWrite` を使うほうが望ましい」としているため不採用
* **`sandbox.enabled: false`** — 隔離を全廃。ネットワーク経由の情報漏洩に対する防御が消えるため不採用
* **`permissions.defaultMode: "bypassPermissions"`** — 全チェックを飛ばす。公式が隔離環境専用としており、ローカル開発機には不適切なため不採用
* **`defaultMode: "acceptEdits"` のまま許可ルールを足し続ける** — 現状維持。保護パス（`.claude/`）・未許可ドメイン・サンドボックス外実行のいずれも allow ルールでは消せないため、根本解決にならない
* **検証を `PostToolUse` フックで走らせる** — Swift ファイル編集のたびにテスト全体が走り遅すぎる。`Stop` なら1ターンに1回で済むため不採用

## 決定結果

### 決定にあたり考慮したメリット

* 開発者が張り付かなくても実装〜検証が進む
* 検証がスキルの記述ではなく harness の実行に変わり、確実に走る。ビルドが壊れたままターンが終わらなくなる
* サンドボックスの隔離境界を維持したまま実現できる（プロンプト削減と安全性のトレードオフを最小化）
* SwiftPM / SwiftLint のキャッシュが効くようになり、ビルド自体も速くなる

### 決定にあたり考慮したデメリット

* auto mode は分類器がリスクを判定するもので、安全を保証しない。公式も「方向性を信頼できる作業に使い、機微な操作のレビュー代替にはするな」としている
* 分類器の判定に往復のレイテンシとトークンコストがかかる
* `--disable-sandbox` により、人間が `make` を叩くときも SwiftPM のマニフェストサンドボックスが無効になる。CI・ローカルとも同じ挙動に揃える方を優先した
* `Stop` フックの分だけターン終了が遅くなる（Swift 変更が無ければスキップ、前回検証から変化が無ければスキップ、で軽減）
* 3回連続失敗で自動検証を止める設計のため、それ以降は人間の確認が要る

## 参考

* 手順とトラブルシュートは `.claude/skills/swift-code-verification/SKILL.md` と `~/.claude/skills/improve-setting/SKILL.md`
* [LoopsBench (arXiv:2608.00267)](https://arxiv.org/abs/2608.00267) — 長時間の自律ループでは最強構成でも解決率25%にとどまり、全構成でリグレッションが継続的に発生する。検証を決定論的に閉じる根拠
