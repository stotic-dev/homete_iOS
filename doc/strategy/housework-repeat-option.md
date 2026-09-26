# 家事登録の繰り返し設定 実装方針

> 関連Issue: [#281 家事登録に繰り返しの項目が欲しい](https://github.com/stotic-dev/homete_iOS/issues/281)
> ブランチ: `feat/housework-repeat-option`（スタックPRの土台。分割は「PR分割」を参照）
> 毎月の家事の保存方式は [ADR-0020](../adr/0020-monthly-housework-template-items.md)、テンプレートの前提は [housework_template.md](housework_template.md) / [ADR-0003](../adr/0003-housework-template-virtual-view.md) を参照。

## ステータス

- [x] 要件確定
- [x] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

家事を登録するときに「毎週◯曜日」「毎月◯日」「毎月第N◯曜日」の繰り返しを指定できるようにし、指定した家事は該当日に自動で家事一覧に並ぶようにする。
「毎週◯曜日」は既存の週間テンプレートで実現できているが、テンプレート画面を開かないと設定できず、毎月の繰り返しには対応していない。登録画面から直接テンプレートに登録できるようにし、テンプレートに毎月の繰り返しを追加する。

## 要件

### 機能要件

**家事登録画面（`RegisterHouseworkView`）**

- 「くり返し」の設定欄を追加する。選べるのは次の4種類で、初期値は「しない」
  | 種類 | 追加で選ぶもの |
  |---|---|
  | しない | なし（今と同じ単発の登録） |
  | 毎週 | 曜日（複数選択、1つ以上） |
  | 毎月（日付） | 日（1〜31） |
  | 毎月（曜日） | 第N（第1〜第4・最終）と曜日（1つ） |
- 「しない」以外で登録すると、テンプレートに家事を追加するだけで、`Houseworks` には書き込まない
  - 登録元の日付（ボードで選んでいた日）が繰り返しの対象外の日だった場合や、過去の日だった場合は、その日には表示されない（`updatedAt` = 登録時刻のため）
  - そのことが伝わるように、設定欄の下に「今日以降の該当する日に表示されます」と表示する
- テンプレートがまだ作られていなければ、登録時に自動で作成する（テンプレート画面の「テンプレートを作成する」と同じ処理）
- 登録画面はホームの「今日の家事」と家事ボードの2箇所から開かれる。どちらから開いても同じように設定できる
- 重複チェック（「"◯◯"は既に登録されています」）は、「しない」のときだけ今までどおり行う

**毎月の繰り返し**

- 「毎月◯日」で29〜31日を指定した家事は、その日がない月は月末に表示する（例: 31日指定 → 2月は28日（うるう年は29日）、4月は30日）
- 「毎月第N◯曜日」のNは第1〜第4と「最終」から選ぶ（第5週はある月とない月があるので選べないようにし、その代わりに「最終」を用意する）
- 表示の仕組みは毎週の家事と同じ（[ADR-0003](../adr/0003-housework-template-virtual-view.md)の仮想ビュー方式）
  - 家事ボード・ホームの今日の家事・未完了の家事一覧に、未完了として表示する
  - 状態を変えた（完了報告した）時点で初めて `Houseworks` に書き込む
  - `updatedAt` より前の日には表示しない

**テンプレート画面（`HouseworkTemplateView`）**

- 曜日ごとのリストの下に「毎月」のセクションを追加し、毎月の家事を一覧表示する
  - 並び順は「◯日」を日付順で先に、そのあとに「第N◯曜日」を第N→曜日の順で並べる
  - 各行には家事名・ポイント・繰り返しの内容（「毎月25日」「毎月第2水曜日」）を表示する
- 家事の追加・編集モーダル（`HouseworkTemplateItemEditModal`）で、「毎週 / 毎月（日付） / 毎月（曜日）」を切り替えられるようにする
  - 既存の家事を編集で別の種類に変えた場合は、元の保存先から消して新しい保存先に追加する（家事のIDは変えない）
- 毎月の家事も、長押しメニューの「編集」「削除」と、タップでの詳細画面への遷移に対応する
- 曜日間のドラッグ&ドロップは毎週の家事だけの機能とし、毎月の家事は対象にしない

### 非機能要件 / 制約

- 既存の `Days` のデータ構造は変えず、データ移行もしない（[ADR-0020](../adr/0020-monthly-housework-template-items.md)）
- テンプレート機能は無料で提供している機能（[premium_plan.md](../premium_plan.md)）なので、繰り返し設定もプランで制限しない
- 登録画面から書き込むときも、テンプレートの `version` を上げる。こうしておくと、他のメンバーがテンプレートを編集中でも、そのメンバーの保存は既存の仕組みでコンフリクトとして検知されるので、登録した家事が上書きで消えない
- 旧バージョンのアプリは `MonthlyItems` を読まないので、アップデートしていないメンバーには毎月の家事が表示されない。`Days` は壊さないので、それ以外の影響はない
- 日付の判定（毎月◯日の月末への寄せ、第N・最終週の判定）はドメイン層の値型に置き、`Calendar` を引数で受け取ってユニットテストする

## 設計方針

### 1. ドメインモデル

`HometeDomain/Cohabitant/HouseworkTemplate/` に毎月の家事を表す型を追加する。

```swift
/// 毎月の繰り返しルール
public enum MonthlyRecurrenceRule: Codable, Sendable, Equatable, Hashable {
    /// 毎月◯日（1〜31。その日がない月は月末）
    case dayOfMonth(Int)
    /// 毎月第N◯曜日
    case weekdayOfMonth(ordinal: WeekOrdinal, dayOfWeek: DayOfWeek)

    /// 指定日がこのルールに当てはまるか
    public func matches(_ date: Date, calendar: Calendar) -> Bool
}

public enum WeekOrdinal: Int, Codable, Sendable, CaseIterable {
    case first = 1, second, third, fourth
    case last = -1
}

/// 毎月繰り返すテンプレートの家事
public struct HouseworkTemplateMonthlyItem: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let item: HouseworkTemplateItem   // id / title / point / updatedAt は毎週と共通
    public let rule: MonthlyRecurrenceRule
}
```

Firestore上の形（`rule.type` / `day` / `ordinal` / `dayOfWeek`）は[ADR-0020](../adr/0020-monthly-housework-template-items.md)のとおり。`Codable` の実装で変換する。

### 2. 表示のマージ処理

今は `HouseworkTemplateContext.templateOfDay(by:calendar:)` がその曜日の `HouseworkTemplateDay` を返し、`HouseworkTemplateDay.applyTemplate(...)` が仮想の家事を足している。これを「その日に表示するテンプレートの家事の一覧」を返す形に一般化する。

```swift
public struct HouseworkTemplateContext {
    public let metadata: HouseworkTemplateMeta?
    public let houseworkTemplate: [HouseworkTemplateDay]
    public let monthlyItems: [HouseworkTemplateMonthlyItem]   // 追加

    /// 指定日に表示するテンプレートの家事（毎週 + 毎月）
    public func templateItems(on date: Date, calendar: Calendar) -> [HouseworkTemplateItem]
}
```

- 重複除去・`updatedAt` の判定は `applyTemplate` のロジックをそのまま使い、入力を `[HouseworkTemplateItem]` にする（`HouseworkTemplateDay` のメソッドから、アイテム配列を受け取る関数に切り出す）
- 呼び出し側（`HouseworkBoardList` / `TodayHouseworkSummary` / `IncompleteHouseworkListView` / `HouseworkBoardScreen` / `TodayHouseworkSummaryComponent`）は `templateOfDay` から `templateItems(on:calendar:)` に置き換える

### 3. Client / Firestore

`HouseworkTemplateClient` を次のように拡張する（実装は `AppRoot/Dependency/Impl/ImplHouseworkTemplateClient.swift`、パスは `CollectionPath` に追加）。

| 追加・変更 | 内容 |
|---|---|
| `fetchMonthlyItems` / `addMonthlyItemsSnapshotListener` | `MonthlyItems` の取得と監視 |
| `updateDays` → `updateTemplate` | 毎週（変更があった `Days`）と毎月（`MonthlyItems` の upsert・delete）を、1回のトランザクションで `version` を確認して書き込む |
| `appendItems`（新規） | 登録画面用。トランザクションで最新の `Days` を読んで家事を追加し（毎月なら `MonthlyItems` に1件追加し）、`version + 1` する。呼び出し側が `currentVersion` を持っている必要はない |

`HouseworkTemplateListStore` は `MonthlyItems` も監視して `context` に含める。保存（`saveDays`）は毎月の家事の変更も受け取る形にし、Analyticsの `create` / `edit` / `delete` 判定（`itemChanges`）でも毎月の家事を比較対象に入れる。

### 4. セキュリティルール

`firebase/firestore.rules` の `HouseworkTemplates` の下に追加し、`firebase/functions/test/rules/firestore.rules.test.ts` にメンバー・非メンバーのテストを足す。アカウント削除時はテンプレートをサブコレクションごと再帰的に削除しているので、`deleteUserData` の変更は不要（E2Eテストに `MonthlyItems` の削除確認を足す）。

```
match /MonthlyItems/{itemId} {
  allow read, write: if isCohabitantMember(cohabitantId);
}
```

### 5. テンプレート画面

- `HouseworkTemplateDraft`（編集中のローカル状態）に毎月の家事を持たせる
- 「毎月」セクションは曜日リストと同じ見た目の行を使い、繰り返し内容のラベルだけ足す
- 追加・編集モーダルの曜日選択（`WeekdaySelector`）の上に、繰り返しの種類を切り替えるセグメントを置く。「毎月（日付）」は日付のピッカー、「毎月（曜日）」は第Nのピッカー＋曜日の単一選択に切り替える
- 繰り返し設定のUIは登録画面でも使うので、`HouseworkTemplateFeature` 内ではなく `HometeUI` に共通コンポーネント（`RecurrenceSelector`（仮））として置く。`HouseworkFeature` から `HouseworkTemplateFeature` への直接依存を作らないため
  - コンポーネントは選択値のBindingを受け取って描画するだけにし、「決定できるか」の判定は呼び出し側に置く（[presentation-logic-placement](../../.claude/rules/presentation-logic-placement.md)）

### 6. 家事登録画面

- `RegisterHouseworkView` に `RecurrenceSelector` を追加する。選択値は `enum HouseworkRecurrence { case none, weekly(Set<DayOfWeek>), monthly(MonthlyRecurrenceRule) }` で持つ
- 「登録する」ボタンの処理を分ける
  - `none`: 今までどおり `HouseworkListStore.register`
  - それ以外: `HouseworkTemplateListStore` にテンプレートの作成（なければ）と `appendItems` を行わせる
- `HouseworkTemplateListStore` は2つの呼び出し元（`HomeView` / `HouseworkBoardScreen`）でOptionalで持っているので、`RegisterHouseworkView` にも environment 経由で渡す。`nil`（未構成）のときは繰り返しの設定欄を出さない
- 登録画面の入力項目が増えて縦に長くなるので、入力履歴（`entryHistoryContent`）とのレイアウトを見直す（スクロールできるようにする）

### 7. Analytics

[ADR-0009](../adr/0009-analytics-event-parameter-design.md)に従い、イベントは増やさず `housework_template` にパラメータを足す。

| パラメータ | 値 | 説明 |
|---|---|---|
| `step`（追加） | `template` / `register` | テンプレート画面で保存したか、登録画面から追加したか |
| `recurrence`（追加） | `weekly` / `monthly_day` / `monthly_weekday` | どの繰り返しか（`create` / `edit` のとき） |

登録画面から追加したときは `action: create, step: register` を送る。テンプレートを自動で作成したときは、テンプレート画面と同じく `apply` も送る。`doc/analytics_events.md` も同じPRで更新する。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/MonthlyRecurrenceRule.swift` | 毎月の繰り返しルールと日付の判定 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkTemplateMonthlyItem.swift` | 毎月の家事 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkRecurrence.swift` | 登録画面で選ぶ繰り返し（しない / 毎週 / 毎月） |
| 修正ドメイン | `.../HouseworkTemplate/HouseworkTemplateContext.swift` | `monthlyItems` と `templateItems(on:calendar:)` |
| 修正ドメイン | `.../HouseworkTemplate/HouseworkTemplateDay.swift` | `applyTemplate` をアイテム配列で使えるように切り出す |
| 修正ドメイン | `.../HouseworkTemplate/HouseworkTemplateListStore.swift` | `MonthlyItems` の監視、保存、`appendItems` |
| 修正Client | `LocalPackage/Sources/HometeDomain/Dependencies/HouseworkTemplateClient.swift` | 毎月の家事の取得・監視、`updateTemplate`、`appendItems` |
| 修正Impl | `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplHouseworkTemplateClient.swift` | 上記のFirestore実装 |
| 修正Analytics | `LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkTemplateAnalyticsAction.swift` | `step` / `recurrence` パラメータ |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkBoardList.swift` / `TodayHouseworkSummary.swift` ほか | マージ処理の呼び出しを置き換え |
| 新規共通UI | `LocalPackage/Sources/HometeUI/Components/Picker/RecurrenceSelector.swift` | 繰り返しの種類と値を選ぶUI |
| 修正View | `LocalPackage/Sources/Features/HouseworkTemplateFeature/Template/HouseworkTemplateView.swift` | 「毎月」セクション |
| 修正View | `LocalPackage/Sources/Features/HouseworkTemplateFeature/EditModal/HouseworkTemplateItemEditModal.swift` | 繰り返しの種類の切り替え |
| 修正Model | `LocalPackage/Sources/Features/HouseworkTemplateFeature/Model/HouseworkTemplateDraft.swift` | 毎月の家事の編集状態 |
| 修正View | `LocalPackage/Sources/Features/HouseworkTemplateFeature/Detail/HouseworkTemplateItemDetailView.swift` | 繰り返し内容の表示 |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/RegisterHouseworkView/RegisterHouseworkView.swift` | 繰り返しの設定欄と登録処理の分岐 |
| 修正ルール | `firebase/firestore.rules` / `firebase/functions/test/rules/firestore.rules.test.ts` | `MonthlyItems` |
| 修正ドキュメント | `doc/analytics_events.md` / `doc/strategy/housework_template.md` | パラメータ追加、毎月の家事への参照 |

## PR分割（スタックPR）

変更が大きいので、以下の順に積み、下から順にマージする。**毎月の家事を書き込めるようになるのは、読み取り・表示ができるようになった後**になるよう並べている（途中でリリースされても、表示できない家事が作られることはない）。

| # | ブランチ（予定） | ベース | 内容 |
|---|---|---|---|
| 1 | `feat/housework-repeat-option` | `main` | 方針ドキュメント・ADR-0020、Firestoreルール（`MonthlyItems`）とルールテスト |
| 2 | `feat/housework-repeat-option-domain` | #1 | ドメインモデル、日付判定、Client/Impl（取得・監視・`updateTemplate`・`appendItems`）、`HouseworkTemplateListStore`、ユニットテスト |
| 3 | `feat/housework-repeat-option-display` | #2 | 家事ボード・今日の家事・未完了一覧に毎月の家事を表示する（マージ処理の一般化） |
| 4 | `feat/housework-repeat-option-template-ui` | #3 | テンプレート画面の「毎月」セクション、編集モーダル・詳細画面、`RecurrenceSelector`、Analytics（`step: template` / `recurrence`） |
| 5 | `feat/housework-repeat-option-register` | #4 | 登録画面の繰り返し設定、Analytics（`step: register`）、`analytics_events.md` の更新 |

- 下のPRがマージされたら、上のPRのベースを `main` に付け替える（`gh pr edit --base main`）
- 下のPRにレビュー指摘の修正が入ったら、上のブランチを順にrebaseする

## タスク

### Phase 1: 設計確定

- [x] 登録画面からは曜日などを選んでテンプレートに直接追加する（テンプレート画面への導線だけにはしない）
- [x] 毎月の繰り返しも今回まとめて対応する
- [x] 毎月は「◯日」と「第N◯曜日」の両方に対応する
- [x] 29〜31日の指定は、その日がない月は月末に表示する
- [x] 繰り返しを設定して登録したときは、登録元の日付に単発では登録しない（繰り返しに任せる）
- [x] 毎月の家事はテンプレート画面に「毎月」セクションを足して管理する
- [x] 毎月の家事の保存方式（[ADR-0020](../adr/0020-monthly-housework-template-items.md)）
- [x] 第N◯曜日のNは第1〜第4と「最終」にする
- [x] ADR-0020のレビュー（提案済 → 承認済）

### Phase 2: 実装

**PR #1**
- [ ] `firebase/firestore.rules` に `MonthlyItems` を追加
- [ ] ルールテストにメンバー・非メンバーの読み書きを追加
- [ ] `deleteUserData` のE2Eテストに `MonthlyItems` の削除確認を追加

**PR #2**
- [ ] `MonthlyRecurrenceRule` / `WeekOrdinal` / `HouseworkTemplateMonthlyItem` / `HouseworkRecurrence` を追加
- [ ] 日付判定のユニットテスト（31日指定の2月・4月、うるう年、第1週・最終週、月初が各曜日のケース）
- [ ] `HouseworkTemplateClient` に取得・監視・`updateTemplate`・`appendItems` を追加し、Implを実装
- [ ] `HouseworkTemplateListStore` の `MonthlyItems` 監視・保存・`appendItems`・変更検知（`itemChanges`）とテスト

**PR #3**
- [ ] `HouseworkTemplateContext.templateItems(on:calendar:)` とテスト
- [ ] `applyTemplate` をアイテム配列で使えるように切り出す
- [ ] `HouseworkBoardList` / `TodayHouseworkSummary` / `IncompleteHouseworkListView` ほか呼び出し側の置き換えとテスト

**PR #4**
- [ ] `RecurrenceSelector` とPreview（種類ごとのバリエーション）
- [ ] `HouseworkTemplateDraft` に毎月の家事を追加
- [ ] テンプレート画面の「毎月」セクションとPreview
- [ ] 編集モーダル・詳細画面の対応とPreview
- [ ] Analyticsの `step` / `recurrence` パラメータ

**PR #5**
- [ ] `RegisterHouseworkView` に繰り返しの設定欄と登録処理の分岐を追加
- [ ] 呼び出し元2箇所から `HouseworkTemplateListStore` を渡す
- [ ] Previewの追加（繰り返しなし / 毎週 / 毎月）
- [ ] `doc/analytics_events.md` を更新

### Phase 3: 検証

- [ ] `swift build` でビルド通過
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] ユニットテスト実行（追加分含む）通過
- [ ] `npm run test:rules` / `npm run test:e2e` 通過（PR #1）
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] 実機/シミュレータで動作確認（登録画面から毎週・毎月を登録 → 家事ボードの該当日に出る、テンプレート画面で編集・削除できる）

### Phase 4: PR

- [ ] スタックPRを#1から順に作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/281
- 既存実装（参考）:
  - `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkTemplateDay.swift`（仮想の家事を足す処理）
  - `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkTemplateListStore.swift`
  - `LocalPackage/Sources/Features/HouseworkTemplateFeature/Model/HouseworkTemplateEditStore.swift`（楽観的ロック・Presence）
  - `LocalPackage/Sources/Features/HouseworkTemplateFeature/EditModal/SubViews/WeekdaySelector.swift`
  - `LocalPackage/Sources/Features/HouseworkFeature/RegisterHouseworkView/RegisterHouseworkView.swift`
