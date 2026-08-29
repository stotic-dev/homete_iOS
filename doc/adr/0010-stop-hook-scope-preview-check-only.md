## タイトル: Stopフックの検証範囲を#Previewの静的検査だけに絞る

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-08-22
* 技術的背景: [ADR-0006](0006-claude-code-autonomous-execution.md) の決定事項のうち「Stop フックで `make test-packages` を実行する」を変更する

## 文脈、背景や問題点の説明

ADR-0006 で Stop フックに `make test-packages`（SwiftPMビルド + SwiftLintプラグイン + ユニットテスト）を置いたが、運用してみると2つの問題が出た。

1つ目は**手動実行との衝突**。フックの `make test-packages` と Claude が手順に従って流す `make test-packages` が同じ worktree で同時に走ると、`Makefile` 冒頭の stale プロセス掃除（`pkill -f "$(CURDIR)/LocalPackage/.build"`）が、もう一方の make のレシピシェル（argv にそのパターン文字列を含む）にマッチして相手を殺す。殺された側は `Terminated: 15` で失敗し、残った SwiftPM の `.build` ロックで後続の実行が数分〜無限に待たされる。

2つ目は**ターン終了の遅さ**。テストは5ターゲットあり、フックの分だけ毎ターンの終了が数分伸びる。ADR-0006 でもデメリットとして挙げていたが、実運用では想定以上に体感が悪かった。

一方で `make check-previews` が検出する `#Preview` のアクセス修飾子ミスは、**ローカルのビルドでは絶対に落ちず Xcode Cloud の VRT ワークフローまで気付けない**。ここだけは Claude の手順に任せると取りこぼしのコストが高い。

## 決定事項

* **Stop フック（`scripts/claude-verify-swift.sh`）が実行するのは `make check-previews` のみとする**
* ビルド・SwiftLint・ユニットテストは `.claude/skills/swift-code-verification/SKILL.md` の手順に従って Claude 自身が実行する
* フックのタイムアウトを 1200 秒から 120 秒に、`statusMessage` を実態に合わせて短縮する
* 3回連続失敗で自動検証を止めるガード、fingerprint による差分スキップは維持する

## 考慮した選択肢

* **Stop フックを丸ごと削除する** — ターン終了は最速になるが、VRT でしか落ちない `#Preview` の誤りを Xcode Cloud まで検出できなくなる。フックのコストの大半はテストであって静的検査ではないため、削除は行き過ぎと判断し不採用
* **フックはそのままで Makefile の `pkill` を並行実行に耐えるよう直す** — 衝突は解消できるが、ターン終了が数分伸びる問題は残る。`pkill` の修正自体は有用なので別途検討する
* **ロックファイルで `make test-packages` を直列化する** — 同上。衝突は防げるが、フック側が待つ分だけターン終了はさらに遅くなる
* **`make test-packages` を PostToolUse に移す** — ADR-0006 で検討済みの通り、Swift 編集のたびに全テストが走り遅すぎるため不採用

## 決定結果

### 決定にあたり考慮したメリット

* フックと手動実行の衝突（`Terminated: 15` と SwiftPM ロック待ち）が構造的に起きなくなる
* ターン終了が数分単位で短縮される（静的検査は1秒未満）
* VRT でしか落ちない `#Preview` の誤りに対する自動検出は維持される

### 決定にあたり考慮したデメリット

* ビルド・テストの実行が Claude の遵守に依存する形に戻る（ADR-0006 が harness 実行に変えた部分の一部後退）。スキル・ルールでの明示と、PR の CI（`ci_local_package.yml`）を後段の担保とする
* テストを流し忘れたまま PR を出した場合、検出が CI まで遅れる

## 参考

* [ADR-0006](0006-claude-code-autonomous-execution.md) — Stop フックを導入した経緯
* `.claude/rules/swift-code-verification.md` / `.claude/skills/swift-code-verification/SKILL.md` — Claude 自身が実行する検証手順
