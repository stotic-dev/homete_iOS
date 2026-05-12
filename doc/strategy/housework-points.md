# 家事ポイント機能 実装方針

## 概要

完了した家事に対してポイントを付与し、週・月・年単位のグラフで家族ごとの家事貢献度を可視化する。

## 要件

- 家事を完了（承認済み）した実行者にポイントを付与する
- ポイントは週・月・年単位でグラフ表示する
- グラフでは同じCohabitantグループ内のメンバー全員の貢献度を比較できる

## データ設計方針

### 新規コレクションは作らない

ポイント集計のために新しいFirestoreコレクションは追加しない。
既存の `Cohabitant/{cohabitantId}/Houseworks` コレクションに必要なデータが揃っているため、それを単一のデータソースとして使う。

**理由:**
- 新規コレクションを作ると `Houseworks` との二重管理になり、データ不整合リスクが生まれる
- 家族アプリのデータ量（数十〜数百件/月）であればクライアント側集計で十分に対応できる
- 将来的にデータ量が増えてクエリが遅くなった時に、初めて集計コレクションの追加を検討する

### グラフの日付軸は indexedDate を使う

ポイントの期間集計には `approvedAt`（承認日時）ではなく `indexedDate`（家事の日付）を使う。
「いつ承認されたか」ではなく「いつの家事か」でグラフを区切る。

### クエリ方式

チャート表示時は `indexedDate.value` に対して範囲クエリを使う。
`indexedDate.value` は `"YYYY/MM/DD"` 形式の文字列で、辞書順ソートが日付順と一致するため範囲クエリが正しく機能する。

```swift
// 例：2026年4月のポイント集計
db.collection("Cohabitant/{cohabitantId}/Houseworks")
  .whereField("state", isEqualTo: "completed")
  .whereField("indexedDate.value", isGreaterThanOrEqualTo: "2026/04/01")
  .whereField("indexedDate.value", isLessThanOrEqualTo:    "2026/04/30")
  .getDocuments()
// → クライアント側で executorId ごとに point を合算
```

## インフラ変更

### Firestore 複合インデックスの追加

`state`（等値）と `indexedDate.value`（範囲）を組み合わせるクエリには複合インデックスが必要。

| コレクション | フィールド1 | フィールド2 |
|---|---|---|
| `Cohabitant/{id}/Houseworks` | `state` ASC | `indexedDate.value` ASC |

## 集計ロジック

クライアント側で取得したドキュメントを `executorId` ごとにグループ化し、`point` を合算する。

```
取得した Houseworks（state == completed, 期間内）
  └─ executorId: "user_alice" → point: 30, 50, 20 → 合計 100pt
  └─ executorId: "user_bob"   → point: 40, 60     → 合計 100pt
```

週・月・年いずれの粒度でも、期間の開始日・終了日を `indexedDate.value` の範囲として渡すだけで同じクエリが使える。

## モジュール構成

### ContributionFeature（新規モジュール）

家事貢献度可視化はアプリの競争優位となる中核機能のため、独立したモジュールとしてカプセル化する。

```
ContributionFeature（新規）
  ├── Views/        グラフ表示の SwiftUI View
  ├── Store/        HouseworkPointStore（期間切り替え・集計ロジック）
  └── Domain/       PointSummary など集計結果モデル

依存: HometeDomain / HometeUI / HometeResources
```

### HouseworkManager（新規）

`HometeDomain` に追加する `@Observable` クラス。
`HouseworkListStore`（家事ボード）と `HouseworkPointStore`（ポイントグラフ）の共通データソースとして機能する。

**役割:**
- 家事データの単一ソース・オブ・トゥルース
- 家事ボードの状態変更がポイントグラフにも即時反映される

**データ取得戦略:**

```
起動時:
  1. 直近1年分の家事をワンショットフェッチ → allItems に保持
  2. ±N日のリアルタイムリスナーを開始

リアルタイム更新時:
  3. 差分を allItems に upsert（ID一致で上書き、新規は追加）
```

**参照関係:**

```
HometeDomain
  └── HouseworkManager
        ├── allItems: [HouseworkItem]   直近1年分
        └── HouseworkClient を保持（読み取り専用：フェッチ・監視）

HouseworkFeature
  └── HouseworkListStore
        ├── HouseworkManager 参照（データ読み取り・ボード表示用に日付フィルタ）
        └── HouseworkClient 保持（書き込み：register / approved / rejected 等）

HomeFeature → ContributionFeature（依存）
  └── ContributionFeature は HomeFeature に依存しない（循環依存防止）

ContributionFeature
  └── HouseworkPointStore
        ├── HouseworkManager 参照（completedItems を期間集計）
        ├── CohabitantStore 参照（グループ内の全メンバー一覧）
        └── AccountStore 参照（自分自身の情報）
        ※ executorId → ユーザー名の解決を両 Store で行う。新規クライアント不要。
```

**CRUD の責務分離:**

書き込み操作（家事の登録・承認・却下等）は `HouseworkListStore` に留める。
他の Feature（ContributionFeature、HomeFeature）は書き込みに関与しない。
HouseworkListStore が書き込んだ変更は HouseworkManager の live listener が拾い、allItems に自動反映される。

**リファクタリング範囲:**

| 対象 | 変更内容 |
|---|---|
| `HouseworkManager`（新規） | 取得・監視・保持の責務を新設 |
| `HouseworkListStore` | HouseworkClient の読み取り処理を HouseworkManager に移譲 |
| `AppTabView` | `loadHouseworkList` の呼び出しを HouseworkManager のロードに切り替え |

**ワンショットフェッチの範囲:**

```swift
// indexedDate.value で直近1年を指定
.whereField("indexedDate.value", isGreaterThanOrEqualTo: oneYearAgoString)
.whereField("indexedDate.value", isLessThanOrEqualTo: todayString)
```

## グラフ実装方針

### ライブラリ

Swift Charts（標準ライブラリ）を使用する。特殊なグラフは不要なため、追加ライブラリは導入しない。

### グラフ仕様

- **種類:** 折れ線グラフ（`LineMark`）
- **X軸:** 日付（週/月/年の粒度で切り替え）
- **Y軸:** ポイント数
- **系列:** アカウントごとに色分け（`foregroundStyle(by:)`）
- **凡例:** アカウント名と対応する色を明示（`.chartLegend`）

```swift
Chart {
    ForEach(memberPointSeries) { series in
        ForEach(series.data) { point in
            LineMark(
                x: .value("日付", point.date),
                y: .value("ポイント", point.totalPoint)
            )
        }
        .foregroundStyle(by: .value("メンバー", series.memberName))
    }
}
.chartLegend(position: .bottom)
```

## データ保存期限（expiredAt）の変更

### 変更内容

`DailyHouseworkMetaData.swift` の expiredAt を1ヶ月→1年に変更する。

```swift
// Before
let expiredAt = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate

// After
let expiredAt = calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
```

**背景:** `expiredAt` は Firestore TTL（自動削除）に使用されている。HouseworkManager が直近1年分を保持するため、データが1ヶ月で削除されないよう保存期限を1年に延長する。

### 注意事項

この変更は**新規登録される家事にのみ適用される**。
変更前に登録済みの家事は元の expiredAt（登録日 + 1ヶ月）のまま自動削除される。
過去データの遡及が必要な場合は、Firestore 側で既存ドキュメントの expiredAt を更新する対応が別途必要。
