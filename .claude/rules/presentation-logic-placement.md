---
paths:
  - "LocalPackage/Sources/**/*.swift"
---

# プレゼンテーションロジックの置き場所

**「何を表示するか」「実行できるか」の判断は、状態を持つScreen/Viewが行う。末端コンポーネントは
渡された値を描画してイベントを伝えるだけに留める。**

末端コンポーネントとは、`Features/**/SubViews/` や `HometeUI/Components/` に置かれる、画面の一部を
構成する再利用可能なViewを指す。

## やってはいけないこと

- 末端コンポーネントが`@Environment`からStore・Client・`loginContext`を引いて、表示内容を自分で
  導出する
- 末端コンポーネントがStoreのメソッドを呼んでドメイン操作を実行する
- 「どのボタンを出すか」「非活性か」をコンポーネント内の算出プロパティで決める

```swift
// ❌ 誤り: コンポーネントが選択内容から表示するアクションを導出し、Storeも叩いている
struct HouseworkBulkActionBar: View {
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext) var loginContext

    let state: HouseworkState
    let selectedItems: [HouseworkBoardItem]

    var bulkActions: [HouseworkQuickAction] { /* 選択内容から導出 */ }
    func performBulk(_ action: HouseworkQuickAction) async { /* Storeを呼ぶ */ }
}

// ✅ 正しい: 決まった結果を受け取り、タップを伝えるだけ
struct HouseworkBulkActionBar: View {
    let actions: [HouseworkQuickAction]
    let isEnabled: Bool
    let onTap: (HouseworkQuickAction) -> Void
}
```

## なぜこうするのか

- **表示の根拠が1箇所に揃う。** 判断がコンポーネントに散ると、たとえば「選択を制限するロジック」と
  「バーに並べるボタンを決めるロジック」が別々のViewに置かれ、片方だけ直して食い違う
- **Previewでバリエーションを網羅できる。** Environment依存が無くなると、引数を変えるだけで表示の
  組み合わせを並べられる。VRTの網羅方針（[prefire-preview.md](prefire-preview.md)）はこれが前提
- **判断ロジックを値型に切り出せば、Viewを介さずユニットテストできる**

## 判断ロジックの置き場所

呼び出し側のViewに算出プロパティとして書くのが基本。判断が複数の入力に依存して増えてきたら、
Feature配下の`Model/`に値型として切り出す（例: `HouseworkSelection`が複数選択の判定を持ち、
`HouseworkBoardListContent`が`body`評価時に組み立てて問い合わせる）。

ドメイン操作の実行（Storeの呼び出し・通知送信）も同様にコンポーネントから追い出す。複数件へ同じ
操作を適用するようなオーケストレーションは、Store側の拡張に置くとテストできる（例:
`HouseworkListStore.performBulk(_:on:...)`）。

## 例外

見た目そのものの出し分けはコンポーネントに残してよい。「先頭のボタンだけスタイルを変える」
「文字数でレイアウトを変える」など、**入力が同じなら結果が決まり、ドメインの知識を必要としない**
ものが該当する。
