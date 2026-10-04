---
name: release-snapshot-review
description: リリースPR（release/* → main）で、前回リリースのVRT参照スナップショットと現在のスナップショットの差分を確認し、意図しない見た目の変化がないかを判定する。GitHub Actionsの Release Snapshot Diff ワークフローが作るreg-cliのレポート（artifact）を取得し、変化した画像を前後で並べて目視し、その変化をもたらしたPRまで遡って意図どおりかを切り分ける。「リリースPRのスナップショットを確認して」「前バージョンと比べて意図しない差分がないか見て」「リリース前のVRT差分チェック」「reg-cliの結果を見て」と言われたとき、またはリリースPRの「前バージョンとのスナップショットの比較で意図しない差分がないこと」のチェック項目を消化するときに必ず使う。個別の機能PRのVRT差分（Dangerのコメント）の確認には使わない。
argument-hint: "[PR番号]"
---

# リリースPRのスナップショット差分レビュー

リリースPRには、前回リリースからの全PRの見た目の変化がまとめて乗る。個々のPRではVRT差分をレビュー済みでも、
**複数PRの組み合わせ・共通コンポーネント経由の波及・PRの目的外の副作用**はリリース単位でしか見えない。
このスキルは、その「目的外の変化」を拾い出すためのもの。

比較そのものはCI（`.github/workflows/release-snapshot-diff.yml`）がreg-cliで済ませているので、ここでは
**結果を取ってきて、変化ごとに「どのPRの何という意図で変わったか」を説明できるか**を確かめる。
説明できない変化が、意図しない差分の候補になる。

## 1. 対象のPRとレポートを特定する

`$ARGUMENTS` にPR番号があればそれを、無ければ `release/` で始まるオープンなPRを使う。

```bash
gh pr list --base main --state open --json number,headRefName,headRefOid \
  --jq '.[] | select(.headRefName | startswith("release/"))'
```

> `gh` がサンドボックス内で `x509: OSStatus -26276`（TLS検証エラー）で落ちる場合は、
> サンドボックスの制約なので `dangerouslyDisableSandbox: true` で再実行する。

レポートを作った実行を探し、artifactをスクラッチパッドへ落とす。

```bash
gh run list --workflow release-snapshot-diff.yml --branch <release/vX.Y.Z> \
  --json databaseId,headSha,status,conclusion,createdAt --limit 5
gh run download <databaseId> --dir <scratchpad>/snapshot-diff
```

- 最新実行の `headSha` がPRの `headRefOid` と一致しているか確認する。ずれていれば、最新のpushの比較が
  まだ終わっていない（実行中・失敗）か、そもそも走っていない。前者なら待つか失敗ログを見る。
  後者ならユーザーに伝えて `gh workflow run release-snapshot-diff.yml --ref <ブランチ> -f release_branch=<ブランチ>` での再実行を提案する
- artifactは `report/index.html`・`report/reg.json`・`expected/`（前回リリース）・`actual/`（現在）・`diff/` の構成。
  **差分のなかった画像は容量削減のため入っていない**（件数は `reg.json` の `passedCount`）

## 2. 差分を一覧にする

```bash
R=<scratchpad>/snapshot-diff/<artifact名>/report/reg.json
jq '{baseTag, headSha, changed: (.failedItems|length), new: (.newItems|length), deleted: (.deletedItems|length), passed: .passedCount}' "$R"
# 1プレビューは端末(iPhone 16 / SE) × 外観(ライト/ダーク)の4枚に分かれるので、プレビュー名でまとめる
jq -r '.failedItems[] | sub("-iPhone-.*$"; "")' "$R" | sort | uniq -c
```

- **変更（failedItems）**: 本命。全プレビューを見る
- **削除（deletedItems）**: 同じプレビュー名で末尾だけ違うものが追加側にあれば改名。対応する追加が無い削除は、
  そのPreviewを消した理由（Viewごと削除・統合など）をPRで確かめる
- **追加（newItems）**: 前バージョンに比較対象が無いので「意図しない差分」の判定対象外。ただし改名の相手探しには使う

## 3. 変化をもたらしたPRを特定する

前回タグ以降の差分PRの一覧はリリースPRの本文にある。加えて、プレビューごとに参照画像を最後に変えたコミットを遡る。

```bash
git fetch origin --tags
S=hometeSnapshotTests/__Snapshots__/PreviewTests.generated
git log --format='%h %s' <baseTag>..origin/<release/vX.Y.Z> -- "$S/<プレビュー名>-iPhone-16.1.png"
```

参照画像の更新はXcode Cloudのbotの `chore: VRT参照スナップショットを自動更新 [ci skip]` コミットとして積まれるため、
コミットメッセージからは意図が分からない。そのコミットを最初に取り込んだマージコミットからPRを特定する。

```bash
# 祖先関係にあるマージのうち最も古いもの（= 最初に取り込んだPR）
git log --merges --ancestry-path --format='%s' <コミット>..origin/<release/vX.Y.Z> | grep -o 'pull request #[0-9]*' | tail -1
```

PRの意図は `gh pr view <番号> --json title,body` と、そのPRで変わったSwiftのソース（`git diff --stat <マージ>^1 <マージ> -- LocalPackage/Sources`）で掴む。
同じPRで多数のプレビューが変わっていれば、まとめて「何が変わるはずだったか」を先に把握してから画像を見ると速い。

## 4. 画像を並べて目視する

reg-cliのdiff画像は変化箇所の赤塗りなので、**前後の見た目の比較には向かない**。前（左）・後（右）を並べた画像を作って見る。
同梱スクリプトは差分ピクセルの外接矩形も出すので、どこが変わったかの当たりが付く。

```bash
swiftc -O .claude/skills/release-snapshot-review/scripts/side_by_side.swift -o <scratchpad>/side_by_side
A=<scratchpad>/snapshot-diff/<artifact名>
mkdir -p <scratchpad>/sbs
jq -r '.failedItems[]' "$A/report/reg.json" | grep -- '-iPhone-16\.1\.png$' | while IFS= read -r f; do
  echo "$f: $(<scratchpad>/side_by_side "$A/expected/$f" "$A/actual/$f" "<scratchpad>/sbs/${f%.png}.png")"
done
```

出力は `diff px=<変化したピクセル数> bbox x<左>-<右> y<上>-<下>`（同じサイズのとき）か、`size <前> -> <後>`（サイズが変わったとき）。

- まず **iPhone 16 ライト**の1枚をプレビューごとに Read で見る。4バリエーション全部を見ると読む画像が4倍になる割に、
  ほとんどは同じ変化なので得るものが少ない
- 次の場合はダーク・SEも同じスクリプトで並べて見る
  - 色・背景・透過に関わる変化（ダークでだけ崩れることがある）
  - 画面全体のレイアウトやセーフエリアに関わる変化（画面サイズで挙動が変わることがある）
  - バリエーション間で bbox や px の傾向が明らかに違うもの
- 同じPRで同じ種類の変化が並ぶ場合（全行にボタンが増えた等）は、代表数枚を見て残りはbboxの位置・大きさが揃っているかで判断してよい

## 5. 意図どおりか判定する

変化ごとに「どのPRの、どの意図による変化か」を一文で言えるかを確かめる。言えれば意図どおり、言えなければ要確認。

要確認になりやすいのは次のような変化。

- **PRの目的と関係ない場所の変化**: 例えば「一覧の終端の余白」を直すPRで、画面上部の要素の位置まで動いている
- **変更していないはずの画面の変化**: 共通コンポーネント・修飾子・セーフエリアの扱いの変更が波及している
- **周辺の画面と揃わなくなった変化**: 同じナビゲーション構造の他画面と比べて余白・位置だけが違う
- **崩れ**: 文字の切れ・はみ出し・重なり・要素の欠落、ダークモードでの低コントラスト
- **プレビューの作りの問題**: 日付依存で表示が変わった（`.claude/rules/prefire-preview.md` の5）、ダミーデータの変化だけ

要確認のものは、原因になったと思われるコミットのソース差分まで読み、**なぜそう見えるのか**の仮説を添える。
スナップショット撮影環境だけの描画の癖（ナビゲーションバーやセーフエリアの扱い）の可能性もあるので、断定せず
実機・シミュレータでの確認ポイントを具体的に書く（必要なら `simulator-e2e-check` スキルで確かめる）。

## 6. 報告する

結論を先に、要確認 → 細かい気付き → 意図どおり、の順で書く。

```markdown
v1.0.1 → release/v1.1.0（<headSha先頭8桁>）: 変更 N枚（Mプレビュー）・追加 N枚・削除 N枚

### 要確認
- **<プレビュー名>**: 何がどう変わったか。原因と思われるPR/コミット、なぜ意図外と考えたか、確認してほしいこと

### 意図どおり
| 変化 | プレビュー | PR |
|---|---|---|
```

- 見ていないもの（ダーク・SEを代表しか見ていない、追加分は見ていない等）は、見ていないと書く
- PR本文の「前バージョンとのスナップショットの比較で意図しない差分がないこと」のチェックは、
  **ユーザーに頼まれない限り付けない**。要確認が残っている場合は付けずにおき、その旨を伝える
