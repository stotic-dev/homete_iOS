# グループメンバー一覧表示機能 実装方針

> 関連Issue: [#154 グループメンバーの一覧画面](https://github.com/stotic-dev/homete_iOS/issues/154)
> ブランチ: `feat/group_member_list`

## ステータス

- [ ] 設計確定（未決定事項を確定する）
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

### 依存関係

```
SettingView
  ├── @Environment(\.cohabitantMembers): CohabitantMemberList  ← AppTabViewでセット済み
  └── @Environment(\.loginContext): LoginContext              ← 自分のID取得用
        ↓ 渡す
GroupMemberListView（新規 SubView）
  └── members: [CohabitantMember]  ← 自分を除外した配列
```

### データの流れ

1. `AppTabView` が `CohabitantStore` を保持し、`\.cohabitantMembers` Environment に注入（既存）
2. `SettingView` が Environment から `CohabitantMemberList` と `LoginContext` を取得
3. `cohabitantMembers.value` から自分（`loginContext.account.id`）を除外して `GroupMemberListView` に渡す
4. `GroupMemberListView` はメンバー名を縦並びで表示。0件時は `EmptyView` を返す

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規View | `LocalPackage/Sources/Features/SettingFeature/SubViews/GroupMemberListView.swift` | メンバー名一覧の表示コンポーネント |
| 修正View | `LocalPackage/Sources/Features/SettingFeature/SettingView.swift` | ユーザー名直下に `GroupMemberListView` を配置 |

## 未決定事項

### 1. 「自分以外」のメンバー取得方法

`CohabitantMemberList.value` は `ownId` を内部に持つが外部から取得できず、`value` プロパティは「自分 + 他メンバー」を返す仕様（自分がメンバーに含まれない場合は空配列）。

| 案 | 内容 | メリット | デメリット |
|---|---|---|---|
| **案A** | `CohabitantMemberList` に `var others: [CohabitantMember]` を追加 | 責務が綺麗。他Featureから再利用可 | HometeDomainに変更が入る |
| **案B** | SettingView内で `value.filter { $0.id != loginContext.account.id }` | HometeDomain無変更 | フィルタロジックが View 側に漏れる |

→ **要ユーザー判断**

### 2. SubView の粒度

| 案 | 内容 |
|---|---|
| **案X** | `GroupMemberListView` のみ作成（行表示はView内で完結） |
| **案Y** | `GroupMemberListView` + `GroupMemberRow` を分離（SettingMenuItemButton と同粒度） |

→ **要ユーザー判断**

## タスク

### Phase 1: 設計確定

- [ ] 未決定事項1（自分以外の取得方法）を確定する
- [ ] 未決定事項2（SubView粒度）を確定する

### Phase 2: 実装

- [ ] 案A採用時: `CohabitantMemberList` に `others` API を追加
- [ ] 案A採用時: `HometeDomainTests/CohabitantMemberListTests` を追加
- [ ] `GroupMemberListView` を新規作成
- [ ] `GroupMemberListView` の Preview を複数バリエーション追加（複数件 / 1件 / 0件）
- [ ] 案Y採用時: `GroupMemberRow` を新規作成 + Preview
- [ ] `SettingView` に `@Environment(\.cohabitantMembers)` / `@Environment(\.loginContext)` を追加
- [ ] `SettingView` のユーザー名直下に `GroupMemberListView` を配置
- [ ] `SettingView` の Preview に環境値（`cohabitantMembers` / `loginContext`）をセット

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
