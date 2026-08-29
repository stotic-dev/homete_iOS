## タイトル: LocalPackageの多重実行防止をpkillからロックに変更する

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-08-29
* 技術的背景: [ADR-0006](0006-claude-code-autonomous-execution.md)、[ADR-0010](0010-stop-hook-scope-preview-check-only.md)

## 文脈、背景や問題点の説明

`make test-packages` / `make build-local-package` は、SwiftPM の `.build` ディレクトリが排他ロックを取ることに起因する "Another instance of SwiftPM ... is already running" を避けるため、実行前に `pkill -f "<LocalPackageのパス>"` で同じworktreeの残骸プロセスを掃除していた。

これは「stale（前回セッションの残骸）」と「同じworktreeで今まさに走っている別のmake実行」を区別できなかった。Stop フックの自動検証（[ADR-0006](0006-claude-code-autonomous-execution.md)）と手動実行が同じworktreeで重なった際、後発の `pkill -f "swift-test --package-path <path>"` が先発の**現在進行中**の `swift-test` プロセスを正しくパターンマッチした上で殺してしまい、`Terminated: 15` で異常終了した。さらに、殺された側が確保していた SwiftPM の `.build` ロックが残ったまま解放されず、後続の実行が数分単位でハングした。

[ADR-0010](0010-stop-hook-scope-preview-check-only.md) で Stop フックから `make test-packages` を外したことで主要な発生源は無くなったが、`pkill` 自体は「stale」と「実行中」を区別しない設計のままであり、手動で `make test-packages` を誤って二重に実行した場合などに同じ事故が再現する。

## 決定事項

* `scripts/kill-stale-swift-processes.sh` と `scripts/with-local-package-lock.sh` を新設する
  * `kill-stale-swift-processes.sh`: 対象プロセスを `ps` の実行バイナリ名（`swift` / `swift-build` / `swift-test` / `swiftpm-testing-helper`）で絞り込んでから kill する。`make` / `sh` / `pkill` など無関係なプロセス（argv にたまたま同じパス文字列を含むもの）を巻き込まない
  * `with-local-package-lock.sh`: PID を記録したロックディレクトリ（`<LocalPackage>/.build/.make-lock`）で排他制御する。ロックが生存中の別プロセスに保持されていれば **kill せず完了を待つ**。ロック保持者が既に死んでいる場合のみ、真にstaleなプロセスとして `kill-stale-swift-processes.sh` で掃除してから奪取する
* `Makefile` の `build-local-package` / `test-packages` は、直接 `pkill` する代わりに `scripts/with-local-package-lock.sh <LocalPackage絶対パス> -- <実行コマンド>` でラップする

## 考慮した選択肢

* **`pkill` のマッチ対象をプロセス名ベースに絞るだけ（ロックは導入しない）** — `make`/`sh`/`pkill` 自身を誤って巻き込む経路は防げるが、「同じworktreeで2つの `make test-packages` が同時に走ると後発が先発の実行中プロセスを殺す」という本質的な事故は残る（正確にマッチした上で殺すため）。今回再現した事故の直接原因はこちらだったため不採用
* **`sandbox.excludedCommands` 等でそもそも並行実行を防ぐ** — Claude Code側の設定であり、人間が手動で二重実行するケースを防げない。ツール非依存の対策にならないため不採用
* **何もしない（ADR-0010でStopフックからテストを外したので実害は減ったとみなす）** — 手動での二重実行事故は今後も起こり得り、発生時のデバッグコスト（`Terminated: 15` の原因調査に時間がかかった実績がある）を考えると、根本修正の方が安い。不採用

## 決定結果

### 決定にあたり考慮したメリット

* 同じworktreeで `make test-packages` / `build-local-package` を誤って二重実行しても、後発は先発を殺さず待つだけになり、`Terminated: 15` やSwiftPMロックのハングが起きなくなる
* stale判定を「ロック保持者の生死」で行うため、pkillのパターンマッチに起因する誤kill（今回のような）が構造的に発生しなくなる
* CI（`ci_local_package.yml`）は1ジョブ内で逐次実行のみのため、ロック待ちが発生することはなく影響がない

### 決定にあたり考慮したデメリット

* ロック機構という新しい可動部が増える。ロックディレクトリが `.build` ごと削除されずに残る異常系（例: SIGKILLで即死しtrapが走らない場合）では次回起動時に「ロック保持者は死んでいる」と正しく判定して奪取するため実害は無いが、コード量は増えている
* 二重実行時、後発は最大10分（`WAIT_TIMEOUT_SECONDS`）待ってからタイムアウトする。以前の「即座に殺して自分が実行する」動作と比べてターン終了は遅くなり得るが、そもそも二重実行を避けるべきという運用（[swift-code-verification](../../.claude/skills/swift-code-verification/SKILL.md)の「ビルド・テストはフォアグラウンドで実行」）が前提のため許容する

## 参考

* `scripts/with-local-package-lock.sh`、`scripts/kill-stale-swift-processes.sh`
* `.claude/skills/swift-code-verification/SKILL.md`
