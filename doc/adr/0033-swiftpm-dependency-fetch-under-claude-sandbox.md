## タイトル: 依存の再取得でSwift検証がClaude Codeのサンドボックス内で落ちる問題への対処

* **ステータス: 提案済**
* 意思決定者: @stotic-dev
* 日付: 2026-10-03
* 技術的背景やその他関連チケット No: Issue #369 / [ADR-0006](0006-claude-code-autonomous-execution.md) を補完する

## 文脈、背景や問題点の説明

[ADR-0006](0006-claude-code-autonomous-execution.md) でSwiftPMを `--disable-sandbox` 付きでClaude Codeのサンドボックス内で動かす運用にしたが、依存を取り直す必要があるとき（新規worktree、Dependabotによる依存更新のマージ後）だけは `make build-local-package` / `make test-packages` が落ち、`dangerouslyDisableSandbox: true` での再実行＝許可プロンプトが必要になっていた。

失敗は2種類あり、どちらもパス不足ではなかった。

1. `.build/checkouts/<pkg>/.git/config` に書けない
   * サンドボックスは**プロジェクトディレクトリ配下の `.git/config`・`.git/hooks` への書き込みを必ず拒否する**（gitフック・設定の注入対策）。同じディレクトリの `.git/HEAD`・`.git/objects` は書け、`$TMPDIR` や `~/Library/Caches/org.swift.swiftpm` 配下では `.git/config` も書けることを確認した
2. xcframeworkの署名検証（`ProcessXCFramework`）が `cannot be verified` で落ちる
   * `codesign --verify` がサンドボックス内だけ `invalid signature` になる。カーネルログで `codesign deny(1) mach-lookup com.apple.trustd.agent` を確認し、`sandbox-exec` で `com.apple.trustd.agent` だけを塞いだ環境で同じ失敗を再現した。証明書チェーンの評価ができないことが原因で、`gh` の `x509: OSStatus -26276` も同根

## 決定事項

* **xcframeworkの署名検証は `sandbox.enableWeakerNetworkIsolation: true` で通す**
  * `com.apple.trustd.agent` へのアクセスを許可する公式の設定で、TLS検証が必要な `gh` も同時に直る
  * チーム全員に必要なので `.claude/settings.json`（コミット対象）に置く
* **`.git/config` は開けないので、依存の取得だけをサンドボックス外で流す `make resolve-packages`（`scripts/resolve-swift-packages.sh`）を用意する**
  * `sandbox.excludedCommands` に `make resolve-packages` を登録し、許可済みの `Bash(make *)` で無確認実行できるようにする
  * サンドボックス外で流す前提なので、SwiftPM自身のマニフェストサンドボックスは有効のまま（`--disable-sandbox` を付けない）
* 中断で壊れたモジュールキャッシュの復旧手順は `swift-code-verification` スキルの切り分け表に置く

## 考慮した選択肢

* **`allowWrite` に `.build/checkouts` を足す** — 拒否は必須denyによるもので、許可パスを足しても開かない設計。不採用
* **`.build` をプロジェクト外（`~/Library/Caches` など）に置く** — `.git/config` の拒否はプロジェクト配下だけなので理屈上は通るが、worktreeごとの `.build`・ロックスクリプト・wtフック・CIのパス前提を全部変えることになる。依存更新時の1回のために払うコストではないため不採用
* **`sandbox.excludedCommands` に `swift` / `make *` を入れる** — ビルド・テスト全体が隔離の外に出る。[ADR-0006](0006-claude-code-autonomous-execution.md) で却下した案と同じ理由で不採用。除外は依存の取得という狭い1コマンドに限る
* **現状維持（落ちたら都度 `dangerouslyDisableSandbox: true`）** — 毎回許可プロンプトで自律実行が止まる。不採用

## 決定結果

### 決定にあたり考慮したメリット

* xcframeworkの署名検証は設定だけで解消し、サンドボックス外での実行が不要になる
* 依存更新後に必要な人手の介在が、許可プロンプト付きの任意コマンドから「`make resolve-packages` を1回」に限定される
* `gh` のTLS検証もサンドボックス内で通るようになる

### 決定にあたり考慮したデメリット

* `enableWeakerNetworkIsolation` はtrustdサービス経由のデータ持ち出し経路を開ける（公式ドキュメントでもセキュリティ低下と明記）。ネットワークの許可ドメイン制限は維持されるため許容する
* `make resolve-packages` はサンドボックス外で依存のgit clone・マニフェスト評価を行う。取得先は `Package.resolved` で固定され、マニフェスト評価にはSwiftPM自身のサンドボックスが効くため許容する
* `sandbox.*` の設定はセッション開始時にしか読まれないため、反映には再起動が必要

## 参考

* [Claude Code sandboxing](https://code.claude.com/docs/en/sandboxing)
* `.claude/skills/swift-code-verification/SKILL.md`「依存の再取得が絡むエラーの切り分け」
