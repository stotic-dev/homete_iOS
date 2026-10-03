---
name: pr-create
description: 現在のブランチの変更内容を確認し、GitHub CLIを使ってPR作成を支援してください。
---

# PR作成

現在のブランチの変更内容を確認し、`.github/PULL_REQUEST_TEMPLATE.md`に準拠したフォーマットでPRを作成するスキル。

## PRテンプレート

PRの本文は `.github/PULL_REQUEST_TEMPLATE.md` のフォーマットに従うこと。

**重要:** PR作成前に、必ず `.github/PULL_REQUEST_TEMPLATE.md` を読み取り、最新のフィールド構造を確認してください。テンプレートが更新されている可能性があります。

## ワークフロー

### 1. マージ先ブランチの決定

ユーザーには確認せず、以下の優先順で決める。ベースの確認は毎回同じ答え（ほぼmain）になるやり取りで、PR作成を止めるだけなので省く。

1. **開発者の指示があればそれに従う**（「release/1.2に向けて」「#350の上に積んで」など）。指示はスタック判定より常に優先する
2. **スタックPRなら親ブランチ**。現在のブランチが、まだマージされていない別のPRのブランチから切られている場合は、そのブランチをベースにする。mainに向けると親PRのコミットまで差分に混ざり、レビューできなくなるため
3. **それ以外はmain**

スタックかどうかは、オープン中のPRのheadブランチのうち、現在のブランチの祖先になっているものがあるかで判定する：

```bash
git fetch origin --prune
current=$(git branch --show-current)

# オープン中PRのheadブランチのうち、HEADの祖先で、かつmainにまだ入っていないものを候補にする
for b in $(gh pr list --state open --json headRefName --jq '.[].headRefName'); do
  [ "$b" = "$current" ] && continue
  git rev-parse --verify -q "origin/$b" >/dev/null || continue
  git merge-base --is-ancestor "origin/$b" HEAD || continue
  git merge-base --is-ancestor "origin/$b" origin/main && continue
  echo "$(git rev-list --count "origin/$b"..HEAD) $b"
done | sort -n | head -1
```

- 出力が空ならスタックではないので `main`
- 出力があれば、HEADまでのコミット数が最も少ない（＝直近の親）ブランチをベースにする。孫ブランチ（A → B → C）でCのPRを作る場合、AではなくBが選ばれる
- 親PRがsquash mergeされた後は、親ブランチがオープンPRから外れるので自動的に `main` になる

決めたベースは、PR作成後の報告でスタック判定の根拠（親PRの番号など）と合わせて伝える。開発者が違うベースを意図していた場合に気づけるようにするため。

### 2. 現在のブランチの状態を確認

以下のコマンドを並列で実行し、マージ先ブランチとの差分を把握する：

```bash
# 未コミットの変更を確認
git status

# マージ先ブランチとの差分を確認
git diff <マージ先ブランチ>...HEAD

# マージ先ブランチからの全コミット履歴を確認
git log --oneline <マージ先ブランチ>..HEAD

# リモートとの同期状態を確認
git branch -vv
```

### 3. 関連Issueの確認

オープン中のIssueを確認し、このPRに関連するIssueがないか調べる：

```bash
gh issue list --state open
```

関連Issueがあれば、PR本文の経緯セクションに `#XX` でリンクする。

### 4. テンプレートの確認とPR本文の作成

`.github/PULL_REQUEST_TEMPLATE.md` を読み取り、そのフォーマットに従ってPR本文を作成する。

**各セクションの記載ガイドライン:**

- **経緯**: なぜこのPRが必要になったか。関連Issueがあれば `#XX` でリンクする
- **実装内容**: 「何をしたか」だけでなく「なぜその実装を選んだか」の理由を重視して記載する
- **確認内容**: 修正が正しく動作することの確認方法をチェックボックス形式で記載する

### 5. PRの作成

未pushの場合はpushした上で、`gh pr create`コマンドでPRを作成する：

```bash
gh pr create \
  --base <マージ先ブランチ> \
  --head <現在のブランチ> \
  --title "タイトル" \
  --body "$(cat <<'EOF'
[テンプレートに準拠した本文]
EOF
)"
```

### 6. ユーザーへの報告

PR作成後、URLとベースブランチ（スタックの場合は親PR）を報告する。

## 注意事項

1. **マージ先ブランチは確認せず決める** - 開発者の指示 > スタックの親ブランチ > main の順
2. **差分はマージ先ブランチとの比較で確認する** - `<マージ先>...HEAD` を使う
3. **関連Issueを確認する** - オープン中のIssueと照合する
4. **全コミットを確認** - 最新コミットだけでなく、マージ先からの全コミットを分析する
5. **理由を重視** - 実装内容セクションでは「何をしたか」より「なぜそうしたか」を重視する
6. **テンプレート準拠** - 独自フォーマットではなく、必ずテンプレートのセクション構造に従う
