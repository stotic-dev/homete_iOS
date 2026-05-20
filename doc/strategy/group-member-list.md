# グループメンバー一覧表示機能 実装方針

> 関連Issue: [#154 グループメンバーの一覧画面](https://github.com/stotic-dev/homete_iOS/issues/154)
> ブランチ: `feat/group_member_list`

## ステータス

- [x] 設計確定（未決定事項を確定する）
- [x] 実装完了
- [x] テスト追加完了
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

#### 1. 既存の `CohabitantMemberList` を流用する

既存の `\.cohabitantMembers` Environment（`CohabitantMemberList` 型）をそのまま使う。
`CohabitantMemberList` に `others`（自分を除いたメンバー一覧）プロパティを追加し、`SettingView` から参照する。

- `others` は `CohabitantMemberList._value` から `ownId` を除外し、ユーザーID昇順でソートして返す
- 既存の `value` プロパティは `[own] + others` に委譲する形で再構成

#### 2. Environment注入箇所

既存どおり `AppTabView` で `\.cohabitantMembers` に `CohabitantMemberList` を注入する（変更なし）。

#### 3. SubViewの粒度

**案Y採用**: `GroupMemberListView` + `GroupMemberRow` に分離する。
`SettingMenuItemButton` と同じ粒度で、行コンポーネントを独立Viewにすることで再利用性とPreview粒度を確保する。

### 依存関係

```
AppTabView
  └── @State cohabitantStore: CohabitantStore
        └── members: CohabitantMemberList
  └── 環境注入: \.cohabitantMembers = store.members

SettingView
  ├── @Environment(\.cohabitantMembers): CohabitantMemberList
  └── GroupMemberListView(members: cohabitantMembers.others)
        └── ForEach { GroupMemberRow(member:) }
```

### データの流れ

1. `AppTabView` が `CohabitantStore` を保持（既存）
2. `AppTabView` が `store.members` を `\.cohabitantMembers` Environment に注入（既存どおり）
3. `SettingView` が Environment から `CohabitantMemberList` を取得し、`others` を `GroupMemberListView` に渡す
4. `GroupMemberListView` は `ForEach` でメンバーを並べて `GroupMemberRow` に渡す。0件時は `EmptyView`
5. `GroupMemberRow` はメンバー1人分のユーザー名を表示

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantMemberList.swift` | `others` プロパティを追加 |
| 新規View | `LocalPackage/Sources/Features/SettingFeature/SubViews/GroupMemberListView.swift` | メンバー一覧の表示コンポーネント |
| 新規View | `LocalPackage/Sources/Features/SettingFeature/SubViews/GroupMemberRow.swift` | メンバー1行の表示コンポーネント |
| 修正View | `LocalPackage/Sources/Features/SettingFeature/SettingView.swift` | ユーザー名直下に `GroupMemberListView` を配置 |

## タスク

### Phase 1: 設計確定

- [x] 未決定事項1（自分以外の取得方法）を確定する → `CohabitantContext` を新設しEnvironment注入、`others` を提供
- [x] 未決定事項2（SubView粒度）を確定する → 案Y（List + Row 分離）

### Phase 2: 実装

- [x] `CohabitantMemberList` に `others` プロパティを追加
- [x] `GroupMemberRow` を新規作成 + Preview
- [x] `GroupMemberListView` を新規作成 + Preview（複数件 / 1件 / 0件）
- [x] `SettingView` に `@Environment(\.cohabitantMembers)` を追加
- [x] `SettingView` のユーザー名直下に `GroupMemberListView` を配置
- [x] `SettingView` の Preview に `\.cohabitantMembers` をセット

### Phase 3: 検証

- [x] `swift build` でビルド通過
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過
- [x] ユニットテスト実行（追加分含む）通過
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
