---
name: issue-create
description: GitHub Issueを作成するスキル。機能追加・修正の要件を整理してGitHub Issueとして起票する。pdmエージェントから起票が決定された際に使用。
---

# GitHub Issue作成

機能追加・修正の要件を整理し、GitHub Issueとして起票するスキル。

## Issueテンプレート

プロジェクトには以下のIssueテンプレートが定義されています：

- `.github/ISSUE_TEMPLATE/feature_request.yml` - 機能リクエスト
- `.github/ISSUE_TEMPLATE/bug_report.yml` - バグ報告
- `.github/ISSUE_TEMPLATE/mentenance_request.yml` - メンテナンスリクエスト

**重要:** Issue作成前に、必ず対応するテンプレートファイルを読み取り、フィールド構造を確認してください。

## ワークフロー

### 1. テンプレートの選択と確認

要件に基づいて適切なテンプレートを選択し、内容を確認：

```bash
# 機能リクエストテンプレートの確認例
cat .github/ISSUE_TEMPLATE/feature_request.yml
```

**テンプレートの選択基準:**
- **feature_request.yml**: 新機能追加、既存機能の改善
- **bug_report.yml**: バグ修正
- **mentenance_request.yml**: リファクタリング、技術的負債解消

### 2. テンプレートに準拠したIssue本文の作成

選択したテンプレートのフィールド構造に従って、Issue本文を作成します。

**基本フォーマット:**
```markdown
### [フィールド名1]
[内容1]

### [フィールド名2]
[内容2]

...
```

各テンプレートの必須フィールド（`required: true`）は必ず記入してください。

### 3. Issueの作成

`gh issue create`コマンドでIssueを作成：

```bash
gh issue create \
  --title "タイトル" \
  --label "ラベル" \
  --body "$(cat <<'EOF'
[テンプレートに準拠した本文]
EOF
)"
```

**タイトルのガイドライン:**
- 簡潔に（50文字以内推奨）
- プレフィックスを付ける
  - `Feature:` - 新機能
  - `Enhancement:` - 既存機能の改善
  - `Bug:` - バグ修正
  - `Refactor:` - リファクタリング

### 4. ラベルの設定

**基本ラベル（テンプレートのデフォルト）:**
- `enhancement` - 機能リクエスト
- `bug` - バグ報告
- `mentenance` - メンテナンスリクエスト

**追加ラベル:**
- **対象領域**: `UI`, `backend`, `test`
- **優先度**: `P0`（高）, `P1`（中）, `P2`（低）

**複数ラベルの指定:**
```bash
--label "enhancement,UI,P1"
```

### 5. GitHub Projectへの追加

Issue作成後、必ずGitHub Project（stotic-dev/projects/2）にTodoとして追加する：

```bash
# 1. IssueをProjectに追加
gh project item-add 2 --owner stotic-dev --url https://github.com/stotic-dev/homete_iOS/issues/XX

# 2. 追加されたアイテムのIDを取得
ITEM_ID=$(gh project item-list 2 --owner stotic-dev --format json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for item in data.get('items', []):
    if item.get('content', {}).get('number') == XX:
        print(item['id'])
        break
")

# 3. ProjectのIDを取得
PROJECT_ID=$(gh project list --owner stotic-dev --format json | python3 -c "
import json, sys
[print(p['id']) for p in json.load(sys.stdin)['projects'] if p['number']==2]
")

# 4. ステータスをTodoに設定
gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" \
  --field-id "PVTSSF_lAHOBvNiZc4A3Tsrzgsd3-I" \
  --single-select-option-id "f75ad846"
```

**Project フィールドID参照:**
- Status field: `PVTSSF_lAHOBvNiZc4A3Tsrzgsd3-I`
  - Todo: `f75ad846`
  - In Progress: `47fc9ee4`
  - Done: `98236657`
- Priority field: `PVTSSF_lAHOBvNiZc4A3Tsrzgsd4Io`
  - P0: `dd8406d5`
  - P1: `9214bf1b`
  - P2: `29f5b4c6`
- Size field: `PVTSSF_lAHOBvNiZc4A3Tsrzgsd4Is`
  - XS: `17bc645d`, S: `e9152bb0`, M: `1df61cad`, L: `6cec2fd3`, XL: `ae9ee069`

### 6. オプション設定

必要に応じて以下のオプションを使用：

```bash
--assignee @username       # 担当者の設定
--milestone "マイルストーン名"  # マイルストーンの設定
```

### 7. ユーザーへの報告

Issue作成後、以下の情報をユーザーに報告：

```
Issue #XXを作成しました！

タイトル: [タイトル]
URL: https://github.com/stotic-dev/homete_iOS/issues/XX
ラベル: [ラベル一覧]
Project: Todo として追加済み

このIssueの実装を開始する場合は、/issue-start XX コマンドを実行してください。
```

## 使用タイミング

### このスキルを使用する場合

- pdmエージェントが機能要求をレビューし、実装が妥当と判断した後
- ユーザーが明示的に「Issueを作成して」と依頼した時
- 機能要件が十分に具体化された時

### このスキルを使用しない場合

- 要件が曖昧で、さらなるヒアリングが必要な場合
- pdmエージェントによるビジネス価値の評価が完了していない場合
- Issue作成が不要な軽微なタスク（タイポ修正など）

## 注意事項

1. **テンプレートを必ず確認**
   - Issue作成前にテンプレートファイルを読み取る
   - フィールド構造と必須項目を把握する
   - テンプレートが更新されている可能性を考慮

2. **適切なラベル付け**
   - テンプレートのデフォルトラベルを使用
   - 優先度ラベルも可能な限り設定

3. **実装タスクの明確化**
   - チェックボックス形式でタスクリストを記載
   - 各タスクは具体的かつ実行可能な単位に

4. **コマンドの実行確認**
   - `gh issue create`コマンドの実行結果を確認
   - エラーが発生した場合は適切に対処

## リファレンス

- `.github/ISSUE_TEMPLATE/` - Issueテンプレートディレクトリ
- `.claude/agents/pdm.md` - Issue起票の観点と判断基準
- `CLAUDE.md` - プロジェクト概要とワークフロー
