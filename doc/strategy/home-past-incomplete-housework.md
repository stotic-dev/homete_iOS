# 過去日の未完了家事（ホームのセクション・家事ボードのアイコン） 実装方針

> 関連Issue: [#349 Feature: ホームに過去日の未完了家事セクションを追加する](https://github.com/stotic-dev/homete_iOS/issues/349)
> ブランチ: `feat/349-uncomplete-list-section`

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

昨日以前に登録されて完了されていない家事は、今はホームから見えず、家事ボードで日付をさかのぼらないと気づけない。
ホームの一番下に「やり残している家事」セクションを置いて全件を日付ごとに並べ、家事ボードの日付にも未完了がある日の印を付けて、やり残しに気づけるようにする。

## 要件

### 機能要件

#### ホーム「やり残している家事」セクション

- 配置: ホーム（`DashboardContent`）の一番下。家事テンプレートを促すバナーよりも下
- 対象: 今日より前の日付で、`state == .incomplete` の家事。グループ全員の分（担当者で絞らない）
  - 保存されている家事だけを対象にする。テンプレートから生成されていない過去日の家事は出さない
- 期間: 取得できている範囲すべて
  - 無料: 起動時に取得する直近3ヶ月（`HouseworkStoragePolicy.initialFetchLowerBound`）
  - プレミアム: 起動時に取得する直近1年。リストの末尾が見えたら、その前の3ヶ月分を追加で取得して並べる（ページング）。追加で取得した3ヶ月に家事が1件も無ければ、それより前は読み込まない
- 件数の上限は設けない。「すべて見る」や別画面は作らず、セクションの中にすべて並べる
- 並び順: 日付が新しい順（昨日が先頭）。Issueの案は古い順だったが、プレミアムでさらに前の家事を読み込むと先頭に増えてしまい「末尾が見えたら読み込む」が成り立たないため変えた。同じ日の中は既存の未完了の並び順（ポイント降順、`HouseworkItem.isIncompleteDisplayOrderedBefore`）
- 日付ごとに区切り（見出し）を入れる
- バナー広告: 無料プランで広告を出す条件（`AdDisplayPolicy.shouldShowAds`）を満たすとき、日付の区切り3つごとに、区切りの間へバナーを1つ挟む
- 行の操作: 既存の行（`HouseBoardListRow`）とクイックアクションを使う。完了にしても家事の日付は元の日付のまま（ポイントは元の日付の月に入る。貢献度の集計は`indexedDate`で月を決めているため）。行をタップすると家事詳細へ移る
- 空状態: 該当が0件ならセクションごと出さない
- 通知は追加しない

#### 家事ボードの日付のアイコン

- 家事ボードの日付の行（`HouseworkDateCell`）で、昨日以前かつ未完了の家事がある日に、赤いビックリマークのアイコンを付ける
- 今日・未来の日付には付けない
- 判定は取得済みの家事（`HouseworkListStore.items`）で行う。取得していない日には付かない

### 非機能要件 / 制約

- 新しいFirestoreのクエリは作らない。抽出は`HouseworkListStore.items`から行い、ページングは既存の`fetchItems`（期間を指定した取得）を使う
- ホームの`ScrollView`の中身は`VStack`のため、件数が多いと全行を一度に描画する。セクションの行は遅延して描画されるようにする（後述）
- 抽出・グルーピング・広告の差し込み位置はFeature配下の`Model/`の値型に置き、ユニットテストする
- UIのみのView（`XxxContent`）とロジックを持つView（`XxxComponent`）に分ける（`.claude/rules/ui-logic-view-separation.md`）
- 文言は`Localizable.xcstrings`に英訳も入れる

## 設計方針

### 1. 抽出モデル `PastIncompleteHouseworkList`

`LocalPackage/Sources/Features/HouseworkFeature/Model/PastIncompleteHouseworkList.swift`（新規）

```swift
public struct PastIncompleteHouseworkList: Equatable, Sendable {

    public struct DaySection: Equatable, Sendable, Identifiable {
        public let date: Date
        public let items: [HouseworkBoardItem]
        public var id: Date { date }
    }

    /// 古い日付順の日ごとの区切り
    public let sections: [DaySection]

    public static func make(storedAllItems: StoredAllHouseworkList, now: Date, calendar: Calendar) -> Self
}
```

- `storedAllItems.value`から`indexedDate < today`の日を取り出し、`state == .incomplete`の家事だけを残す。家事が残らない日は除く
- 日付の降順に並べ、日の中は`HouseworkItem.isIncompleteDisplayOrderedBefore`で並べる（`TodayHouseworkSummary`と共通化した）
- 期間の下限は`items`に入っている範囲そのものなので、モデル側では絞らない

### 2. 広告の差し込み位置

「何個目の区切りの後に広告を挟むか」も同じモデル（または小さな値型）で決め、テストする。

```swift
enum PastIncompleteHouseworkListElement: Identifiable {
    case section(DaySection)
    case advertisement(index: Int)
}

/// 区切り3つごとに広告を挟んだ並び。末尾には付けない
func elements(showsAdvertisement: Bool) -> [PastIncompleteHouseworkListElement]
```

### 3. ページング（プレミアム）

- `HouseworkManager.fetchOlderPeriod(months:cohabitantId:calendar:) async -> Int?`を足す。取得済みの期間の前日から指定した月数前までを取得し、取得した件数を返す（初回のフェッチ前・失敗・割り込みは`nil`）。内部の`appendItems`が件数を返すようにした
- `HouseworkListStore.fetchOlderPeriod(cohabitantId:) async -> Int?`から3ヶ月単位で呼ぶ
- 無料プランは閲覧範囲が3ヶ月で、起動時に取得済みなのでページングしない
- 末尾に来たら読み込むきっかけは、一覧の末尾に置いた要素の`.task(id: olderPeriodLoadCount)`。読み込んだ期間にやり残しが無いと一覧が変わらず末尾が表示され直さないため、読み込むたびに回数を増やして、末尾が表示されたままなら続けて読み込む。読み込み中は末尾にインジケータを出す
- Component側は「待機」「読み込み中」「もう前は無い」の3つの状態を持つ
- 失敗したときは末尾のインジケータを消し、次に末尾が見えたときにもう一度試す（エラーのアラートは出さない）

### 4. View

| View | 役割 |
|---|---|
| `PastIncompleteHouseworkComponent`（ロジック） | `HouseworkListStore`・`\.now`・`calendar`・`SubscriptionStore`・`adComponentResolver`からモデルを組み立て、クイックアクション・完了シート・詳細への遷移・ページングを受け持つ |
| `PastIncompleteHouseworkContent`（UIのみ） | 見出し「やり残している家事」、日付の区切り、行（`HouseBoardListRow`）、広告の差し込み、末尾のインジケータを描く。広告と行のメニューは`@ViewBuilder`で受け取る |

- `DashboardContent`に`pastIncompleteHousework`の`@ViewBuilder`引数を足し、一番下に置く。0件のときはComponentが`EmptyView`相当を返し、セクションごと出さない
- 遅延描画: `DashboardContent`の`ScrollView`直下の`VStack`を`LazyVStack`に変え、セクションの中身は日付の区切りごとに直下の要素として並べる（入れ子の`VStack`に全行を入れると遅延されない）。チュートリアルのスポットライト（`tutorialSpotlightTarget`）が崩れないかをVRTとシミュレータで確かめる
- 日付の区切りの書式は「10月27日（2日前）」のように、日付と何日前かを並べる（文言・書式はView側で決める）
- 家事詳細への遷移は、ホームの既存の遷移（`RegisteredContentRoute`）に乗せる
- 画面は増えないので`screen_view`は足さない。Analyticsイベントも足さない（完了などは既存のクイックアクションのイベントで送られる）

### 5. バナー広告

- 既存の`BannerType.dashboardTop`（広告ユニットIDと`.inline(maxHeight: 150)`の配置）を使い回す。新しい広告ユニットIDは作らない
- 広告の近くにタップできる要素を置かないというAdMobのガイドラインに従い、広告と行の間に余白を取る

### 6. 家事ボードの日付アイコン

- `HouseworkBoardScreen`が`PastIncompleteHouseworkList.make(...).dates`で「昨日以前で未完了の家事がある日」の集合を作り、`HouseworkBoardView` → `HouseworkDateHeaderContent` → `HouseworkDateCell(hasPastIncomplete:)`へ渡す。ホームと同じ抽出を使い、判定をそろえる
- `HouseworkDateCell`は右上に赤い`exclamationmark.circle.fill`を重ねる。VoiceOverでは日付の読み上げに「やり残している家事があります」を足す
- アイコンの色・記号はView（`HouseworkDateCell`）で決める（`.claude/rules/ui-attributes-in-view.md`）

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/PastIncompleteHouseworkList.swift` | 過去日の未完了の抽出・日付ごとの区切り・広告の差し込み位置 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/TodayHouseworkSummary.swift` | 未完了の並び順を共通化 |
| 新規Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkItem+IncompleteDisplayOrder.swift` | 未完了の並び順 |
| 修正Store | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | 取得済みより前の3ヶ月を追加取得 |
| 修正Manager | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkManager.swift` | 取得済みより前を指定した月数ぶん取得する`fetchOlderPeriod` |
| 新規View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/Components/PastIncompleteHouseworkComponent.swift` | ロジックを持つView |
| 新規View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/Components/PastIncompleteHouseworkContent.swift` | UIのみのView・Preview |
| 修正View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/DashboardContent.swift` | 一番下にセクション、`LazyVStack`化 |
| 修正View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/RegisteredContent.swift` | Componentと広告を渡す |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/DateHeader/HouseworkDateCell.swift` | アイコンの表示 |
| 修正View | `HouseworkDateHeaderContent.swift`・`HouseworkBoardView.swift`・`HouseworkBoardScreen.swift` | 印を付ける日付の受け渡し |
| 修正 | `Localizable.xcstrings`（HomeFeature・HouseworkFeature） | 見出し・日付の区切り・読み上げの英訳 |
| テスト | `LocalPackage/Tests/HouseworkFeatureTests/Model/PastIncompleteHouseworkListTest.swift` ほか | 抽出・並び順・区切り・広告位置・日付アイコン |

## タスク

### Phase 1: 設計確定

- [x] 表示期間: 取得できる範囲。無料3ヶ月、プレミアムは1年＋3ヶ月ずつのページング（家事が0件の期間で打ち切り）
- [x] 過去分を完了したポイントは元の日付の月に入れる
- [x] ホームの一番下に件数の上限なしで並べる。別画面は作らない
- [x] 日付ごとに区切る
- [x] バナー広告は日付の区切り3つごと（無料プランのみ）
- [x] 家事ボードのアイコンは昨日以前の日だけ
- [x] 見出しは「やり残している家事」
- [x] 広告ユニットIDは`dashboardTop`を使い回す
- [x] 並び順は日付が新しい順（ページングと両立させるため）

### Phase 2: 実装

- [x] `TodayHouseworkSummary`の未完了の並び順を共通化（refactor）
- [x] `PastIncompleteHouseworkList`とユニットテスト
- [x] `HouseworkManager.fetchOlderPeriod`・`HouseworkListStore`の追加取得とユニットテスト
- [x] `PastIncompleteHouseworkContent` / `PastIncompleteHouseworkComponent`とPreview（区切り1つ・複数・広告あり・読み込み中）
- [x] `DashboardContent`への配置と`LazyVStack`化
- [x] 家事ボードの日付アイコン（`HouseworkDateCell`）とPreview
- [x] 文言の英訳（`make check-translations`）

### Phase 3: 検証

- [x] `make build-affected`・`make build-infra-package`
- [x] `swift-code-verification`スキルに沿ってSwiftLint・`make test-affected`
- [ ] `make check-previews`・`make snapshot-affected`
- [ ] シミュレータで確認（過去日の未完了の表示・完了操作・詳細への遷移・家事ボードのアイコン）

### Phase 4: PR

- [ ] PR作成（`pr-create`スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/349
- 既存実装（参考）:
  - `LocalPackage/Sources/Features/HouseworkFeature/Model/TodayHouseworkSummary.swift`
  - `LocalPackage/Sources/Features/HouseworkFeature/IncompleteHouseworkListView/IncompleteHouseworkListView.swift`
  - `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/DashboardContent.swift`
  - `LocalPackage/Sources/HometeDomain/Subscription/HouseworkStoragePolicy.swift`
  - `doc/strategy/today-housework-summary.md`
