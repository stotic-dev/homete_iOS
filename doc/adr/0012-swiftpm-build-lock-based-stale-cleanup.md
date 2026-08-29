## タイトル: staleなswiftプロセスの掃除を`ps`依存からSwiftPMビルドロック依存に切り替える

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-08-30
* 技術的背景: [ADR-0011](0011-local-package-lock-instead-of-pkill.md)、[Issue #226](https://github.com/stotic-dev/homete_iOS/issues/226)

## 文脈、背景や問題点の説明

[ADR-0011](0011-local-package-lock-instead-of-pkill.md) で導入した `scripts/kill-stale-swift-processes.sh` は、掃除対象の特定を `ps -eo pid=,args=` に頼っている。しかし Claude Code のサンドボックス（`.claude/settings.local.json` の `sandbox.enabled: true`）配下では `ps` の実行が許可されておらず、`/bin/ps: Operation not permitted` で失敗する。スクリプトは `set -e` を使わず末尾が `exit 0` のため**失敗しても成功扱いで終了し、掃除が丸ごとスキップされたことに誰も気付けなかった**。

結果として次の事故が起きた。前セッションの `swift-build` が `LocalPackage/.build` の SwiftPM ロックを保持したまま残り、新しい `swift build` が**一切の出力を出さないまま**（ログファイルが0バイトのまま）ロック解放を待ち続けて10分のタイムアウトに達した。ハングとの区別がつかず原因特定に時間がかかったが、該当プロセスを手で kill したところ同じビルドが23秒で完了した。

## 決定事項

* **`ps` の失敗を検知して呼び出し元に伝える。** `kill-stale-swift-processes.sh` は `ps` が失敗した場合、理由を stderr に出したうえで終了コード `2` を返す。`with-local-package-lock.sh` はこれを受けて警告を出す
* **`<LocalPackage>/.build/.lock` を第2の掃除手段として追加する。** SwiftPM はこのファイルに自身のPIDを書き込んでから `flock(2)` で排他するため、プロセス一覧が無くても「今まさにビルドロックを握っている者」だけは特定できる。判定は `scripts/swiftpm-build-lock.py`（`flock` の非ブロッキング取得を試す）が行う。`ps` が使えない環境ではこの経路だけで掃除する
* **ロック待ちに入る前に保持者を通知する。** `with-local-package-lock.sh` は make-lock 奪取後・コマンド実行前にビルドロックの保持状況を確認し、保持されていれば保持者PIDと「ハングではなく待機である」ことを stderr に出す。ここでは kill しない（make を通さず直接叩かれた `swift` を巻き添えにしないため）

## 考慮した選択肢

* **サンドボックスで `ps` を許可する** — 調査した結果、**これを可能にする `sandbox.*` 設定は存在しない**。`filesystem.allowWrite` のようにプロセス情報だけを開ける項目は無く、`pgrep`（`sysmond service not found`）・`sysctl kern.proc.all`（`Operation not permitted`）も同様に塞がれている。唯一の回避策は `sandbox.excludedCommands` に `make *` を入れて make 実行全体をサンドボックス外に出すことだが、`excludedCommands` は「複合コマンドの一部が一致すればコマンド全体を非サンドボックスで実行する」仕様のため、ファイルシステム・ネットワークの隔離ごと失われる。ビルドの安全性と引き換えにするには代償が大きく不採用
* **`lsof` でロックファイルの保持者を特定する** — `lsof` もプロセス情報を要求するためサンドボックス下では同様に機能しない
* **ロックディレクトリに記録したPIDのみを対象に `kill` する** — `with-local-package-lock.sh` は既にPIDファイルを持つが、記録しているのはラッパースクリプト自身のPIDであり、実害を出す `swift-build` / `swiftpm-testing-helper` はその子孫にあたる。プロセスグループを記録して一括 kill する案も検討したが、ジョブ制御（`set -m`）でコマンドを別プロセスグループに置く必要があり、Ctrl-C の伝播や stdin の扱いが変わる。今回の事故は「make-lock 保持者は生存しており、ロックを握っていたのは**それより前のセッションの残骸**」だったため、この方式では救えない。得られる範囲の割に可動部が増えるため不採用
* **`ps` の失敗を検知して報告するだけに留める（掃除は諦める）** — Issue の提案1のみを実施する案。サンドボックス下では掃除が永久に機能しないままとなり、毎回手動 kill が必要になる。報告だけでも事故の調査コストは大きく下がるが、`.lock` から保持者を特定する手段が実在する以上、掃除まで機能させる方が妥当と判断し不採用

## 決定結果

### 決定にあたり考慮したメリット

* サンドボックス下でも実害の中心（ビルドロックを握ったままの残骸プロセス）を掃除できるようになった
* 「出力ゼロのまま止まる」状態が、実行前の1行の警告で「ロック待ち」と判別できるようになった。ハングとの切り分けに時間を使わずに済む
* 掃除が機能しなかった場合に必ず stderr へ出るため、以前のように黙ってスキップされることが無くなった
* `ps` が使える環境（通常のターミナル、CI）では従来どおり全体スキャンが働く。掃除の網羅性は落ちていない

### 決定にあたり考慮したデメリット

* 掃除の経路が2系統になり、`.build/.lock` の書式（PIDをテキストで保持する）と `flock(2)` を使うという SwiftPM の実装詳細に依存する。SwiftPM 側が排他方式を変えた場合、この経路は静かに機能しなくなる（ただし `ps` 経路は残るため、サンドボックス外では従来どおり動く）
* `python3` への依存が増える。既に `make check-previews` が `scripts/check-prefire-previews.py` を使っているため新規の依存ではないが、`python3` が無い環境ではロック経由の掃除がスキップされる（その旨を stderr に出す）
* 実行前チェックとコマンド実行の間にロックが握られた場合は通知できない。実行中も監視する案（ウォッチドッグ）は、コマンドをバックグラウンド実行に変える必要があり stdin の扱いが変わるため採用していない

## 参考

* `scripts/swiftpm-build-lock.py`、`scripts/kill-stale-swift-processes.sh`、`scripts/with-local-package-lock.sh`
* `.claude/skills/swift-code-verification/SKILL.md`
* [Claude Code サンドボックス設定リファレンス](https://docs.claude.com/en/docs/claude-code/settings-reference#sandbox-settings)
