---
paths:
  - ".claude/**"
  - "CLAUDE.md"
  - ".worktreeinclude"
---

# Claude Code設定の更新ルール

Claude Code の設定（`settings.json` / `settings.local.json` / `.claude/rules/` / `.claude/skills/` / `.claude/agents/` / `.claude/commands/` / `CLAUDE.md`）を更新・追加する前に、必ず `improve-setting` スキルを参照すること。

変更対象ごとにロードすべきデフォルトスキル（`update-config`、`example-skills:skill-creator`、`keybindings-help` など）と、マージ編集 → `jq` 検証 → 反映タイミングの伝達までの手順は当該スキルに集約されている。

## このリポジトリ固有の事情

### settings.local.json は worktree に引き継がれる

`.worktreeinclude` に `.claude/settings.local.json` が登録されているため、gitignore 対象でありながら `wt step copy-ignored` で新規 worktree にコピーされる。

つまり `settings.local.json` に入れた設定は**このリポジトリの全 worktree に伝播する**。マシン固有の絶対パスを含む許可ルールを足すときは、worktree 側（`../<branch-name>` 階層）でも成立するかを考えること。逆に、worktree でも効かせたい個人設定はここに置けばよい。

### 書き分け

- 個人用の `allow` 許可ルール → `.claude/settings.local.json`
- チーム全員に効かせたい `deny`（秘匿ファイルの読み書き禁止など） → `.claude/settings.json`（コミット対象）

`.claude/settings.json` には `Secret*.xcconfig`・`GoogleService-Info*.plist`・`private_keys/` などの deny が既にある。deny は allow より優先されるため、これらに一致する allow を足しても効かない。

### ルール追加時の `paths:` は必須

`.claude/rules/` に追加するファイルには必ず `paths:` frontmatter を付ける（詳細は CLAUDE.md「ルール（.claude/rules/）の運用」）。Swift実装に関するルールに `firebase/functions/**` を含めるような、対象の広げすぎをしない。

### ADR の対象になる場合がある

プラグイン導入・MCPサーバ追加・フックによるワークフロー自動化など、開発フローの技術選定に相当する設定変更を行った場合は `.claude/rules/adr.md` に従って `doc/adr/` に ADR を残す。単なる許可ルールの追加は対象外。
