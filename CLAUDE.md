# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

hometeは同居人（ルームメイト/家族）間で家事を管理するためのiOSアプリです。ユーザーは共有の家事リストを作成し、タスクを完了としてマークし、他のユーザーがタスクを完了した際にプッシュ通知を受け取ることができます。

**技術スタック:**
- iOS: SwiftUI + Swift 6（strict concurrency有効）
- バックエンド: Firebase（Firestore、Auth、Cloud Messaging、Functions）
- CI/CD: GitHub Actions + Fastlane

## よく使うコマンド

### iOS開発

```bash
# Xcodeでプロジェクトを開く
open homete.xcodeproj

# テスト実行（ユニット + スナップショット）
xcodebuild test -project homete.xcodeproj -scheme homete -testPlan CI.xctestplan -destination 'platform=iOS Simulator,name=iPhone 16'

# スナップショットテストのみ実行
xcodebuild test -project homete.xcodeproj -scheme homete -testPlan snapshotTesting.xctestplan -destination 'platform=iOS Simulator,name=iPhone 16'

# SwiftLint（CIでDanger経由で実行、スタンドアロンでは実行しない）
swift run --package-path ProjectTools swiftlint lint --config .swiftlint.yml

# ProjectToolsのセットアップ（Danger、SwiftLint）
make setup-project
# または: swift build --package-path ProjectTools --scratch-path ProjectTools/.build
```

### Firebase Functions

```bash
# Firebase Functionsのlint実行
make lint
# または: cd firebase/functions && npm run lint -- --fix

# TypeScriptのビルド
cd firebase/functions && npm run build

# ローカルでエミュレーターを起動
make emulator
# または: cd firebase/functions && npm run serve

# Functionsをデプロイ
make deploy
# または: cd firebase/functions && npm run deploy

# E2Eテスト実行
make test-e2e
# または: cd firebase/functions && npm run test:e2e
```

### Fastlane

```bash
# TestFlightへアップロード（証明書が必要）
bundle exec fastlane upload_testFlight

# App Storeへリリース
bundle exec fastlane release

# 開発用プロビジョニングプロファイルをインストール
bundle exec fastlane install_dev_profile

# 本番用プロビジョニングプロファイルをインストール
bundle exec fastlane install_prod_profile
```

## アーキテクチャ

### iOSアプリの構造

**パターン**: カスタムDependency Injectionを用いたクリーンアーキテクチャ

```
Views（SwiftUI）
  ↓ 使用
Stores（@Observableな状態管理クラス）
  ↓ 使用
Clients（プロトコルベースのDI層）
  ↓ 実装
Services（Firestore、SignInWithApple、P2P、NotificationCenter）
  ↓ 操作
Domain Models（Codable構造体）
```

**主要ディレクトリ:**
- `homete/Views/` - 機能別に整理されたSwiftUIビュー（Auth、HomeView、HouseworkBoardViewなど）
- `homete/Model/Domain/` - ビジネスロジックモデル（Account、Housework、Cohabitant）
- `homete/Model/Dependencies/` - Dependency Injection用のクライアントプロトコル
- `homete/Model/Store/` - Observableな状態管理クラス（@Observableクラス）
- `homete/Model/Service/` - インフラ層の実装（Firestore、SignInWithApple、P2P）

**エントリーポイント:**
- `homete/Views/HometeApp.swift` - アプリのエントリーポイント、Firebaseの初期化
- `homete/Views/RootView/RootView.swift` - 起動状態マシン（launching → login → logged in）
- `homete/Model/AppDependencies.swift` - Dependency Injectionコンテナ

### Dependency Injectionパターン

サードパーティフレームワークを使わないカスタムDIシステム:

1. 全てのクライアントは`DependencyClient`プロトコルに準拠し、`.liveValue`（本番）と`.previewValue`（モック）を持つ
2. `AppDependencies`構造体が全てのクライアントを保持し、SwiftUIのEnvironment経由で注入される
3. `DependenciesInjectLayer`ビューラッパーがアプリのルートで依存関係を注入
4. Storeは初期化時に`AppDependencies`を受け取る

**例（フロー）:**
```swift
View → Store（AppDependenciesを受け取る）
     → Client.liveValue（プロトコル実装）
     → FirestoreService（シングルトンactor）
     → Firebase SDK
```

### Firebase連携

**Firestoreサービス** (`homete/Model/Service/Firestore/FirestoreService.swift`):
- スレッドセーフのためにactorベース
- 汎用CRUD: `fetch()`, `insertOrUpdate()`, `delete()`
- `AsyncStream`を使ったリアルタイムリスナー
- コレクションパスは`CollectionPath.swift`で定義

**Cloud Functions** (`firebase/functions/src/`):
- `notifyothercohabitants` - 同居人グループメンバーにプッシュ通知を送信（v2 callable）
- `deleteuserdata` - アカウント削除時のユーザーデータクリーンアップ（v1 authトリガー）

**認証:**
- `homete/Model/Service/SignInWithApple/`経由でSign in with Apple
- `AccountAuthClient`がFirebase Auth操作をラップ

### 状態管理

**モダンなSwift Concurrency:**
- `@Observable`マクロを使用（CombineやObservableObjectではない）
- Swift 6のstrict concurrencyでアクター分離と`@Sendable`
- 全体的にasync/await、completion handlerは使わない

**起動状態マシン** （RootViewの`LaunchState` enum）:
```
launching → notLoggedIn → Sign In with Apple
         ↓
         preLoggedIn(auth) → 登録画面
         ↓
         loggedIn(context) → メインアプリ（AppTabView）
```

### テスト戦略

**ユニットテスト** (`hometeTests/`):
- テストプラン: `CI.xctestplan`
- ロケール: 日本語（ja/JP）、タイムゾーン: 東京
- プラットフォーム: iOSシミュレーター（iPhone 16、iOS 18.6）

**スナップショットテスト** (`hometeSnapshotTests/`):
- ライブラリ: PointFreeのswift-snapshot-testing 1.18.7
- テストプラン: `snapshotTesting.xctestplan`
- Prefire連携（`.prefire.yml`）でプレビュースナップショット
- CI上で失敗時は`Build/VRT/SnapshotsFailures`にアップロード

**Firebase Functions E2Eテスト** (`firebase/functions/test/`):
- フレームワーク: Jest + ts-jest
- Firebase Emulators（Auth、Firestore、Functions）に対して実行
- コマンド: `npm run test:e2e`または`make test-e2e`

## CI/CDパイプライン

**GitHub Actionsワークフロー:**

1. **`ci.yml`** - 全てのpush/PRで実行
   - ユニット + スナップショットテストを実行
   - Danger実行（SwiftLint、カバレッジレポート）
   - `main`ブランチでTestFlightデプロイをトリガー

2. **`cd_testFlight.yml`** - TestFlightデプロイ
   - `main`ブランチでビルド成功後に`ci.yml`からトリガー
   - ビルド番号を`${{ github.run_number }}`にインクリメント
   - Fastlane Matchでコード署名
   - IPAをApp Store Connectにアップロード

3. **`cd_release.yml`** - 本番リリース
   - `release/*`ブランチへのpushでトリガー
   - gitタグ`v{app_version}`を作成

4. **`functions-e2e-test.yml`** - Firebase Functionsテスト
   - `firebase/dev/functions/**`への変更でトリガー
   - ESLintとE2Eテストを実行
   - Node.js 21とJava 21を使用

**コード署名:**
- Fastlane Matchを使用（証明書はプライベートGitリポジトリに保存）
- ASC APIキー認証（Apple ID/パスワード不要）
- 開発用バンドルID: `taichi.satou.hometekure.dev`
- 本番用バンドルID: `taichi.satou.hometekure`

## 重要事項

### SwiftLint設定

- `.swiftlint.yml`で設定
- `force_unwrapping`、`multiline_arguments`、`trailing_closure`などのopt-inルールを有効化
- `identifier_name`、`statement_position`などのルールを無効化
- `homete/`と`hometeTests/`ディレクトリのみをlint（ProjectToolsは除外）

### Xcode 26対応

Fastlaneのアップロードで`--use-old-altool`を使用。Xcode 26の新しいaltoolはエラー発生時にハングしてエラーを報告しないバグがあるため。`fastlane/Fastfile:25`参照。

### Firebase設定

- 開発環境設定: CIでGitHub secretsからデコード（`FIREBASE_CONFIG_DEV_BASE64`）
- 本番環境設定: GitHub secretsからデコード（`FIREBASE_CONFIG_PROD_BASE64`）
- 設定ファイルはリポジトリにコミットしない（`.gitignore`に含まれる）

### ドメインモデル

コアエンティティは家事管理システムを表現:
- **Account**: FCMトークンとcohabitantId参照を持つユーザープロファイル
- **Cohabitant**: 一緒に住んでいるユーザーのグループ（Account IDの配列としてmembers）
- **HouseworkItem**: 状態、担当者、完了ステータスを持つ個別の家事/タスク
- **HouseworkBoardList**: 日付で整理された家事のコレクション
- **DailyHouseworkList**: 特定の日の家事アイテム

### カスタムビルドツール（ProjectTools）

開発ツールを含むSwift Package:
- **SwiftLint 0.59.1**: コードスタイル強制
- **Danger Swift 3.22.0**: PR自動化
- **danger-swift-coverage**: コードカバレッジレポート

**Dangerfile** (`ProjectTools/Dangerfile.swift`):
- PRの変更が500行を超えると警告
- `homete/`の変更ファイルでSwiftLintを実行
- `Build/test.xcresult`からコードカバレッジをレポート

ビルド: `swift build --package-path ProjectTools --scratch-path ProjectTools/.build`

<<<<<<< Updated upstream
=======
## エージェント

プロジェクトでは特定のタスクに特化したエージェントを活用します。

### pdm

プロダクトマネージャーエージェント。機能追加・修正のビジネス観点からのレビューとGitHub Issue起票を担当します。

**使用タイミング:**
- ユーザーが機能要望を出した際にプロアクティブに使用
- ユーザーが明示的に「〇〇の機能を追加するからIssueを使って」と指示した際

**重要:** ユーザーが機能要望を出した場合は、このエージェントを使用してビジネス観点からレビューし、適切なIssueを起票してください。

### ios-code-reviewer

Swiftコードの実装完了後に使用する専用のコードレビューエージェントです。

**使用タイミング:**
- 新しい機能の実装完了後（View、Store、Client、Service、Domainモデルなど）
- 既存コードのリファクタリング完了後
- バグ修正完了後
- テストコード作成・更新後

**重要:** Swiftコードのレビューが必要な場合は、このエージェントに任せてください。

**注意:** pdmエージェントとは独立して実行します。pdmはビジネス観点、ios-code-reviewerは技術観点のレビューを担当します。

>>>>>>> Stashed changes
## ファイル整理の規約

新機能を追加する際:

1. **Views**: `homete/Views/`の適切な機能フォルダに追加（例: `HomeView/`、`SettingView/`）
2. **ドメインモデル**: ドメイン領域別に`homete/Model/Domain/`のサブフォルダに追加
3. **Clients**: `homete/Model/Dependencies/`でプロトコル定義、`.liveValue`と`.previewValue`を実装
4. **Services**: `homete/Model/Service/`のサブフォルダにインフラコードを追加
5. **Stores**: `homete/Model/Store/`にObservable状態管理クラスを追加
6. **Tests**: `hometeTests/`でメインアプリの構造をミラー

常にDependency Injectionパターンを使用 - ViewからServiceに直接アクセスしない。

## 主要な依存関係

**iOS（SPM）:**
- Firebase iOS SDK 12.0.0（Auth、Firestore、Messaging、Analytics）
- swift-snapshot-testing 1.18.7
- Prefire 5.3.0
- swift-custom-dump 1.3.3

**Firebase Functions（npm）:**
- firebase-admin 12.6.0
- firebase-functions 6.0.1
- typescript 5.7.3
- jest 30.2.0 + ts-jest 29.4.6

**ビルドツール:**
- Fastlane（Bundler/Gemfile経由）
- Node.js 22（Firebase Functions用）
