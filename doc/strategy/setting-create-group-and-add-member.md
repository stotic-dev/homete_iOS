# 設定画面からのグループ作成/メンバー追加導線 実装方針

> 関連Issue: [#156 メンバー追加項目を設定画面に追加](https://github.com/stotic-dev/homete_iOS/issues/156)
> ブランチ: `feat/setting_create_group_and_add_member`

## ステータス

- [x] 要件確定
- [ ] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

設定画面（`SettingView`）に「メンバー追加」のメニュー項目を追加し、タップすると `CohabitantRegistrationView` を `fullScreenCover` で表示する導線を提供する。
グループ未参加ユーザーは新規にグループを作成でき、グループ参加済みユーザーは新メンバーを招待できるようにすることが目的。

## 要件

### 機能要件

- 設定画面の `SettingMenuItem` に「メンバー追加」項目を追加する
  - タイトル: `メンバー追加`
  - SF Symbol アイコン: `person.badge.plus`
- 項目は **グループ参加状態に関わらず常に表示** する（`hasCohabitant` で出し分けない）
- タップ時の挙動:
  - `CohabitantRegistrationView` を `fullScreenCover` で表示する（`HomeView` の既存導線と同じ表示方式）
  - 表示は `RouteResolver` 経由（`router.resolve(.cohabitantRegistration)`）で解決する
- 登録完了後の挙動:
  - `CohabitantRegistrationView` 内の既存 `dismiss` 動作に従い、モーダルが閉じて **`SettingView` に戻る**
  - `SettingView` 自体は閉じない（`SettingView` を閉じる追加処理はしない）

### 非機能要件 / 制約

- 既存の `CohabitantRegistrationView` を流用する（新規Viewは作らない）
- `RouteResolver` 経由でViewを解決する（既存 `HomeView` と同じ方式）
- ユニットテスト・スナップショットテストは既存パターンに従う

## 設計方針

### 1. `SettingMenuItem` enumに `memberRegistration` ケースを追加

`LocalPackage/Sources/HometeDomain/Setting/SettingMenuItem.swift` の `SettingMenuItem` enum に新ケースを追加する。

```swift
public enum SettingMenuItem: Equatable, CaseIterable {
    case memberRegistration  // ← 追加
    case taskTemplate
    case privacyPolicy
    case license

    public var title: LocalizedStringKey {
        switch self {
        case .memberRegistration: "メンバー追加"
        // ...
        }
    }

    public var iconName: String {
        switch self {
        case .memberRegistration: "person.badge.plus"
        // ...
        }
    }
}
```

- 表示順: 最上段（taskTemplateの前）に配置する
  - 理由: 既存 `taskTemplate` 等は機能設定系。グループ系は性質が異なるので独立して見やすい先頭に置く

### 2. `SettingView` でタップハンドラを実装

既存の `ForEach(SettingMenuItem.allCases)` 内で `case .memberRegistration` 時のアクションを追加する。
`HomeView` と同じパターンで `@State` のフラグと `fullScreenCoverOnIOS` を使う。

```swift
@Environment(\.routeResolver) var router
@State var isShowMemberRegistration = false

// メニューボタンのactionで
SettingMenuItemButton(item: item) {
    switch item {
    case .memberRegistration:
        isShowMemberRegistration = true
    case .taskTemplate, .privacyPolicy, .license:
        // TODO: 既存のまま
        break
    }
}

// ルートビューに
.fullScreenCoverOnIOS(isPresented: $isShowMemberRegistration) {
    router.resolve(.cohabitantRegistration)
}
```

### 3. 登録完了後のdismiss動作確認

`CohabitantRegistrationView` の `onCompleteCohabitantRegistration` を確認し、登録完了時に `dismiss()` が呼ばれていることを担保する。
（現状は `accountStore.registerCohabitantId(cohabitantId)` の後の dismiss 挙動を要確認）

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Setting/SettingMenuItem.swift` | `.memberRegistration` ケースを追加 |
| 修正View | `LocalPackage/Sources/Features/SettingFeature/SettingView.swift` | タップハンドラとfullScreenCoverを追加 |

新規Viewファイルは作らない。

## タスク

### Phase 1: 設計確定

- [x] メニュー項目のタイトル・アイコン確定（「メンバー追加」+ person.badge.plus）
- [x] 表示制御方針確定（常に表示）
- [x] 表示方式確定（fullScreenCover）
- [x] 登録完了後の挙動確定（SettingViewに戻る）
- [ ] `CohabitantRegistrationView` の登録完了時 dismiss 挙動の現状確認

### Phase 2: 実装

- [ ] `SettingMenuItem` に `.memberRegistration` ケースを追加（title / iconName）
- [ ] `SettingView` に `@Environment(\.routeResolver)` を追加
- [ ] `SettingView` に `@State isShowMemberRegistration` を追加
- [ ] `SettingView` のメニュー `action` で `.memberRegistration` 分岐を実装
- [ ] `SettingView` ルートに `fullScreenCoverOnIOS` を追加
- [ ] `SettingView` Preview に routeResolver を注入（必要なら）

### Phase 3: 検証

- [ ] `swift build` でビルド通過
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] ユニットテスト実行（追加分含む）通過
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] 実機/シミュレータで動作確認
  - グループ未参加状態でタップ → 登録Viewが表示される
  - グループ参加済み状態でタップ → 登録Viewが表示される
  - 登録完了後 → SettingViewに戻る

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/156
- 既存実装（参考）:
  - `LocalPackage/Sources/HometeDomain/Setting/SettingMenuItem.swift`
  - `LocalPackage/Sources/Features/SettingFeature/SettingView.swift`
  - `LocalPackage/Sources/Features/SettingFeature/SubViews/SettingMenuItemButton.swift`
  - `LocalPackage/Sources/Features/HomeFeature/RegisterCohabitantView/CohabitantRegistrationView.swift`
  - `LocalPackage/Sources/Features/HomeFeature/HomeView/HomeView.swift` （fullScreenCover導線の参考）
  - `LocalPackage/Sources/AppRoot/ResolverImpl/RouteResolverInjection.swift` （RouteResolver注入）
  - `LocalPackage/Sources/HometeDomain/Navigation/AppRoute.swift` （`.cohabitantRegistration`）
