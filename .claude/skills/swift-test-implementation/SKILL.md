---
name: swift-test-implementation
description: homete iOSプロジェクトのSwiftテスト実装ガイド。Swift Testingフレームワークを使ったユニットテストの書き方、パターン、アサーション必須ルール、規約を定義する。テストファイル（*Test.swift / *Tests.swift / Tests/**/*.swift）の新規作成・編集を行う前に必ず参照すること。
---

# Swift テスト実装ガイド

> **このスキルは、テストファイル（`*Test.swift` / `*Tests.swift` / `Tests/**/*.swift`）を編集する前に必ず読むこと。**
> 実装後ではなく**実装前**に参照しないと、後述のアサーションルール違反で書き直しが発生する。

---

## 🚨 最優先：アサーション必須ルール（違反禁止）

**過去に何度も違反が発生している最重要ルール。テスト実装時は必ず以下を守ること。**

### ルール1: expected値の生成にテスト対象（プロダクションコード）を使わない

expected値は**ピュアな`.init(...)`または`makeForTest`**で組み立てる。
SUT（System Under Test）と同じファクトリ・同じメソッド・同じ計算ロジックで expected を作るのは禁止。

**理由**: SUTと同じロジックで expected を作ると「actual と expected が同じロジックを通っている」だけになり、ロジックの正しさを検証できない（自分自身と比較しているのと等価）。

### ルール2: プロパティ単体検証ではなく、戻り値型の全体比較を行う

`#expect(result.count == 2)`、`#expect(item.id == ...)`、`#expect(item.title == ...)` のような**プロパティ単体の連続検証は禁止**。
expected をピュア init で構築し、`#expect(actual == expected)` で型ごと丸ごと比較する。

**理由**: プロパティ単体検証は検証漏れを生み、新規プロパティ追加時に自動検出できない。

### ❌ NG パターン

```swift
// NG: プロダクションコードの make() で expected を生成
let expected = await ContributionAnalytics.make(
    contribution: contribution,
    members: members,
    displayPeriod: newPeriod,
    calendar: calendar
)
#expect(result == expected)
```

```swift
// NG: SUTと同じドメインメソッドで expected を加工
let expected = HouseworkItem.makeForTest(id: 1).updatedToCompleted()  // updatedToCompleted がSUT
```

```swift
// NG: プロパティ単体検証
#expect(item.id == "generatedId")
#expect(item.title == "週末掃除")
#expect(item.point == 30)
#expect(item.state == .incomplete)
```

### ✅ OK パターン

```swift
// OK: ピュア .init() で expected を組み立て、丸ごと比較
let expected = HouseworkItem(
    id: "generatedId",
    indexedDate: HouseworkIndexedDate(value: Date.previewDate(year: 2026, month: 5, day: 9)),
    title: "週末掃除",
    point: 30,
    state: .incomplete,
    executorId: nil,
    executedAt: nil,
    reviewerId: nil,
    approvedAt: nil,
    reviewerComment: nil,
    expiredAt: Date.previewDate(year: 2027, month: 5, day: 9)
)
#expect(actual == expected)
```

```swift
// OK: makeForTest でデフォルト値を埋めて生成（SUTと無関係なヘルパー）
let expected = HouseworkItem.makeForTest(id: 1, state: .completed)
#expect(actual == expected)
```

```swift
// OK: 入力側を簡単にして expected を簡単に書ける状態にする
//   メンバー0人/空集計データなどにして、expected が空配列やゼロ値で決定論的に書ける状態に寄せる
let expected = ContributionAnalytics(
    weekPointList: [],
    monthPointList: [],
    yearPointList: [],
    displayPeriod: newPeriod
)
#expect(result == expected)
```

### confirmation 内のアサーションも同じルール

`confirmation` のクロージャ内で `#expect(item == ...)` する場合も、expected はピュア init で構築する:

```swift
// OK
let expectedItem = HouseworkItem(
    id: fixedItemId,
    indexedDate: ...,
    title: "週末掃除",
    point: 30,
    state: .incomplete,
    // ...全プロパティ
)
try await confirmation { confirmation in
    let store = HouseworkListStore(
        houseworkClient: .init(insertOrUpdateItemHandler: { item, _ in
            #expect(item == expectedItem)  // ← 全体比較
            confirmation()
        }),
        idGenerator: { fixedItemId }
    )
    try await store.applyTemplate(plan: plan)
}
```

---

## 基本構成

### フレームワーク・インポート

```swift
import Foundation  // Date等を使う場合のみ
import Testing
@testable import HometeDomain
```

### struct の分離・アイソレーション

- **Storeテスト（`@MainActor`クラスを扱う場合）**: `@MainActor struct`
- **純粋なドメインモデルテスト**: アノテーションなし

```swift
@MainActor
struct HouseworkListStoreTest { ... }

struct HouseworkBoardListTest { ... }
```

---

## テストケースの構造

### 基本テンプレート（Arrange/Act/Assert）

```swift
@Test("日本語でテスト内容を説明する")
func functionName() async throws {

    // Arrange

    let input = ...
    let expected = ...

    // Act

    let actual = sut.method(input)

    // Assert

    #expect(actual == expected)
}
```

- コメントは `// Arrange` / `// Act` / `// Assert` の3セクション
- **Actが複数ある場合は別テストケースに分ける**（1テスト1Act原則）

### パラメータ化テスト

```swift
@Test(
    "担当者が自分以外かつ未完了の場合、レビュー可能",
    arguments: [HouseworkState.incomplete, .pendingApproval]
)
func canReview_notOwnUserAndNotCompleted_returnsTrue(state: HouseworkState) {

    // Arrange
    let item = HouseworkItem.makeForTest(id: 1, state: state)

    // Act
    let result = item.canReview(ownUserId: "ownUserId")

    // Assert
    #expect(result == true)
}
```

### テストケースのグルーピング

関連するケースは `enum` + `extension` でグループ化する:

```swift
enum HouseworkItemTest {
    struct CanReviewCase {}
    struct UpdateStateCase {}
}

extension HouseworkItemTest.CanReviewCase {
    @Test("...") func test1() { ... }
}

extension HouseworkItemTest.UpdateStateCase {
    @Test("...") func test2() { ... }
}
```

ファイルが長くなる場合は先頭に `// swiftlint:disable file_length` を追加する。

---

## 非同期テストのパターン

### confirmation：コールバックが呼ばれることを検証

複数のコールバックを検証する場合は `expectedCount` を指定する。

```swift
try await confirmation(expectedCount: 2) { confirmation in

    let store = SomeStore(
        client: .init(
            methodA: { param in
                #expect(param == expected)
                confirmation()
            },
            methodB: { param in
                #expect(param == expected)
                confirmation()
            }
        )
    )

    try await store.doSomething()
}
```

### withCheckedContinuation：コールバック完了まで待機

非同期処理の完了を `Task` 内で待つ場合:

```swift
let _: Void = await withCheckedContinuation { continuation in

    let store = SomeStore(
        client: .init(onComplete: { result in
            #expect(result == expected)
            continuation.resume()  // ← ここで待機解除
        })
    )

    Task { try await store.doSomething() }
}
```

### AsyncStream：リアルタイムリスナーのテスト

```swift
let (stream, continuation) = AsyncStream<[HouseworkItem]>.makeStream()

let manager = HouseworkManager(
    houseworkClient: .init(
        snapshotListenerHandler: { _, _, _, _ in stream },
        fetchItemsHandler: { _, _, _ in [] }
    )
)

// ストリームにデータを流す
continuation.yield([item1, item2])

// ストリームから受け取る
var received: [HouseworkItem] = []
for await items in observerStream {
    received = items
    break  // 1件受け取ったら抜ける
}
continuation.finish()
```

### @Observable プロパティ変更の検知

`@Observable` クラスのプロパティ変更を待つ場合は `ObservationHelper` を使う:

```swift
let waiter = Task {
    await withCheckedContinuation { continuation in
        ObservationHelper.continuousObservationTracking({ store.items }) {
            continuation.resume(returning: ())
        }
    }
}

// プロパティ変更をトリガーする操作
continuation.yield(newItems)

await waiter.value  // 変更が検知されるまで待機
```

### actor のプロパティ読み取り

`final actor` のプロパティは `await` で読み取る:

```swift
let allItems = await manager.allItems
#expect(allItems.count == 2)
```

---

## クライアントモックのパターン

### 呼ばれてはいけないハンドラ

想定外の呼び出しには `Issue.record()` を使う:

```swift
cohabitantPushNotificationClient: .init { _, _ in
    Issue.record()  // このハンドラは呼ばれてはいけない
}
```

### 使わないパラメータ

不要なパラメータは `_` でスキップする:

```swift
fetchItemsHandler: { _, _, _ in [] }
snapshotListenerHandler: { _, _, _, _ in .makeStream().stream }
```

---

## テストヘルパー

### `makeForTest` ファクトリメソッド

テスト用のドメインモデルはヘルパーで作る。`TestHelper/` に置く。

```swift
// HouseworkItemHelper.swift
extension HouseworkItem {
    static func makeForTest(
        id: Int,
        indexedDate: Date = .now,
        title: String = "title",
        point: Int = 100,
        state: HouseworkState = .incomplete,
        expiredAt: Date = .now
    ) -> Self { ... }
}
```

### `updateProperties` ヘルパー

既存モデルの一部だけ変更したテストデータを作る場合:

```swift
let updatedItem = existingItem.updateProperties(title: "updated title")
```

---

## ジェネリック型のテスト

ジェネリック型（`AllUserViewablePointList<ViewableType>` など）は型引数を渡してインスタンス化する。型推論が効く場合はそのままで良いが、空リストなど推論できない場合は明示指定する。

```swift
// 型推論が効く場合
let sut = AllUserViewablePointList(
    list: [PointOfWeek(...)],
    dateRange: start...end
)

// 空リストで推論できない場合は明示指定
let sut = AllUserViewablePointList<PointOfWeek>(
    list: [],
    dateRange: start...end
)
```

---

## 制約・規約

| 項目 | ルール |
|---|---|
| **アサーション（最重要）** | **expected はピュア init / makeForTest で生成。SUTのロジック使用禁止。プロパティ単体検証ではなく `#expect(actual == expected)` で全体比較。詳細は冒頭「🚨 最優先：アサーション必須ルール」参照** |
| テスト名 | `@Test("日本語で何をテストするか")` |
| Actの数 | 1テストにつき1つ。複数Actは別テストケースに分ける |
| 関数名 | キャメルケース・英語（`setupObserver`, `streamUpdateIsUpserted`など） |
| 行数上限 | 関数本体50行以内（コメント・空行除く）。超える場合は分割 |
| ファイル行数 | 400行超で `// swiftlint:disable file_length` を先頭に追加 |
| `try?` / force unwrap | `force_unwrapping` 禁止。`try?` または `?? fallback` を使う |
| 複数クロージャ | trailing closure 禁止。`onChange:` など明示的ラベルを使う |
