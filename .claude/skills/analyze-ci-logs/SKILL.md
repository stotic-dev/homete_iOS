---
name: analyze-ci-logs
description: GitHub ActionsのCIログを解析する。URLまたはrun IDを受け取り、ログを取得・解析して結果を報告する。
context: fork
agent: ci-log-analyzer
---

# GitHub Actions ログ解析

$ARGUMENTSで指定されたGitHub Actionsのログを解析してください。

## 入力の解析

以下のいずれかの形式を受け付けます：

1. **URL形式**: `https://github.com/{owner}/{repo}/actions/runs/{run_id}`
2. **run ID**: 数字のみ（リポジトリは現在のリポジトリを使用）
3. **質問形式**: 「最新のCIが失敗した原因を教えて」など

## ログ取得コマンド

### 基本コマンド

```bash
# ワークフロー実行の概要
gh run view {run_id} --repo {owner}/{repo}

# 失敗したジョブのログ
gh run view {run_id} --repo {owner}/{repo} --log-failed 2>&1 | head -500

# 全てのログ
gh run view {run_id} --repo {owner}/{repo} --log 2>&1 | head -1000

# 特定のジョブのログ
gh run view {run_id} --repo {owner}/{repo} --job {job_id} --log
```

### フィルタリング

```bash
# 特定パターンの検索（前後コンテキスト付き）
gh run view {run_id} --log-failed 2>&1 | grep -A 10 -B 5 "pattern"

# エラー関連の抽出
gh run view {run_id} --log-failed 2>&1 | grep -i "error\|failed\|failure"

# テスト結果の抽出
gh run view {run_id} --log-failed 2>&1 | grep -A 5 "Expectation failed\|XCTAssert"
```

### ワークフロー一覧

```bash
# 最近の実行一覧
gh run list --repo {owner}/{repo} --limit 10

# 失敗した実行のみ
gh run list --repo {owner}/{repo} --status failure --limit 5

# 特定ブランチの実行
gh run list --repo {owner}/{repo} --branch {branch_name}
```

## 解析の実行

1. **入力を解析**してrun IDとリポジトリを特定
2. **適切なコマンド**でログを取得
3. **ログを分析**して問題や情報を抽出
4. **必要に応じて**ソースコードや設定ファイルを確認
5. **結果を整理**してユーザーの質問に回答

## 出力形式

### エラー調査の場合

```markdown
## 問題の概要
[失敗の種類と影響範囲]

## 根本原因
[問題が発生した理由]

## 影響箇所
- ファイル: `path/to/file:行番号`
- ステップ: `step name`

## 解決策
[具体的な修正方法]
```

### 情報抽出の場合

```markdown
## 抽出結果
[求められた情報]

## 詳細
[関連するコンテキスト]
```

### ステータス確認の場合

```markdown
## ワークフロー状態
- ステータス: [成功/失敗/進行中]
- 実行時間: [時間]
- トリガー: [push/PR/schedule]

## ステップ別結果
| ステップ | 状態 | 備考 |
|---------|------|------|
| ... | ... | ... |
```

## 注意事項

- ログが長い場合は関連部分を抽出
- 複数の問題がある場合は優先度順にリストアップ
- 必要に応じてソースコードも参照して根本原因を特定
