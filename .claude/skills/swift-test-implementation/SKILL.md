---
name: swift-test-implementation
description: homete iOSプロジェクトのSwiftテスト実装ガイド。Swift Testingフレームワークを使ったユニットテストの書き方、パターン、規約を定義する。新規テスト作成・既存テスト修正時に参照する。
---

# Swift テスト実装ガイド

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

## 制約・規約

| 項目 | ルール |
|---|---|
| テスト名 | `@Test("日本語で何をテストするか")` |
| Actの数 | 1テストにつき1つ。複数Actは別テストケースに分ける |
| 関数名 | キャメルケース・英語（`setupObserver`, `streamUpdateIsUpserted`など） |
| 行数上限 | 関数本体50行以内（コメント・空行除く）。超える場合は分割 |
| ファイル行数 | 400行超で `// swiftlint:disable file_length` を先頭に追加 |
| `try?` / force unwrap | `force_unwrapping` 禁止。`try?` または `?? fallback` を使う |
| 複数クロージャ | trailing closure 禁止。`onChange:` など明示的ラベルを使う |
