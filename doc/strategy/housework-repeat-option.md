# 家事登録の繰り返し設定 実装方針

> 関連Issue: [#281 家事登録に繰り返しの項目が欲しい](https://github.com/stotic-dev/homete_iOS/issues/281)
> ブランチ: `feat/housework-repeat-option`（スタックPRの土台。分割は「PR分割」を参照）
> 毎月の家事の保存方式は [ADR-0020](../adr/0020-monthly-housework-template-items.md)、テンプレートの前提は [housework_template.md](housework_template.md) / [ADR-0003](../adr/0003-housework-template-virtual-view.md) を参照。

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

家事を登録するときに「毎日」「毎週」「毎月」の繰り返しを指定できるようにし、指定した家事は該当日に自動で家事一覧に並ぶようにする。
「毎週◯曜日」は既存の週間テンプレートで実現できているが、テンプレート画面を開かないと設定できず、毎月の繰り返しには対応していない。登録画面から直接テンプレートに登録できるようにし、テンプレートに毎月の繰り返しを追加する。

## 要件

### 機能要件

**家事登録画面（`RegisterHouseworkView`）**

- 「くり返し」の行を追加し、メニューのピッカーで種類を選ぶ（iOSのカレンダーの「繰り返し」と同じ形）。選べるのは次の4種類で、初期値は「しない」
  | 種類 | 繰り返す日 |
  |---|---|
  | しない | なし（今と同じ単発の登録） |
  | 毎日 | 全曜日 |
  | 毎週 | 登録しようとしている日の曜日 |
  | 毎月 | 登録しようとしている日の日付 |
- 登録画面では曜日・日付を選ばせず、登録しようとしている日を起点にする。いつ表示されるかは設定欄の下に「今日以降の毎週木曜日に表示されます」のように出す
- 「しない」以外で登録すると、テンプレートに家事を追加するだけで、`Houseworks` には書き込まない
  - 登録元の日付（ボードで選んでいた日）が繰り返しの対象外の日だった場合や、過去の日だった場合は、その日には表示されない（`updatedAt` = 登録時刻のため）
- テンプレートがまだ作られていなければ、登録時に自動で作成する（テンプレート画面の「テンプレートを作成する」と同じ処理）
- 登録画面はホームの「今日の家事」と家事ボードの2箇所から開かれる。どちらから開いても同じように設定できる
- 重複チェック（「"◯◯"は既に登録されています」）は、「しない」のときだけ今までどおり行う

**毎月の繰り返し**

- 「毎月◯日」で29〜31日を指定した家事は、その日がない月は月末に表示する（例: 31日指定 → 2月は28日（うるう年は29日）、4月は30日）
- 「毎月第N◯曜日」は選択肢を絞るため今回は対応しない（ルールに種類を持たせてあるので後から足せる。[ADR-0020](../adr/0020-monthly-housework-template-items.md)）
- 表示の仕組みは毎週の家事と同じ（[ADR-0003](../adr/0003-housework-template-virtual-view.md)の仮想ビュー方式）
  - 家事ボード・ホームの今日の家事・未完了の家事一覧に、未完了として表示する
  - 状態を変えた（完了報告した）時点で初めて `Houseworks` に書き込む
  - `updatedAt` より前の日には表示しない

**テンプレート画面（`HouseworkTemplateView`）**

- 曜日ごとのリストの下に「毎月」のセクションを追加し、毎月の家事を一覧表示する
  - 並び順は日付順（同じ日付ならID順）
  - 各行には家事名・ポイント・繰り返しの内容（「毎月25日」）を表示する
- 家事の追加・編集モーダル（`HouseworkTemplateItemEditModal`）で、「毎日 / 毎週 / 毎月」をメニューのピッカーで切り替えられるようにする
  - 登録画面と違い、毎週は曜日（複数選択）、毎月は日付（1〜31）も選ぶ
  - 毎日は全曜日の毎週として保存する。全曜日に登録されている家事を編集するときは「毎日」を選んだ状態で開く
  - 既存の家事を編集で別の種類に変えた場合は、元の保存先から消して新しい保存先に追加する（家事のIDは変えない）
- 毎月の家事も、長押しメニューの「編集」「削除」と、タップでの詳細画面への遷移に対応する
- 曜日間のドラッグ&ドロップは毎週の家事だけの機能とし、毎月の家事は対象にしない

### 非機能要件 / 制約

- 既存の `Days` のデータ構造は変えず、データ移行もしない（[ADR-0020](../adr/0020-monthly-housework-template-items.md)）
- テンプレート機能は無料で提供している機能（[premium_plan.md](../premium_plan.md)）なので、繰り返し設定もプランで制限しない
- 登録画面から書き込むときも、テンプレートの `version` を上げる。こうしておくと、他のメンバーがテンプレートを編集中でも、そのメンバーの保存は既存の仕組みでコンフリクトとして検知されるので、登録した家事が上書きで消えない
- 旧バージョンのアプリは `MonthlyItems` を読まないので、アップデートしていないメンバーには毎月の家事が表示されない。`Days` は壊さないので、それ以外の影響はない
- `MonthlyItems` の取得に失敗しても（セキュリティルールが未デプロイの環境など）、`configure` は失敗扱いにしない。毎週の家事を含むテンプレート全体の表示を巻き込まないため
- **リリース手順: 本番（`prod`）の Firestore ルールを、アプリの審査提出より先にデプロイする。** 本番へのルールのデプロイは `deploy-firestore.yml` の手動実行だけなので、忘れると新しいアプリで毎月の家事を読み書きできない
- 日付の判定（毎月◯日の月末への寄せ）はドメイン層の値型に置き、`Calendar` を引数で受け取ってユニットテストする

## 設計方針

### 1. ドメインモデル

`HometeDomain/Cohabitant/HouseworkTemplate/` に毎月の家事を表す型を追加する。

```swift
/// 毎月の繰り返しルール
public enum MonthlyRecurrenceRule: Codable, Sendable, Equatable, Hashable {
    /// 毎月◯日（1〜31。その日がない月は月末）
    case dayOfMonth(Int)

    /// 指定日がこのルールに当てはまるか
    public func matches(_ date: Date, calendar: Calendar) -> Bool
}

/// 毎月繰り返すテンプレートの家事
public struct HouseworkTemplateMonthlyItem: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let item: HouseworkTemplateItem   // id / title / point / updatedAt は毎週と共通
    public let rule: MonthlyRecurrenceRule
}
```

Firestore上の形（`rule.type` / `day`）は[ADR-0020](../adr/0020-monthly-housework-template-items.md)のとおり。`Codable` の実装で変換する。

### 2. 表示のマージ処理

家事ボード・今日の家事・未完了一覧は、どれも `HouseworkTemplateContext.templateOfDay(by:calendar:)` でその日のテンプレート（`HouseworkTemplateDay?`）を取り、`HouseworkTemplateDay.applyTemplate(...)` で仮想の家事を足している。

`templateOfDay` が「その曜日の毎週の家事 + その日付に当てはまる毎月の家事」を1つの `HouseworkTemplateDay` にまとめて返すように変える。

```swift
public struct HouseworkTemplateContext {
    public let metadata: HouseworkTemplateMeta?
    public let houseworkTemplate: [HouseworkTemplateDay]
    public let monthlyItems: [HouseworkTemplateMonthlyItem]   // 追加

    /// 指定日付に表示するテンプレート（毎週 + 当てはまる毎月）。どちらも無ければ nil
    public func templateOfDay(by date: Date, calendar: Calendar) -> HouseworkTemplateDay?
}
```

- 重複除去・`updatedAt` の判定（`applyTemplate`）と、3つの呼び出し元（`HouseworkBoardScreen` / `TodayHouseworkSummaryComponent` / `IncompleteHouseworkListView`）は変更しない
- 当初は `templateItems(on:calendar:)` を新設して `applyTemplate` をアイテム配列向けに切り出す予定だったが、既存の戻り値の型のままで毎月の家事を含められるため、差分が小さいこちらを採用した

### 3. Client / Firestore

`HouseworkTemplateClient` を次のように拡張する（実装は `AppRoot/Dependency/Impl/ImplHouseworkTemplateClient.swift`、パスは `CollectionPath` に追加）。

| 追加・変更 | 内容 |
|---|---|
| `fetchMonthlyItems` / `addMonthlyItemsSnapshotListener` | `MonthlyItems` の取得と監視。解釈できないドキュメント（旧アプリが知らない種類の `rule` など）は除外する。`FirestoreService.fetch` は1件でもデコードに失敗すると全体が失敗するため、Implで `LenientDecoded` に包んで読む（リスナーは元から1件ずつ `try?` でデコードしている） |
| `updateDays` → `updateTemplate` | 書き込む内容を `HouseworkTemplateUpdate`（`days` / `upsertedMonthlyItems` / `deletedMonthlyItemIds`）で受け取り、1回のトランザクションで `version` を確認して書き込む |
| `appendItem`（新規） | 登録画面用。家事1件と `HouseworkRecurrence` を受け取り、トランザクションで最新の `Days` を読んで追記する（毎月なら `MonthlyItems` に1件追加する）。そのあと `version + 1` する。呼び出し側が `currentVersion` を持っている必要はない |

`HouseworkTemplateListStore` の変更:

- `monthlyItems` を持ち、`configure` で `Days` と一緒に取得・監視して `context` に含める
- 監視の開始・停止は `startObservingDays` / `stopObservingDays` を `startObservingItems` / `stopObservingItems` に改名し、`Days` と `MonthlyItems` をまとめて扱う
- `saveDays` → `saveTemplate(days:monthlyItems:...)`。`monthlyItems` には保存後の全件を渡し、現在の内容との差分だけを書き込む
- `appendItem(_:recurrence:templateId:cohabitantId:)` を追加する（`create` イベントを送る）
- Analyticsの `create` / `edit` / `delete` 判定（`itemChanges`）では、家事ごとの繰り返し方を `HouseworkRecurrence` で比べる。毎週→毎月の切り替えも「編集」として扱う

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
- 追加・編集モーダルでは「くり返し」の行のメニューで種類を選び、その下に毎週なら曜日選択（`WeekdaySelector`）、毎月なら日付のピッカーを出す。毎日は追加の選択なし
- 繰り返し設定のUIは登録画面でも使うので、`HouseworkTemplateFeature` 内ではなく `HometeUI` に共通コンポーネント `RecurrenceSelector` として置く。`HouseworkFeature` から `HouseworkTemplateFeature` への直接依存を作らないため
  - 曜日選択（`WeekdaySelector` / `WeekdayLabel`）も `HometeUI/Components/Weekday/` へ移す（リファクタとして先にコミット）
  - 入力状態は `HouseworkRecurrenceInput`（HometeDomain）で持つ。種類を切り替えても他の種類の入力値を失わないよう全種類の値を持ち、`recurrence` で選択中の種類の値だけを取り出す。毎日は `HouseworkRecurrence.weekly(全曜日)` にし、保存の形を増やさない
  - 曜日・日付を選ばせるかは `showsDetail` で切り替える（テンプレート画面は選ばせ、登録画面は選ばせない）
  - コンポーネントは選択値のBindingを受け取って描画するだけにし、「決定できるか」の判定は呼び出し側に置く（[presentation-logic-placement](../../.claude/rules/presentation-logic-placement.md)）
- 編集モードの「変更があるか」は、選んでいない種類の入力値ではなく、保存される繰り返し方（`recurrence`）で比べる
- `HouseworkTemplateDraft` の毎月の家事は常に表示順（同じルールならID順）で持つ。Firestoreから読んだ順（ドキュメントID順）と編集で追加した順の違いだけで、未保存の変更やコンフリクトと判定しないため

### 6. 家事登録画面

- `RegisterHouseworkView` に `RecurrenceSelector`（`showsDetail: false`）を追加する。選択値は `HouseworkRecurrenceInput` で持ち、`recurrence` が `nil` ならくり返さない。`HouseworkRecurrence` は `weekly(Set<DayOfWeek>)` / `monthly(MonthlyRecurrenceRule)` の2択で、テンプレートの家事の繰り返し方としても使う
- 「登録する」ボタンの処理を分ける
  - `nil`: 今までどおり `HouseworkListStore.register`
  - それ以外: `HouseworkTemplateListStore` にテンプレートの作成（なければ）と `appendItem` を行わせる
- `HouseworkTemplateListStore` は2つの呼び出し元（`HomeView` / `HouseworkBoardScreen`）で既に environment に入っているので、`RegisterHouseworkView` は `@Environment(HouseworkTemplateListStore.self) var ...: HouseworkTemplateListStore?` で受け取る。`nil`（未構成）のときは繰り返しの設定欄を出さない
- 毎週・毎月の曜日・日付は、登録しようとしている日の曜日・日付にする（画面では変えられない）
- テンプレートが無いグループでは、`appendItemCreatingTemplateIfNeeded` がテンプレートを作成し、その場で選択して `Days` / `MonthlyItems` の監視を始めてから追加する（既存の「テンプレート作成を検知する監視」は監視の開始までは行わないため、そのままだと登録した家事が表示されない）
- 繰り返しの設定欄は、テンプレートの読み込みが終わっている（`loadState == .loaded`）ときだけ出す。Storeは `configure` の完了を待たずに作られるので、読み込み中・失敗時は `selectedTemplateId == nil` でもテンプレートが無いとは限らず、重複して作成してしまうため（Store側でも `HouseworkTemplateError.notLoaded` で止める）
- `startObservingItems` は、呼ばれるたびに既存の監視を解除してから開始し直す（呼び出し箇所が増えたため、二重監視を防ぐ）
- 入力履歴は `List` のまま、残りの高さの中でスクロールする

### 7. Analytics

[ADR-0009](../adr/0009-analytics-event-parameter-design.md)に従い、イベントは増やさず `housework_template` にパラメータを足す（PR #5でまとめて対応）。

| パラメータ | 値 | 説明 |
|---|---|---|
| `step`（追加、`create`のみ） | `template` / `register` | テンプレート画面で保存したか、登録画面から追加したか |
| `recurrence`（追加、`create` / `edit`のみ） | `daily` / `weekly` / `monthly` | 追加・編集後の繰り返し方（全曜日の毎週は `daily`） |

登録画面から追加したときは `action: create, step: register` を送る。テンプレートを自動で作成したときは、テンプレート画面と同じく `apply` も送る。繰り返しを設定した登録では `Houseworks` に書き込まないので、`housework` イベントの `register` は送らない。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/MonthlyRecurrenceRule.swift` | 毎月の繰り返しルールと日付の判定 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkTemplateMonthlyItem.swift` | 毎月の家事 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkRecurrence.swift` | 家事の繰り返し方（毎週 / 毎月。毎日は全曜日の毎週） |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkTemplateUpdate.swift` | 保存で書き込む内容 |
| 修正ドメイン | `.../HouseworkTemplate/HouseworkTemplateContext.swift` | `monthlyItems` を持ち、`templateOfDay` で毎月の家事も返す |
| 修正ドメイン | `.../HouseworkTemplate/HouseworkTemplateListStore.swift` | `MonthlyItems` の監視、`saveTemplate`、`appendItem` |
| 修正Client | `LocalPackage/Sources/HometeDomain/Dependencies/HouseworkTemplateClient.swift` | 毎月の家事の取得・監視、`updateTemplate`、`appendItem` |
| 修正Impl | `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplHouseworkTemplateClient.swift` | 上記のFirestore実装 |
| 修正Analytics | `LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkTemplateAnalyticsAction.swift` | `step` / `recurrence` パラメータ |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkRecurrenceInput.swift` | 繰り返しの入力状態 |
| 移動UI | `LocalPackage/Sources/HometeUI/Components/Weekday/` | `WeekdaySelector` / `WeekdayLabel`（HouseworkTemplateFeatureから移動） |
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
| 2 | `feat/housework-repeat-option-domain` | #1 | ドメインモデル、日付判定、Client/Impl（取得・監視・`updateTemplate`・`appendItem`）、`HouseworkTemplateListStore`、ユニットテスト |
| 3 | `feat/housework-repeat-option-display` | #2 | 家事ボード・今日の家事・未完了一覧に毎月の家事を表示する（マージ処理の一般化） |
| 4 | `feat/housework-repeat-option-template-ui` | #3 | テンプレート画面の「毎月」セクション、編集モーダル・詳細画面、`RecurrenceSelector` |
| 5 | `feat/housework-repeat-option-register` | #4 | Analytics（`step` / `recurrence`）、登録画面の繰り返し設定、`analytics_events.md` の更新 |

- 下のPRがマージされたら、上のPRのベースを `main` に付け替える（`gh pr edit --base main`）
- 下のPRにレビュー指摘の修正が入ったら、上のブランチを順にrebaseする

## タスク

### Phase 1: 設計確定

- [x] 登録画面からは曜日などを選んでテンプレートに直接追加する（テンプレート画面への導線だけにはしない）
- [x] 毎月の繰り返しも今回まとめて対応する
- [x] 毎月は「◯日」だけに対応する（当初は「第N◯曜日」も対応予定だったが、選択肢を絞るため見送った）
- [x] 29〜31日の指定は、その日がない月は月末に表示する
- [x] 繰り返しを設定して登録したときは、登録元の日付に単発では登録しない（繰り返しに任せる）
- [x] 毎月の家事はテンプレート画面に「毎月」セクションを足して管理する
- [x] 毎月の家事の保存方式（[ADR-0020](../adr/0020-monthly-housework-template-items.md)）
- [x] 繰り返しの種類はメニューのピッカーで選ぶ。「毎日」も選べるようにする
- [x] 登録画面では曜日・日付を選ばせず、登録しようとしている日を起点にする（テンプレート画面では選ばせる）
- [x] ADR-0020のレビュー（提案済 → 承認済）

### Phase 2: 実装

**PR #1**
- [x] `firebase/firestore.rules` に `MonthlyItems` を追加
- [x] ルールテストにメンバー・非メンバーの読み書きを追加
- [x] `deleteUserData` のE2Eテストに `MonthlyItems` の削除確認・残存確認を追加

**PR #2**
- [x] `MonthlyRecurrenceRule` / `HouseworkTemplateMonthlyItem` / `HouseworkRecurrence` / `HouseworkTemplateUpdate` を追加
- [x] 日付判定のユニットテスト（31日指定の2月・3月・4月、うるう年）とCodableのテスト
- [x] `HouseworkTemplateClient` に取得・監視・`updateTemplate`・`appendItem` を追加し、Implを実装
- [x] `HouseworkTemplateListStore` の `MonthlyItems` 監視・`saveTemplate`・`appendItem`・変更検知（`itemChanges`）とテスト

**PR #3**
- [x] `HouseworkTemplateContext.templateOfDay(by:calendar:)` で毎月の家事も返すようにし、テストを追加

**PR #4**
- [x] `WeekdaySelector` / `WeekdayLabel` を `HometeUI` へ移動（リファクタ）
- [x] `HouseworkRecurrenceInput` と `RecurrenceSelector`・Preview（種類ごとのバリエーション）
- [x] `HouseworkTemplateDraft` に毎月の家事を追加
- [x] テンプレート画面の「毎月」セクションとPreview
- [x] 編集モーダル・詳細画面の対応とPreview

**PR #5**
- [x] Analyticsの `step` / `recurrence` パラメータ
- [x] `RegisterHouseworkView` に繰り返しの設定欄と登録処理の分岐を追加（呼び出し元2箇所は既に environment に `HouseworkTemplateListStore` を入れているので変更不要）
- [x] テンプレートが無い場合の作成と監視開始（`appendItemCreatingTemplateIfNeeded`）とテスト
- [x] Previewの追加（毎週くり返し、毎月くり返しの月末）
- [x] `doc/analytics_events.md` を更新

### Phase 3: 検証

- [x] `swift build` でビルド通過
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過
- [x] ユニットテスト実行（追加分含む）通過
- [ ] `npm run test:rules` / `npm run test:e2e` 通過（PR #1。ローカルは8080番ポートが別プロセスで使用中のため未実行。CIで確認する）
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] 実機/シミュレータで動作確認（登録画面から毎週・毎月を登録 → 家事ボードの該当日に出る、テンプレート画面で編集・削除できる）

### Phase 4: PR

- [ ] スタックPRを#1から順に作成（`pr-create` スキル使用）
- [ ] 本番のFirestoreルールをデプロイしてから、アプリを審査に提出する
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
