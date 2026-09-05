# グループ招待リンク（Universal Link）実装方針

> 関連Issue: [#182 グループ作成、メンバー追加時のアプリ共有機能](https://github.com/stotic-dev/homete_iOS/issues/182)
> ブランチ: `feat/join-group`
> 技術選定の経緯は [ADR-0013](../adr/0013-cohabitant-invitation-universal-link.md) を参照。

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

同居人グループへの招待をURL（Universal Link）で共有できるようにする。LINE等で送られたリンクをタップすると、アプリがインストール済みなら参加確認画面に直接遷移し、未インストールならApp Storeへ誘導される。

現行のグループ登録は MultipeerConnectivity による近接P2Pのみで、「同じ場所にいて、両者ともアプリを入れている」ことが前提になっている。招待リンクを追加することで、離れた相手・アプリ未インストールの相手ともグループを作れるようにする。

## 要件

### 機能要件

#### 招待する側

- `CohabitantRegistrationView` のスキャン画面（`CohabitantRegistrationInitialStateView`）に「リンクで招待」導線を追加する
  - 既存のP2P（近くのデバイスを自動検出）は**そのまま残し**、並列の選択肢として提示する
- タップすると招待トークンを発行し、共有シート（`UIActivityViewController`）でURLを共有できる
- 招待者がまだグループに所属していない場合は、**トークン発行時にグループを新規作成**して自分をメンバーに加える
- 発行に失敗した場合はアラートを表示する

#### 招待される側（アプリインストール済み）

- 招待URLをタップするとアプリが起動し、参加確認画面（`CohabitantJoinView`）が表示される
- 「参加する」を選ぶとグループに参加し、完了表示の後にホームへ戻る
- 以下のケースはエラーとして表示し、参加しない
  - トークンが存在しない（無効なリンク）
  - トークンの有効期限（24時間）が切れている
  - **すでに別のグループに参加済み**（既存グループの家事データを失う事故を防ぐため、移動は許可しない）
  - 通信エラー
- 未ログイン／アカウント登録前にリンクを開いた場合は、トークンを保持したままログイン・登録を完了させ、`loggedIn` になった時点で参加確認画面を表示する

#### 招待される側（アプリ未インストール）

- Universal Link はアプリ未インストール時 Safari でフォールバックページを開く
- フォールバックページには次の手順を明記する
  1. App Store から homete をインストール
  2. LINE等に戻って**もう一度このリンクをタップ**する
- Firebase Dynamic Links は 2025/8 に終了しているため deferred deep link（インストール後の自動遷移）は行わない。「リンク再タップ」の案内で代替する

### 非機能要件 / 制約

- トークンの有効期限は **24時間**、使用回数は **無制限**（1つのリンクで複数人が参加できる）
- 参加処理は **Cloud Functions（v2 callable）** で行い、トークン検証・期限チェック・`members` 更新・`Account` 更新をサーバ側のトランザクションで完結させる
- Universal Link のドメインは **Firebase Hosting** で配信する
  - 今回は dev 環境（`homete-ios-dev-e3ef7.web.app`）のみ先行して構築する
  - 本番ドメインの設定は、本番Firebaseプロジェクト確定後に別タスクとする
- 既存の `CohabitantRegistrationView` / P2P 実装は削除しない
- iOS 側の Client は既存のDIパターン（`DependencyClient` + `liveValue` / `previewValue`）に従う
- Functions は既存の `notifyothercohabitants` / `synchouseworkretention` と同じ実装パターンに揃え、E2Eテストを追加する

## 設計方針

### 1. URL 設計

```
https://homete-ios-dev-e3ef7.web.app/invite/<token>     # dev
https://<本番ドメイン>/invite/<token>                     # prod（後日）
```

クエリパラメータではなくパス方式にする。AASA の `components` で `/invite/*` を素直に判定でき、フォールバックページの rewrite も単純になるため。

トークンはドキュメントIDを兼ねるランダム文字列（`crypto.randomUUID()`）とする。

### 2. Firebase Hosting（AASA + フォールバックページ）

`firebase/firebase.json` に `hosting` セクションを追加する。

```json
"hosting": {
  "public": "hosting/public",
  "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
  "rewrites": [
    { "source": "/invite/**", "destination": "/invite/index.html" }
  ],
  "headers": [
    {
      "source": "/.well-known/apple-app-site-association",
      "headers": [{ "key": "Content-Type", "value": "application/json" }]
    }
  ]
}
```

`firebase/hosting/public/.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["56LYVN6DMF.taichi.satou.hometekure.dev"],
        "components": [
          { "/": "/invite/*", "comment": "同居人グループ招待リンク" }
        ]
      }
    ]
  }
}
```

`firebase/hosting/public/invite/index.html`（未インストール時のみ表示される）:

- 「hometeのグループに招待されています」
- ①App Storeでインストール → ②このリンクをもう一度タップ、の2ステップを明示
- App Store の URL は未確定のため、確定後に差し替える（残課題）

デプロイは `.github/workflows/deploy-hosting.yml` を新規追加し、`firebase/hosting/**` の main への push で `firebase deploy --only hosting` を実行する。認証は既存の `FIREBASE_SERVICE_ACCOUNT` secret を流用する。

### 3. Associated Domains（entitlements）

`homete/hometeDebug.entitlements` に追加:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:homete-ios-dev-e3ef7.web.app</string>
</array>
```

`hometeRelease.entitlements` への追加は本番ドメイン確定後。
Apple Developer 上の App ID に **Associated Domains capability を有効化する必要がある**（Xcode Cloud の自動署名でもApp ID側の設定は必要）。

### 4. Firestore データ設計

新規コレクション `Invitation/{token}`:

| フィールド | 型 | 説明 |
|---|---|---|
| `cohabitantId` | String | 参加先のグループID |
| `createdBy` | String | 発行者のAccount ID |
| `createdAt` | Timestamp | 発行日時 |
| `expiresAt` | Timestamp | `createdAt` + 24時間 |

- 使用回数は制限しない（期限内なら何人でも参加可）
- 期限切れドキュメントは Firestore の TTLポリシーで自動削除する。コレクショングループ `Invitation` の `expiresAt` フィールドに対し、2026-09-05に `gcloud firestore fields ttls update expiresAt --collection-group=Invitation --enable-ttl --project=<プロジェクトID>` でstg（`homete-ios-dev-e3ef7`）・prod（`homete-ios-dev`）両方に設定し、`ttlConfig.state: ACTIVE` を確認済み（[#231](https://github.com/stotic-dev/homete_iOS/issues/231)）。削除猶予日数などの追加パラメータはなく、期限切れ後24時間以内に非同期削除される仕様
- **iOSからは直接読み書きしない**（Functions のみが触る）ため、iOS側の `CollectionPath` には追加しない

### 5. Cloud Functions

`firebase/functions/src/cohabitantInvitation.ts` を新規作成し、`index.ts` から export する。

#### `issuecohabitantinvitation`（v2 callable）

```
入力: なし
出力: { token: string, cohabitantId: string, expiresAt: number }
```

1. 未認証なら `unauthenticated`
2. 呼び出し元の `Account` を取得（無ければ `not-found`）
3. `cohabitantId` が未設定なら `Cohabitant` を新規作成（`members: [uid]`）し、`Account.cohabitantId` を更新
4. `Invitation/{token}` を作成して返す

#### `joincohabitant`（v2 callable）

```
入力: { token: string }
出力: { cohabitantId: string }
```

1. 未認証なら `unauthenticated`
2. `Invitation/{token}` を取得。無ければ `not-found`
3. `expiresAt < now` なら `deadline-exceeded`
4. 呼び出し元の `Account.cohabitantId` が設定済みの場合
   - 招待先と同一なら**冪等に成功**として返す（リンク再タップ対策）
   - 異なるなら `failed-precondition`（すでに別グループに参加済み）
5. トランザクションで `Cohabitant.members` に `arrayUnion(uid)`、`Account.cohabitantId` を更新

`FirestoreHelper`（`src/models/FirestoreHelper.ts`）に招待ドキュメント操作のメソッドを追加する。

### 6. iOS: Client 層

`LocalPackage/Sources/HometeDomain/Dependencies/CohabitantInvitationClient.swift`:

```swift
public struct CohabitantInvitationClient: Sendable {

    /// 招待トークンを発行する（グループ未所属の場合はグループも作成される）
    public let issue: @Sendable () async throws -> CohabitantInvitation
    /// 招待トークンでグループに参加する
    public let join: @Sendable (_ token: String) async throws -> String

    public init(
        issue: @Sendable @escaping () async throws -> CohabitantInvitation = { .preview },
        join: @Sendable @escaping (_ token: String) async throws -> String = { _ in "" }
    ) { ... }

}

public extension CohabitantInvitationClient {
    static let previewValue: CohabitantInvitationClient = .init()
}
```

- `CohabitantInvitation`（`HometeDomain/Cohabitant/`）: `token` / `cohabitantId` / `expiresAt`
- `liveValue` は `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplCohabitantInvitationClient.swift` に実装（既存の `ImplCohabitantPushNotificationClient` と同じく `Functions.functions().httpsCallable(...)` を使う）
- `AppDependencies` に `cohabitantInvitationClient` を追加
- Functions の `HttpsError` は `FunctionsErrorCode` から判定し、ドメインエラー `CohabitantInvitationError`（`.notFound` / `.expired` / `.alreadyJoined` / `.unknown`）にマッピングする

### 7. iOS: リンク生成・解析

`LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantInvitationLink.swift`:

```swift
public enum CohabitantInvitationLink {

    /// 招待リンクのホスト（Debug/Releaseで切り替え）
    static var host: String { ... }

    public static func url(token: String) -> URL?
    /// Universal Linkから招待トークンを取り出す（対象外のURLならnil）
    public static func token(from url: URL) -> String?

}
```

ホストは `#if DEBUG` で切り替える（`HometeApp.swift` の GoogleService-Info 切り替えと同じ流儀）。

### 8. iOS: リンク受信とルーティング

```
Universal Link タップ
  ↓ RootView.onOpenURL
CohabitantInvitationLink.token(from:)
  ↓
PendingInvitationStore.pendingToken に保持
  ↓ launchState == .loggedIn になったら消化
AppTabView が fullScreenCover で CohabitantJoinView を表示
```

- `PendingInvitationStore`（`HometeDomain/Cohabitant/`、`@MainActor @Observable`）にトークンを保持する。未ログイン・アカウント登録前にリンクを開いた場合も保持され、`loggedIn` 到達後に消化される
- `AppRoute` に `case cohabitantJoin(token: String)` を追加し、`RouteResolverInjection` で `CohabitantJoinView(token:)` を解決する
- `.onOpenURL` は `homete/Views/HometeApp.swift` ではなく `AppRoot/RootView.swift` に置く（実装をLocalPackage内で完結させるため）

#### `CohabitantJoinView`（新規: `Features/HomeFeature/JoinCohabitantView/`）

状態遷移:

| 状態 | 表示 |
|---|---|
| `confirming` | 「グループに参加しますか？」＋参加／キャンセル |
| `processing` | ローディング |
| `completed` | 参加完了（既存 `CohabitantRegistrationCompleteView` を流用） |
| `failed(reason)` | 無効なリンク／有効期限切れ／すでに参加済み／通信エラー |

参加成功後は Functions 側で `Account` が更新済みのため、クライアントは**オンメモリのみ**同期する。
`AccountStore` に `applyCohabitantId(_:)`（Firestoreへ書き込まず `account` を差し替える）を追加し、二重書き込みを避ける。

### 9. iOS: 共有UI

- `HometeUI` に `ShareSheet`（`UIViewControllerRepresentable` で `UIActivityViewController` をラップ）を追加
- `CohabitantRegistrationInitialStateView` に「リンクで招待」ボタンを配置
  - タップ → `issue()` 実行（ローディング）→ URL生成 → `.sheet` で共有シート表示
  - 共有テキスト例: `hometeで一緒に家事を管理しませんか？下のリンクから参加できます\n<URL>`
  - 発行失敗時はアラート

### 10. Analytics

`doc/analytics_events.md` に `cohabitant_invitation` イベントを追加する（イベント名は機能単位、行動はパラメータで区別する [ADR-0009](../adr/0009-analytics-event-parameter-design.md) 方針に従う）。

| パラメータ | 値 | 説明 |
|---|---|---|
| `action` | `issue` / `open` / `join` | 招待発行／リンク起動／参加実行 |
| `result` | `success` / `expired` / `already_joined` / `not_found` / `failure` | 結果 |

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規（Hosting） | `firebase/hosting/public/.well-known/apple-app-site-association` | AASA |
| 新規（Hosting） | `firebase/hosting/public/invite/index.html` | 未インストール時のフォールバックページ |
| 修正 | `firebase/firebase.json` | `hosting` セクション追加 |
| 新規（CI） | `.github/workflows/deploy-hosting.yml` | Hostingデプロイ |
| 新規（Functions） | `firebase/functions/src/cohabitantInvitation.ts` | 招待発行・参加のcallable |
| 修正（Functions） | `firebase/functions/src/index.ts` | export追加 |
| 新規（Functions） | `firebase/functions/src/models/Invitation.ts` | 招待ドキュメントのモデル |
| 新規（Functions） | `firebase/functions/src/models/InvitationManager.ts` | 招待発行・参加のロジック（callableから分離してテスト可能にする） |
| 修正（Functions） | `firebase/functions/src/models/FirestoreCollections.ts` | `Invitation` コレクション追加 |
| 修正（Functions） | `firebase/functions/src/models/Cohabitant.ts` | `id` フィールド追加（クライアントのリスナーが参照するため） |
| 新規（テスト） | `firebase/functions/test/e2e/cohabitantInvitation.test.ts` | E2Eテスト |
| 修正 | `homete/hometeDebug.entitlements` | Associated Domains |
| 新規（Domain） | `HometeDomain/Cohabitant/CohabitantInvitation.swift` | 招待モデル |
| 新規（Domain） | `HometeDomain/Cohabitant/CohabitantInvitationLink.swift` | URL生成・解析 |
| 新規（Domain） | `HometeDomain/Cohabitant/CohabitantInvitationError.swift` | 招待固有のエラー |
| 新規（Domain） | `HometeDomain/Cohabitant/PendingInvitationStore.swift` | 未処理トークンの保持 |
| 新規（Domain） | `HometeDomain/Cohabitant/CohabitantJoinState.swift` | 参加処理の状態と失敗理由 |
| 新規（Domain） | `HometeDomain/Cohabitant/CohabitantJoinStore.swift` | 参加処理のStore |
| 新規（Domain） | `HometeDomain/AnalyticsLog/CohabitantInvitationAnalyticsAction.swift` | Analyticsのパラメータ設計 |
| 新規（Domain） | `HometeDomain/Dependencies/CohabitantInvitationClient.swift` | Clientプロトコル定義 |
| 修正（Domain） | `HometeDomain/Account/AccountStore.swift` | `applyCohabitantId(_:)` 追加 |
| 修正（Domain） | `HometeDomain/Dependencies/AppDependencies.swift` | Client追加 |
| 新規（Impl） | `AppRoot/Dependency/Impl/ImplCohabitantInvitationClient.swift` | callable呼び出し |
| 修正（AppRoot） | `AppRoot/RootView.swift` | `.onOpenURL` でトークン受信・`PendingInvitationStore` の注入 |
| 修正（AppRoot） | `AppRoot/AppTabView.swift` | 参加画面の`fullScreenCover`表示 |
| 修正（AppRoot） | `AppRoot/ResolverImpl/RouteResolverInjection.swift` | `.cohabitantJoin` 解決 |
| 修正（Domain） | `HometeDomain/Navigation/AppRoute.swift` | `case cohabitantJoin` 追加 |
| 新規（UI） | `HometeUI/Components/Share/ShareSheet.swift` | 共有シート |
| 新規（View） | `Features/HomeFeature/JoinCohabitantView/CohabitantJoinView.swift` | 参加確認画面 |
| 新規（View） | `Features/HomeFeature/JoinCohabitantView/SubViews/CohabitantJoinCompletedView.swift` | 参加完了表示 |
| 新規（View） | `Features/HomeFeature/JoinCohabitantView/SubViews/CohabitantJoinFailureView.swift` | 参加失敗表示 |
| 修正（View） | `Features/HomeFeature/RegisterCohabitantView/SubViews/ScanningState/CohabitantRegistrationInitialStateView.swift` | 「リンクで招待」導線 |
| 修正（View） | `Features/HomeFeature/RegisterCohabitantView/SubViews/ScanningState/CohabitantRegistrationScanningStateView.swift` | 招待トークンの発行と共有シート表示 |
| 修正（Doc） | `doc/analytics_events.md` | イベント追加 |
| 新規（Doc） | `doc/adr/0013-cohabitant-invitation-universal-link.md` | 技術選定のADR |

## タスク

### Phase 1: 設計確定

- [x] 共有リンクの役割 → 招待コードによる遠隔参加まで対応する
- [x] AASA配信先 → Firebase Hosting（devを先行、prodは後日）
- [x] 参加処理の実行場所 → Cloud Functions callable
- [x] トークンの有効期限・使用回数 → 24時間・無制限
- [x] 参加済みユーザーが招待リンクを開いた場合 → 参加不可としてエラー表示
- [x] 既存P2Pとの関係 → 残したうえで共有導線を追加
- [x] 未インストールユーザー → LPで「再度リンクをタップ」を案内（deferred deep linkは行わない）
- [ ] 本番Firebaseプロジェクト（Hostingドメイン）の確定
- [ ] App Store ID の確定（LPのApp Storeリンク用）

### Phase 2: 実装

- [x] Firebase Hosting のセットアップ（`firebase.json` / AASA / フォールバックLP）
- [x] `deploy-hosting.yml` の追加
- [x] Functions: `issuecohabitantinvitation` / `joincohabitant` の実装
- [x] Functions: E2Eテストの追加
- [x] entitlements に Associated Domains を追加（Debug）
- [x] Domain: `CohabitantInvitation` / `CohabitantInvitationLink` / `PendingInvitationStore` / `CohabitantInvitationClient`
- [x] Impl: `ImplCohabitantInvitationClient` + `AppDependencies` 登録
- [x] `AccountStore.applyCohabitantId(_:)` 追加
- [x] `AppRoute.cohabitantJoin` 追加 + `RouteResolverInjection` 対応
- [x] `RootView` に `.onOpenURL` を追加し、`loggedIn` 到達後にトークンを消化
- [x] `CohabitantJoinView` の実装（4状態）+ Preview
- [x] `ShareSheet` の追加
- [x] `CohabitantRegistrationInitialStateView` に「リンクで招待」導線を追加 + Preview
- [x] `doc/analytics_events.md` の更新
- [x] ADR-0013 の作成

### Phase 3: 検証

- [x] `swift build` でビルド通過
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過（`make check-previews` も通過）
- [x] ユニットテスト実行（追加分含む）通過（5ターゲット / 281件）
  - `CohabitantInvitationLink` のURL生成・解析
  - `PendingInvitationStore` のトークン保持・消化
  - `CohabitantJoinStore` の状態遷移（エラー分岐含む）
  - `AccountStore.applyCohabitantId(_:)` / `cohabitant_invitation` イベントのパラメータ
- [x] Functions の lint / E2Eテスト通過（27件）
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新（Xcode Cloudの`VRT`に委ねる）
- [ ] 実機で Universal Link の動作確認（Hostingデプロイ後）
  - インストール済み → アプリが開いて参加確認画面に遷移する
  - 未インストール → Safariでフォールバックページが開く
  - 期限切れ・参加済み・無効トークンのエラー表示

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 残課題（今回のスコープ外）

以下はIssueに切り出し済み。

- [#229 本番環境で招待リンク(Universal Link)を有効化する](https://github.com/stotic-dev/homete_iOS/issues/229)
  - 本番Hosting・AASA・`hometeRelease.entitlements`・`productionHost`・App IDのAssociated Domains capability・実機確認
- [#230 招待リンクのフォールバックページにApp Storeへの導線を設定する](https://github.com/stotic-dev/homete_iOS/issues/230)

その他:

- `deleteuserdata` で最後のメンバーが退会した場合の招待ドキュメントのクリーンアップ（TTLで自然消滅するため優先度低）

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/182
- PR: https://github.com/stotic-dev/homete_iOS/pull/228
- 既存実装（参考）:
  - `LocalPackage/Sources/Features/HomeFeature/RegisterCohabitantView/CohabitantRegistrationView.swift`
  - `LocalPackage/Sources/Features/HomeFeature/RegisterCohabitantView/SubViews/ProcessingState/CohabitantRegistrationProcessingLeader.swift`
  - `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplCohabitantPushNotificationClient.swift`
  - `firebase/functions/src/notifyCohabitants.ts`
  - `doc/strategy/setting-create-group-and-add-member.md`
