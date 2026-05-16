# コードスタイル統一: SwiftFormat & SwiftLint

本プロジェクトでは Swift コードの品質を統一するために、役割の異なる 2 つのツールを併用しています。

| ツール | 役割 | 実行タイミング |
|---|---|---|
| **SwiftFormat** | コードの**自動整形**（インデント・改行・ラップなど機械的に修正可能なスタイル） | pre-commit hook / 手動 |
| **SwiftLint** | 静的解析による**品質チェック**（自動修正できない規約違反やコードスメル） | CI（Danger 経由）/ 手動 |

設定ファイルは双方ともリポジトリルートに配置しています。

- `.swiftformat` — SwiftFormat 設定
- `.swiftlint.yml` — SwiftLint 設定

両ツールの除外パス・行長などは互いに整合するよう設定してあります（`.swiftformat` の `--exclude` と `.swiftlint.yml` の `excluded` が一致、`--max-width 120` が SwiftLint の `line_length` 警告閾値と一致）。

---

## SwiftFormat

### 提供方法

SwiftFormat は `ProjectTools/Package.swift` に SwiftPM 依存として組み込まれており、SwiftPM プラグイン経由で実行します。

```swift
// ProjectTools/Package.swift
.package(url: "https://github.com/nicklockwood/swiftformat", exact: "0.61.1")
```

### 自動実行（pre-commit hook）

`scripts/git-hooks/pre-commit` がステージ済みの Swift ファイルに SwiftFormat を適用し、整形結果を自動で再ステージします。

**初回セットアップ:**

```bash
make install-hooks
# または
git config core.hooksPath scripts/git-hooks
```

`make setup-project` 内でも自動的に呼ばれます。

**動作:**

1. `git diff --cached` でステージ済み Swift ファイルを取得
2. `.swiftformat` の `--exclude` 設定で除外されているパスをスキップ
3. SwiftFormat を実行
4. 整形後のファイルを `git add` で再ステージ

### 手動実行

プロジェクト全体（`homete/` / `hometeSnapshotTests/` / `LocalPackage/` 配下）に一括で整形を適用するには:

```bash
make format
```

内部では以下を実行しています。

```bash
swift package --package-path ProjectTools plugin \
    --allow-writing-to-package-directory \
    --allow-writing-to-directory $(pwd) \
    swiftformat --config .swiftformat \
    homete hometeSnapshotTests LocalPackage
```

> `--allow-writing-to-directory` は SwiftPM プラグインのサンドボックスがパッケージ外への書き込みをブロックするため必要。

### 主要なルール（`.swiftformat`）

| 設定 | 内容 |
|---|---|
| `--swift-version 6` | Swift 6 構文を前提に整形 |
| `--max-width 120` | SwiftLint の `line_length.warning` と一致 |
| `--type-blank-lines insert` | 型宣言の `{` 直後に空行を挿入 |
| `--wrap-arguments before-first` | 複数行に分割される引数を `(` の次行から開始 |
| `--wrap-parameters before-first` | 関数呼び出しパラメータも同様 |
| `--wrap-collections before-first` | 配列/辞書リテラルも同様 |
| `--closing-paren balanced` | 閉じ `)` を独立行に配置 |

**before-first スタイルの例:**

```swift
init(
    hoge: String,
    huga: Int
)
```

**無効化しているルール（既存コードへの影響が大きいため）:**

- `organizeDeclarations` — 宣言の並び替え
- `markTypes` — `// MARK:` 自動挿入
- `acronyms` — 識別子内の頭字語の大文字化
- `wrapMultilineStatementBraces` — `{` の改行配置変更
- `blockComments` — ブロックコメントの整形

---

## SwiftLint

### 提供方法

SwiftLint は `ProjectTools/Package.swift` にバイナリターゲットとして組み込まれています。

```swift
.binaryTarget(
    name: "SwiftLintPluginBinary",
    url: "https://github.com/realm/SwiftLint/releases/download/0.59.1/SwiftLintBinary.artifactbundle.zip",
    ...
)
```

### 自動実行（CI / Danger）

PR 作成時に GitHub Actions の `ci.yml` から Danger 経由で実行されます。`ProjectTools/Dangerfile.swift` で `homete/` 配下の変更ファイルに対して SwiftLint を実行し、PR コメントとして結果を投稿します。

### 手動実行

ローカルで全体を Lint するには:

```bash
ProjectTools/.build/arm64-apple-macosx/debug/swiftlint lint --config .swiftlint.yml
```

> CI と異なり SwiftLint をスタンドアロンで呼ぶケースは限定的です（基本は Danger 経由）。

### 主要な設定（`.swiftlint.yml`）

**有効化している opt-in ルール（抜粋）:**

- `force_unwrapping` — 強制アンラップを警告
- `multiline_arguments` — 複数行引数の整形
- `trailing_closure` — トレーリングクロージャ推奨
- `convenience_type` — `static` メンバのみの型を `enum` 化

**無効化しているルール（抜粋）:**

- `trailing_comma` — SwiftFormat が複数行末尾にカンマを付与する挙動と衝突するため無効化
- `identifier_name` — 識別子名の長さ・命名規則
- `statement_position` — `else` などの位置

---

## SwiftFormat と SwiftLint の住み分け

両ツールはルールが一部重複しますが、本プロジェクトでは以下の方針で住み分けています。

- **整形できることは SwiftFormat に任せる**: インデント、改行、引数ラップ、空行など機械的に決定できるルールは SwiftFormat が pre-commit で自動修正するため、SwiftLint 側で同じ警告を出してもノイズになる
- **SwiftLint は構造的な品質に集中**: 強制アンラップ、未使用宣言、関数の複雑度など「人間の判断が必要な指摘」を担当
- **衝突するルールは SwiftLint 側を無効化**: `trailing_comma` のように両者で挙動が異なるものは、自動修正される SwiftFormat の挙動を優先

新たに SwiftFormat ルールを追加して SwiftLint と衝突するようになった場合は、`.swiftlint.yml` 側で当該ルールを `disabled_rules` に追加してください。

---

## 関連ファイル

- `.swiftformat` — SwiftFormat 設定
- `.swiftlint.yml` — SwiftLint 設定
- `ProjectTools/Package.swift` — 両ツールの依存定義
- `ProjectTools/Dangerfile.swift` — CI 上の SwiftLint 呼び出し
- `scripts/git-hooks/pre-commit` — pre-commit hook 実装
- `Makefile` — `format` / `install-hooks` ターゲット
