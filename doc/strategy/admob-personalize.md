# AdMob広告のパーソナライズ化 実装方針

> 関連Issue: [#175 表示する広告をパーソナライズ化する](https://github.com/stotic-dev/homete_iOS/issues/175)
> ブランチ: `feat/admob_personarize`
> 参考: [Google AdMob iOS Privacy ガイド](https://developers.google.com/admob/ios/privacy?hl=ja)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

Google AdMobで表示する広告をパーソナライズ化して広告収入の最適化を行う。
GDPR等のプライバシー規制に対応するため、UMP (User Messaging Platform) による同意取得フォームと、iOSのATT (App Tracking Transparency) ダイアログを実装する。
ユーザーが同意した場合はパーソナライズ広告、拒否した場合は非パーソナライズ広告を表示する。

## 要件

### 機能要件

1. **UMP同意フォームの表示**
   - アプリ起動直後（AppDelegate.didFinishLaunching の Firebase 初期化後）に同意状態を取得する
   - 同意が必要な地域（EU等）のユーザーには UMP の同意フォームを表示する
   - 同意状態は SDK 側で自動的に保存され、次回起動以降は不要な場合は表示しない

2. **ATT ダイアログの表示**
   - AdMobコンソール（Privacy & messaging）で App Tracking Transparency メッセージを設定済み
   - `ConsentForm.loadAndPresentIfRequired` 実行時に、このコンソール設定に基づきIDFAメッセージ→システムのATT許可ダイアログが自動的に提示される
   - アプリコード側で `ATTrackingManager.requestTrackingAuthorization` を明示的に呼び出す実装は行わない（AdMobコンソール設定に委譲する方針に変更、実機確認済み）
   - `NSUserTrackingUsageDescription` 文言: 「より関連性の高い広告を表示するために、あなたの閲覧履歴を利用します。」
   - 一度回答済みの場合は再表示しない（iOSのATT標準挙動）

3. **広告表示の出し分け**
   - `ConsentInformation.canRequestAds == true` の場合のみ `MobileAds.shared.start()` を実行する
   - ユーザーがATTや同意フォームで拒否しても `canRequestAds` が `true` であれば**非パーソナライズ広告**として表示する
   - 既存の `BannerViewContainer` の表示制御は変更不要（広告サーバー側で出し分けが行われる）

4. **プライバシー設定の再表示導線**
   - 今回のスコープ外（将来 `ConsentInformation.privacyOptionsRequirementStatus == required` の対応として別Issueで検討）

### 非機能要件 / 制約

- 既存DIパターン（`AppDependencies`）に準拠
- Swift 6 strict concurrency 準拠
- UMP/ATT のSDK処理自体はテスト不能なため、`Protocol` で抽象化してモック差し替え可能にする
- AdMobの起動シーケンス（同意取得 → ATT → MobileAds.start）は `AdsSetupUseCase` に集約し、ユニットテスト対象とする
- 既存の `MobileAdsClient` の責務は変更せず、`MobileAds.shared.start()` のラッパーのまま維持する

## 設計方針

### 1. クラス構成

新規追加する型と既存型の役割分担:

| 型 | 種別 | 役割 |
|---|---|---|
| `ConsentClient` | 新規（クロージャベースClient） | UMP の同意情報取得・同意フォーム表示（ATTダイアログ提示を含む）・`canRequestAds` 状態の提供 |
| `MobileAdsClient` | 新規（クロージャベースClient） | `MobileAds.shared.start()` の抽象 |
| `AdsSetupUseCase` | 新規 class | 上記2つを束ねて起動シーケンスを実行する。**テスト対象** |

**注:** 当初 `AppTrackingClientProtocol`/`AppTrackingClient` を新規実装する設計だったが、AdMobコンソールの App Tracking Transparency メッセージ設定により `ConsentClient.loadAndPresentConsentFormIfRequired` の中でATTダイアログが自動提示されることを確認できたため、専用Clientの実装は行わない方針に変更した。

### 2. 起動シーケンス

`AdsSetupUseCase.setup()` の流れ:

```swift
public func setup() async {
    // 1. UMP同意情報の取得・更新
    do {
        try await consentClient.requestConsentInfoUpdate()
        // 2. 必要なら同意フォームを表示（AdMobコンソール設定によりATTダイアログもここで提示される）
        try await consentClient.loadAndPresentConsentFormIfRequired()
    } catch {
        // ログ出力のみ。失敗してもMobileAds起動は試みる
    }

    // 3. canRequestAdsがtrueならMobileAds起動
    if await consentClient.canRequestAds() {
        await mobileAdsClient.initialize()
    }
}
```

**設計意図:**
- UMP 同意フォーム → MobileAds の順序は [Google公式ガイド](https://developers.google.com/admob/ios/privacy?hl=ja) に沿う
- ATT許可リクエストはアプリコードで明示的に呼ばず、AdMobコンソールの App Tracking Transparency メッセージ設定により `loadAndPresentConsentFormIfRequired` の内部で提示される（実機確認済み）
- 同意取得が失敗してもアプリ自体は起動継続させたいため、try-catch で広く受ける
- `canRequestAds` が `false`（同意必須地域で同意拒否など）の場合は `MobileAds.start` を呼ばない

### 3. AppDelegate 修正

`homete/Views/HometeApp.swift` の `AppDelegate` に `AdsSetupUseCase` インスタンスを保持し、`setupGoogleMobileAds()` から呼び出す:

```swift
let adsSetupUseCase = AdsSetupUseCase(
    consentClient: .liveValue,
    mobileAdsClient: .liveValue
)

func setupGoogleMobileAds() {
    guard !isXcodePreview, !isUnitTestMode else { return }
    Task {
        await adsSetupUseCase.setup()
    }
}
```

既存の `MobileAdsClient.shared.initialize()` の直接呼び出しは廃止。

### 4. UMP SDK の追加

`LocalPackage/Package.swift` に依存追加:

```swift
.package(
    url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git",
    from: "3.0.0"  // 最新版に応じて要調整
),
```

`AppRoot` ターゲットに依存追加（プロダクト名は `GoogleUserMessagingPlatform`）:

```swift
.product(
    name: "GoogleUserMessagingPlatform",
    package: "swift-package-manager-google-user-messaging-platform",
    condition: .when(platforms: [.iOS])
),
```

### 5. Info.plist 修正

`homete/Info.plist` に `NSUserTrackingUsageDescription` を追加:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>より関連性の高い広告を表示するために、あなたの閲覧履歴を利用します。</string>
```

### 6. テスト方針

新規追加: `LocalPackage/Tests/HometeDomainTests/AdsSetupUseCaseTests.swift`

- `HometeDomainTests` テストターゲット（既存）に追加
- `AdsSetupUseCase` の以下ケースをテスト:
  - 全て成功: `mobileAdsClient.initialize()` が呼ばれる
  - 同意情報取得失敗: MobileAds起動の流れは継続する
  - `canRequestAds == false`: `mobileAdsClient.initialize()` が呼ばれない
  - 呼び出し順序: 同意フォーム → MobileAds の順で実行される
  - ATTはコード上で明示的に扱わない（AdMobコンソール設定に委譲するためテスト対象外）

クロージャベースの `ConsentClient` / `MobileAdsClient` を直接テスト用インスタンスとして組み立て、`actor` の `CallRecorder` で各メソッドの呼び出し回数・順序を検証する。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/ConsentClient.swift` | UMP同意Client（protocol定義・クロージャベース） |
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/MobileAdsClient.swift` | `MobileAds.shared.start()` の抽象（クロージャベース） |
| 新規UseCase | `LocalPackage/Sources/HometeDomain/Advertisement/AdsSetupUseCase.swift` | 起動シーケンスの集約 |
| 新規実装 | `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplConsentClient.swift` | `ConsentClient.liveValue`（UMP SDK使用） |
| 新規実装 | `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplMobileAdsClient.swift` | `MobileAdsClient.liveValue`（GoogleMobileAds SDK使用） |
| 新規テスト | `LocalPackage/Tests/HometeDomainTests/AdsSetupUseCaseTests.swift` | UseCaseのユニットテスト |
| 修正 | `LocalPackage/Package.swift` | UMP SDK 依存追加 |
| 修正 | `homete/Views/HometeApp.swift` | `AdsSetupUseCase` 呼び出しに変更 |
| 修正 | `homete/Info.plist` | `NSUserTrackingUsageDescription` 追加 |

**注:** 上記は当初設計からモジュール構成（`HometeInfrastructure` → `HometeDomain`/`AppRoot` へのマルチモジュール分割）に合わせて実態を反映したもの。`AppTrackingClient` は前述の理由により実装していない。

## タスク

### Phase 1: 設計確定

- [x] UMP/ATT の表示タイミングを決定（アプリ起動直後）
- [x] 拒否時の挙動を決定（非パーソナライズ広告を表示）
- [x] プライバシー再表示導線はスコープ外と決定
- [x] ATT文言を決定
- [x] クラス設計（ConsentClient/AdsSetupUseCase）を決定。ATTはAppTrackingClientを実装せずAdMobコンソール設定に委譲する方針に変更

### Phase 2: 実装

- [x] `Package.swift` に UMP SDK 依存を追加
- [x] `ConsentClient` （クロージャベースClient + `liveValue`実装）を追加
- [x] `MobileAdsClient` （クロージャベースClient + `liveValue`実装）を追加
- [x] `AdsSetupUseCase` を実装
- [x] `HometeApp.swift` の `setupGoogleMobileAds()` を `AdsSetupUseCase` 呼び出しに変更
- [x] `Info.plist` に `NSUserTrackingUsageDescription` を追加
- [x] AdMobコンソールで App Tracking Transparency メッセージを設定（コード外の作業）

### Phase 3: テスト

- [x] `AdsSetupUseCaseTests` を追加
- [x] 正常系：全Client成功 → MobileAds起動
- [x] 異常系：同意取得失敗 → 後続シーケンス継続
- [x] 出し分け：`canRequestAds == false` → MobileAds起動しない
- [x] 順序：同意フォーム → MobileAds

### Phase 4: 検証

- [x] `swift build` でビルド通過
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過
- [x] ユニットテスト実行（追加分含む）通過
- [x] 実機で動作確認（ATT・UMPダイアログが表示されること、広告が表示されることを確認済み）

### Phase 5: PR

- [x] PR作成（`pr-create` スキル使用、PR #181）
- [x] Danger / CI通過
- [ ] レビュー対応（未アサイン。レビュワー依頼が必要）
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/175
- PR: https://github.com/stotic-dev/homete_iOS/pull/181
- Google公式ガイド: https://developers.google.com/admob/ios/privacy?hl=ja
- ATT/IDFAメッセージの挙動: https://developers.google.com/admob/ios/privacy/idfa
- UMP SDK SPM: https://github.com/googleads/swift-package-manager-google-user-messaging-platform
- 既存実装（参考）:
  - `LocalPackage/Sources/HometeDomain/Dependencies/ConsentClient.swift`
  - `LocalPackage/Sources/HometeDomain/Dependencies/MobileAdsClient.swift`
  - `LocalPackage/Sources/HometeDomain/Advertisement/AdsSetupUseCase.swift`
  - `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplConsentClient.swift`
  - `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplMobileAdsClient.swift`
  - `homete/Views/HometeApp.swift`
