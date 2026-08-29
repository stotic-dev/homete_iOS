# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

hometeは同居人（ルームメイト/家族）間で家事を管理するためのiOSアプリです。ユーザーは共有の家事リストを作成し、タスクを完了としてマークし、他のユーザーがタスクを完了した際にプッシュ通知を受け取ることができます。

**技術スタック:**
- iOS: SwiftUI + Swift 6（strict concurrency有効）
- バックエンド: Firebase（Firestore、Auth、Cloud Messaging、Functions）
- CI/CD: GitHub Actions + Xcode Cloud + Fastlane

## よく使うコマンド

### iOS開発

```bash
# LocalPackageのユニットテスト（最も使う。xcodebuildは使わない）
make test-packages

# LocalPackageをiOSシミュレーター向けにビルド
make build-local-package

# SwiftFormatを全体にかける
make format

# VRT(Prefire)のビルドが壊れる#Previewを静的に検出
make check-previews

# SwiftLint（ビルド時にSPMプラグインとして自動実行される。単体で流す場合）
ProjectTools/.build/arm64-apple-macosx/debug/swiftlint lint

# プロジェクトのセットアップ（ProjectToolsビルド、証明書、git hooks）
make setup-project
```

`make` の各ターゲットには `--disable-sandbox` が付いている。理由は `.claude/skills/swift-code-verification/SKILL.md` を参照。

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

**マルチモジュール構成**（SPM）: 実装コードはメインターゲットではなく `LocalPackage/` に置かれている。モジュールの一覧・責務・依存関係は **[doc/multimodules_structure.md](doc/multimodules_structure.md)** が正。採用経緯は [ADR-0001](doc/adr/0001-spm-multimodule-structure.md)。

**主要ディレクトリ:**
- `LocalPackage/Sources/HometeDomain/` - ドメインモデル・Clientプロトコル・Store・UseCase（最下層、依存なし）
- `LocalPackage/Sources/Features/` - 機能別SwiftUIビュー（Auth / Home / Housework / HouseworkTemplate / Setting / Contribution）
- `LocalPackage/Sources/HometeUI/` - デザインシステム・共通コンポーネント・Viewユーティリティ
- `LocalPackage/Sources/HometeInfrastructure/` - Clientの`liveValue`実装とService（Firestore、SignInWithApple、Purchase、Advertisement）
- `LocalPackage/Sources/HometeResources/` - アセットとSwiftGen生成コード
- `LocalPackage/Sources/AppRoot/` - RootView・AppTabView・依存注入レイヤ

**エントリーポイント:**
- `homete/Views/HometeApp.swift` - アプリのエントリーポイント、Firebaseの初期化（メインターゲットにある実装コードはこれだけ）
- `LocalPackage/Sources/AppRoot/RootView.swift` - 起動状態マシン（launching → login → logged in）
- `LocalPackage/Sources/HometeDomain/Dependencies/AppDependencies.swift` - Dependency Injectionコンテナ

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

**Firestoreサービス** (`LocalPackage/Sources/HometeInfrastructure/Firestore/FirestoreService.swift`):
- スレッドセーフのためにactorベース
- 汎用CRUD: `fetch()`, `insertOrUpdate()`, `delete()`
- `AsyncStream`を使ったリアルタイムリスナー
- コレクションパスは`CollectionPath.swift`で定義

**Cloud Functions** (`firebase/functions/src/`):
- `notifyothercohabitants` - 同居人グループメンバーにプッシュ通知を送信（v2 callable）
- `deleteuserdata` - アカウント削除時のユーザーデータクリーンアップ（v1 authトリガー）

**認証:**
- `LocalPackage/Sources/HometeInfrastructure/SignInWithApple/`経由でSign in with Apple（プロトコルは`HometeDomain/SignInWithApple/`）
- `AccountAuthClient`がFirebase Auth操作をラップ

### 状態管理

**モダンなSwift Concurrency:**
- `@Observable`マクロを使用（CombineやObservableObjectではない）
- Swift 6のstrict concurrencyでアクター分離と`@Sendable`
- 全体的にasync/await、completion handlerは使わない

**起動状態マシン** （`HometeDomain/AppLaunch/LaunchState.swift` の enum を `AppRoot/RootView.swift` が分岐）:
```
launching → notLoggedIn → Sign In with Apple
         ↓
         preLoggedIn(auth) → 登録画面
         ↓
         loggedIn(context) → メインアプリ（AppTabView）
```

### テスト戦略

**ユニットテスト** (`LocalPackage/Tests/`):
- テストターゲット: `HometeDomainTests`、`HouseworkFeatureTests`、`ContributionFeatureTests`、`HouseworkTemplateFeatureTests`
- 実行: `make test-packages`（`swift test`。xcodebuildは使わない）
- Xcode経由で流す場合のテストプラン: `homete.xctestplan`（上記4ターゲットを含む）
- CI: `.github/workflows/ci_local_package.yml`（`LocalPackage/**` の変更でトリガー、macos-26 / Xcode 26.4.1）

**スナップショットテスト** (`hometeSnapshotTests/`):
- ライブラリ: PointFreeのswift-snapshot-testing 1.18.7
- テストプラン: `snapshotTesting.xctestplan`（言語は`-AppleLanguages (ja)`で日本語固定）
- Prefire連携（`.prefire.yml`）でプレビューからテストを生成。対象ソースは `homete/Views` と `LocalPackage/Sources`
- 収録デバイス: iPhone 16 / iPhone SE (2nd generation)、必要OS: 27
- CI上で失敗時は`Build/VRT/SnapshotsFailures`にアップロード

**Firebase Functions E2Eテスト** (`firebase/functions/test/`):
- フレームワーク: Jest + ts-jest
- Firebase Emulators（Auth、Firestore、Functions）に対して実行
- コマンド: `npm run test:e2e`または`make test-e2e`

## CI/CDパイプライン

**GitHub Actionsワークフロー:**

1. **`ci_danger.yml`** - PR作成時に実行
   - Danger実行（SwiftLint、カバレッジレポート）

2. **`ci_local_package.yml`** - LocalPackageのユニットテスト
   - `LocalPackage/**`への変更でトリガー（macos-26 / Xcode 26.4.1）

3. **`functions-e2e-test.yml`** - Firebase Functionsテスト
   - `firebase/functions/**`への変更でトリガー（PR / mainまたはrelease/*へのpush）
   - ESLintとE2Eテストを実行
   - Node.js 21とJava 21を使用

4. **`deploy-functions.yml`** - Firebase FunctionsをSTGへデプロイ
   - `functions-e2e-test.yml`の完了を`workflow_run`で受けて発火し、mainへのpushかつ成功時のみデプロイ
   - `firebase deploy --only functions`（`firebase.json`のpredeployでlint+buildが走る）
   - `workflow_dispatch`で手動デプロイも可能

5. **`deploy-firestore-indexes.yml`** - Firestoreインデックスのデプロイ
   - `firebase/firestore.indexes.json`のmainへのpushでトリガー

6. **`create-release-note.yaml`** - リリースノート生成

デプロイ先は`firebase/.firebaserc`のdefaultプロジェクト（`homete-ios-dev-e3ef7`）。認証は`FIREBASE_SERVICE_ACCOUNT` secretのサービスアカウントJSONを使う。

**Xcode Cloudワークフロー:**

`ci_scripts/` 配下のシェルスクリプトが`$CI_WORKFLOW`の値で処理を分岐する。

1. **`VRT`** - スナップショットテスト
   - `ci_post_clone.sh`: SPMプラグイン検証スキップ + スナップショット参照ファイル確認

2. **`Upload Stg TestFlight`** - Stg環境TestFlightアップロード
   - `ci_post_clone.sh`: `GOOGLESERVICE_INFO` 環境変数から `homete/GoogleService-Info-dev.plist` をデコード配置

3. **`Upload For AppStore`** - 本番App Storeアップロード
   - `ci_post_clone.sh`: `GOOGLESERVICE_INFO` 環境変数から `homete/GoogleService-Info.plist` をデコード配置
   - `ci_pre_xcodebuild.sh`: `$CI_BUILD_NUMBER` を `agvtool` で全Targetに反映
   - `ci_post_xcodebuild.sh`: archive成功時に `v{version}` の git タグを作成（`$GITHUB_TOKEN` 設定時のみpush）

**コード署名:**
- Xcode Cloudが自動管理（証明書・プロビジョニングプロファイルとも）
- 開発用バンドルID: `taichi.satou.hometekure.dev`
- 本番用バンドルID: `taichi.satou.hometekure`

## 重要事項

### SwiftLint設定

- `.swiftlint.yml`で設定
- `force_unwrapping`、`multiline_arguments`、`trailing_closure`などのopt-inルールを有効化
- `identifier_name`、`statement_position`などのルールを無効化
- `ProjectTools`・`DangerTools`・`LocalPackage/.build`・`LocalPackage/Package.swift`・`vendor`を除外し、それ以外をlint

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

### Analyticsイベント

Firebase Analytics（GA4）へ送るイベントの一覧・送信タイミング・パラメータ定義は **[doc/analytics_events.md](doc/analytics_events.md)** が正。イベント名は行動ごとに増やさず機能単位で定義し、パラメータで区別する（[ADR-0009](doc/adr/0009-analytics-event-parameter-design.md)）。イベントを追加・変更したら同ドキュメントも必ず更新する。

### カスタムビルドツール（ProjectTools）

開発ツールは2つのSwift Packageに分かれている。

**`ProjectTools/`** - ビルド時に走るツール:
- **SwiftLint 0.59.1**: バイナリをSPMプラグイン（`SwiftLintPlugin`）としてビルドに組み込み、`swift build` / `swift test` 実行時に自動でlintされる
- **SwiftFormat 0.61.1**: `make format` から呼ぶ
- ビルド: `swift build --package-path ProjectTools --scratch-path ProjectTools/.build`

**`DangerTools/`** - PR自動化（CIのみ）:
- **Danger Swift 3.22.0** + **danger-swift-coverage**
- **Dangerfile** (`DangerTools/Dangerfile.swift`):
  - PRの変更が500行を超えると警告
  - `homete/`の変更ファイルでSwiftLintを実行
  - `Build/test.xcresult`からコードカバレッジをレポート
  - VRTスナップショット（`hometeSnapshotTests/__Snapshots__/PreviewTests.generated`）の差分を報告

> 注意: Dangerの`lintTargets`は`homete`のみで、実装コードの大半がある`LocalPackage/`はPR時のDanger lint対象外。ローカルではSPMプラグインが同じlintを実行するため検知はできる。

## エージェント

プロジェクトでは特定のタスクに特化したエージェントを活用します。

### pdm

プロダクトマネージャーエージェント。機能追加・修正のビジネス観点からのレビューとGitHub Issue起票を担当します。

**使用タイミング:**
- ユーザーが機能要望を出した際にプロアクティブに使用
- ユーザーが明示的に「〇〇の機能を追加するからIssueを使って」と指示した際

**使用スキル:**
- `issue-create`: GitHub Issue作成の手順とテンプレート参照

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

## ルール（.claude/rules/）の運用

`.claude/rules/`配下にルールを追加・編集する際は、Claude Codeのpath-scoped rules機能を使い、対象パターンに一致するファイルを編集・参照するときだけ自動的に読み込まれるようにすること。

- ルールファイル冒頭にYAML frontmatterで`paths:`を指定する（globパターン、複数指定可）

  ```markdown
  ---
  paths:
    - "LocalPackage/Sources/**/*.swift"
  ---
  ```

- 対象を無闇に広げない。実際にそのルールが関係するディレクトリ・拡張子のみを`paths:`に指定する（例: Swift実装のみに関係するルールに`firebase/functions/**`を含めない）
- プレーンテキストで「対象範囲: 〜のときのみ参照」のように書くだけでは自動スコープにならないため使わない。必ず`paths:`フロントマターで機能として制限する
- 既存ルールの`paths:`は以下の通り。`applyTo:`はスコープ機能として認識されないため使わないこと
  - `**/*.swift`: `swift-code-verification.md`、`swiftui-push-navigation.md`、`prefire-canimport.md`
  - `LocalPackage/Sources/**/*.swift`: `dependency-environment-access.md`、`presentation-logic-placement.md`
  - `LocalPackage/Tests/**/*.swift`: `swift-test-implementation.md`
  - `LocalPackage/Sources/Features/**/*.swift` / `LocalPackage/Sources/HometeUI/**/*.swift` / `LocalPackage/Sources/HometeInfrastructure/Purchase/**/*.swift` / `LocalPackage/Sources/AppRoot/**/*.swift`: `ux-writing.md`
  - `.claude/**` / `CLAUDE.md` / `.worktreeinclude`: `claude-config-update.md`
  - `adr.md` / `git-commit.md` は`paths:`を持たない（技術選定・コミット粒度はファイル種別に紐づかないため意図的に常時ロード）

## ファイル整理の規約

新機能を追加する際:

1. **Views**: `LocalPackage/Sources/Features/<機能名>Feature/` に追加
2. **ドメインモデル**: ドメイン領域別に `LocalPackage/Sources/HometeDomain/` のサブフォルダに追加
3. **Clients**: `LocalPackage/Sources/HometeDomain/Dependencies/` でプロトコルと`.previewValue`を定義し、`.liveValue`は `LocalPackage/Sources/HometeInfrastructure/` に実装
4. **Services**: `LocalPackage/Sources/HometeInfrastructure/` のサブフォルダにインフラコードを追加
5. **Stores**: `LocalPackage/Sources/HometeDomain/` の該当ドメインフォルダにObservable状態管理クラスを追加（機能固有のものは Feature 配下の `Model/` でもよい）
6. **共通UI**: `LocalPackage/Sources/HometeUI/` に追加
7. **Tests**: `LocalPackage/Tests/<対象モジュール>Tests/` に対象モジュールの構造をミラー

新しいモジュールを足す場合は `LocalPackage/Package.swift` と [doc/multimodules_structure.md](doc/multimodules_structure.md) の両方を更新する。

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
