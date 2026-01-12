---
name: code-review
description: hometeプロジェクト用のiOS Swiftコードレビュースキル。SwiftLintを実行し、警告・エラーを報告し、git diffで変更されたSwiftファイルをレビューする。/code-reviewコマンドでユーザーがコードレビューを要求した時、または機能実装、リファクタリング、バグ修正、テスト更新後に使用。DIパターン準拠、Swift 6並行性、過度なエンジニアリングの回避、テストコードの品質に焦点を当てる。
---

# コードレビュー

SwiftLintの自動チェックと包括的なコード品質分析を備えた、homete iOSプロジェクト用のSwiftコードレビュースキル。

## ワークフロー

**重要:** このスキルは実際のレビュー作業を`ios-code-reviewer`エージェントに委譲します。

### 1. ios-code-reviewerエージェントを起動

Taskツールを使用して`ios-code-reviewer`エージェントを起動し、現在のブランチのSwift差分をレビューさせます：

```
Task tool with:
- subagent_type: "ios-code-reviewer"
- description: "Swiftコードの差分をレビュー"
- prompt: "現在のブランチのSwiftコードの差分をレビューしてください"
```

### 2. レビュー結果の報告

エージェントが以下を実行します：
- SwiftLintの実行と結果報告
- git diffによる変更差分の取得
- 変更コードの詳細レビュー
- レビュー結果のサマリー出力

## エージェントが実施するレビュー

#### 主要なレビュー基準

**Dependency Injection違反** (最優先)：
- ViewはServiceに直接アクセスしてはいけない - Clientを使用すべき
- Storeは初期化時に`AppDependencies`を受け取り、`.liveValue`または`.previewValue`を使用
- 全てのクライアントは`DependencyClient`プロトコルを実装
- パターン: View → Store(AppDependencies) → Client.liveValue → Service

**過度なエンジニアリング** (最優先)：
- 一度しか使わない処理のために不要な抽象化や汎用的なソリューションを避ける
- 要求された内容以外の機能を追加しない
- 発生し得ないシナリオのエラーハンドリングを追加しない
- 単一の操作のためにヘルパー/ユーティリティを作成しない
- 類似した3行のコード > 早すぎる抽象化

**テストコードの品質** (最優先)：
- 新機能には対応するユニットテストが必要
- UIコンポーネントにはスナップショットテスト（swift-snapshot-testing使用）が必要
- テストは日本語ロケール（`ja_JP`）と東京タイムゾーンを使用
- テストファイルは`hometeTests/`でメインアプリの構造をミラー

#### 副次的なレビュー基準

**Swift 6 Strict Concurrency**：
- UI関連コードに適切な`@MainActor`アノテーション
- アクター分離の準拠
- 並行性境界を越える型の`Sendable`準拠
- async/awaitを使用、completion handlerは使用しない

**セキュリティ問題**：
- ハードコードされたシークレットや認証情報がないこと
- システム境界での適切な入力検証
- クラッシュの可能性がある強制アンラップ（! 演算子）がないこと
- OWASP Top 10の一般的な脆弱性をチェック

**アーキテクチャ準拠**：
- クリーンアーキテクチャのレイヤーに従う（Views → Stores → Clients → Services → Domain）
- ドメインモデルは`homete/Model/Domain/`に配置
- サービスは`homete/Model/Service/`に配置
- Storeは`homete/Model/Store/`に配置

**コード品質**：
- ロジックが自明でない場合のみコメントを追加
- 変更していないコードにdocstringを追加しない
- 使用されていないコードに対する後方互換性のハックを避ける
- 使用されていないコードは完全に削除、コメントアウトしない

## 使用タイミング

### このスキルを使用する場合

- ユーザーが `/code-review` コマンドを実行した時
- 機能実装、リファクタリング、バグ修正が完了した時
- ユーザーが「コードレビューをお願いします」と依頼した時

### このスキルを使用しない場合

- コード構造に関する一般的な質問（代わりに探索を使用）
- Swiftファイルに変更がない場合
- 初期のコード探索や理解フェーズ中

## 注意事項

- このスキルは**エントリーポイント**として機能します
- 実際のレビュー処理は `ios-code-reviewer` エージェントが実行します
- スキル自身でSwiftLintやgit diffを直接実行しないでください

## リファレンス

プロジェクトの詳細なアーキテクチャと規約については、以下を参照：
- `homete/CLAUDE.md` - プロジェクト概要とアーキテクチャパターン
- `.swiftlint.yml` - SwiftLint設定とルール
- `homete/Model/AppDependencies.swift` - DIコンテナ実装
