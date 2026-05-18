# グループメンバー一覧表示機能 実装方針

> 関連Issue: [#154 グループメンバーの一覧画面](https://github.com/stotic-dev/homete_iOS/issues/154)
> ブランチ: `feat/group_member_list`

## ステータス

- [x] 設計確定（未決定事項を確定する）
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

設定画面（`SettingView`）に、ログイン中ユーザーが所属している家族グループ（Cohabitant）のメンバー一覧を表示する。
ユーザーが「自分以外に誰が同じグループに参加しているか」を確認できるようにすることが目的。

## 要件

### 機能要件

- 設定画面のユーザー名の直下にメンバー一覧をインライン表示する（別画面遷移はしない）
- 各メンバーは**ユーザー名**を表示する
- **自分自身は一覧に含めない**（自分のユーザー名は既に画面上部に表示済みのため）
- メンバーが0人（同居人未登録）の場合は**空表示**にする
  - TODO: 将来的にグループ参加への導線を別途用意する想定（本Issue対象外）
- メンバー行のタップ時の挙動は**なし**

### 非機能要件 / 制約

- 既存のドメインモデルは流用する（`CohabitantStore` / `CohabitantMember` / `CohabitantMemberList`）
- SettingFeature固有のドメインモデルが必要になった場合のみ `SettingFeature` 内で定義する
- ユニットテスト・スナップショットテストは既存パターンに従う

## 設計方針

### 確定事項

#### 1. `CohabitantContext` を新設してアプリ全体にDIする

「グループID + メンバー一覧 + 自分以外（others）」を1つのコンテキストモデルに集約し、Environment 経由でアプリ全体にDIする。
個別の `cohabitantMembers` Environment（現状）からの置き換えを行う。

**新規モデル**: `LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantContext.swift`

```swift
public struct CohabitantContext: Sendable, Equatable {
    public let id: String                       // グループID（cohabitantId）
    public let members: CohabitantMemberList    // 自分含むメンバー一覧
    public var others: [CohabitantMember] { ... } // 自分を除いたメンバー
}
```

- `others` は `CohabitantMemberList.value` から `ownId` を除外したものを返す
- 既存の `CohabitantMemberList` 内部の `ownId` を活用するため、`CohabitantMemberList` 側に「自分以外を返すロジック」を持たせ、`CohabitantContext.others` から委譲する形でも良い（実装時に判断）

#### 2. Environment注入箇所

現状 `AppTabView` で `\.cohabitantMembers` に `CohabitantMemberList` を注入している（既存）。
これを `\.cohabitantContext` のような形に置き換え、`CohabitantContext` 全体を渡すよう変更する。

既存の参照箇所（要修正）:
- `LocalPackage/Sources/AppRoot/AppTabView.swift` - 注入箇所
- `LocalPackage/Sources/Features/ContributionFeature/View/Summary/ContributionSummaryComponent.swift`
- `LocalPackage/Sources/Features/ContributionFeature/View/Analytics/ContributionAnalyticsScreen.swift`

#### 3. SubViewの粒度

**案Y採用**: `GroupMemberListView` + `GroupMemberRow` に分離する。
`SettingMenuItemButton` と同じ粒度で、行コンポーネントを独立Viewにすることで再利用性とPreview粒度を確保する。

### 依存関係

```
AppTabView
  └── @State cohabitantStore: CohabitantStore
        └── members: CohabitantMemberList
  └── 環境注入: \.cohabitantContext = CohabitantContext(id, members)

SettingView
  ├── @Environment(\.cohabitantContext): CohabitantContext
  └── GroupMemberListView(members: cohabitantContext.others)
        └── ForEach { GroupMemberRow(member:) }
```

### データの流れ

1. `AppTabView` が `CohabitantStore` を保持（既存）
2. `AppTabView` が `CohabitantContext(id: cohabitantId, members: store.members)` を構築し、`\.cohabitantContext` Environment に注入
3. `SettingView` が Environment から `CohabitantContext` を取得し、`others` を `GroupMemberListView` に渡す
4. `GroupMemberListView` は `ForEach` でメンバーを並べて `GroupMemberRow` に渡す。0件時は `EmptyView`
5. `GroupMemberRow` はメンバー1人分のユーザー名を表示

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantContext.swift` | グループID・メンバー一覧・othersを保持 |
| 新規View | `LocalPackage/Sources/Features/SettingFeature/SubViews/GroupMemberListView.swift` | メンバー一覧の表示コンポーネント |
| 新規View | `LocalPackage/Sources/Features/SettingFeature/SubViews/GroupMemberRow.swift` | メンバー1行の表示コンポーネント |
| 修正View | `LocalPackage/Sources/Features/SettingFeature/SettingView.swift` | ユーザー名直下に `GroupMemberListView` を配置 |
| 修正View | `LocalPackage/Sources/AppRoot/AppTabView.swift` | `\.cohabitantContext` Environment注入に置き換え |
| 修正View | `ContributionFeature` 配下の `\.cohabitantMembers` 参照箇所 | `\.cohabitantContext.members` に置き換え |

## タスク

### Phase 1: 設計確定

- [x] 未決定事項1（自分以外の取得方法）を確定する → `CohabitantContext` を新設しEnvironment注入、`others` を提供
- [x] 未決定事項2（SubView粒度）を確定する → 案Y（List + Row 分離）

### Phase 2: 実装

- [ ] `CohabitantContext` ドメインモデルを新規作成（id / members / others）
- [ ] `CohabitantContext` 用のEnvironmentValue（`\.cohabitantContext`）を定義
- [ ] `HometeDomainTests` に `CohabitantContext` のテストを追加
- [ ] `AppTabView` で `\.cohabitantContext` の注入に置き換え
- [ ] `ContributionFeature` 配下の `\.cohabitantMembers` 参照箇所を `\.cohabitantContext.members` に置き換え
- [ ] 既存の `\.cohabitantMembers` Environment を撤去（または `CohabitantContext` 経由で参照する形に統一）
- [ ] `GroupMemberRow` を新規作成 + Preview
- [ ] `GroupMemberListView` を新規作成 + Preview（複数件 / 1件 / 0件）
- [ ] `SettingView` に `@Environment(\.cohabitantContext)` を追加
- [ ] `SettingView` のユーザー名直下に `GroupMemberListView` を配置
- [ ] `SettingView` の Preview に `\.cohabitantContext` をセット

### Phase 3: 検証

- [ ] `swift build` でビルド通過
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] ユニットテスト実行（追加分含む）通過
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/154
- 既存ドメインモデル:
  - `LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantMember.swift`
  - `LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantMemberList.swift`
  - `LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantStore.swift`
- 既存利用箇所（参考）:
  - `LocalPackage/Sources/AppRoot/AppTabView.swift` （`\.cohabitantMembers` 環境注入）
  - `LocalPackage/Sources/Features/ContributionFeature/View/Summary/ContributionSummaryComponent.swift`
