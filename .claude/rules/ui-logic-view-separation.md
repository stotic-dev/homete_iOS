---
paths:
  - "LocalPackage/Sources/**/*.swift"
---

# UIのみのViewとロジックを持つViewに分ける

**画面や画面の一部を実装するときは、「UIのみのView」と「ロジックを持つView」の2つに分ける。**
UIのみのViewは渡された値を描画してタップを伝えるだけにし、`Environment`からの依存の取得・
Storeの呼び出し・シートや画面遷移は、ロジックを持つView側に置く。

| 単位 | ロジックを持つView | UIのみのView |
|---|---|---|
| 画面 | `XxxScreen` | `XxxView` |
| 画面の一部 | `XxxComponent` | `XxxContent` |

実例: `HouseworkBoardScreen` / `HouseworkBoardView`、`TodayHouseworkSummaryComponent` /
`TodayHouseworkSummaryContent`、`ContributionSummaryComponent` / `ContributionSummaryContent`。

## UIのみのViewに置かないもの

- `@Environment`から取るStore・`AppDependencies`のClient・`loginContext`・`routeResolver`・
  `xxxNavigationPath`
- Storeのメソッド呼び出し、Analyticsの送信、`Task`での非同期処理
- `NavigationStack`・`.navigationDestination`・`.sheet`・`.fullScreenCover`などの提示と遷移
- `.trackScreenView`（サンプルの値で表示したときにも送られてしまうため）

## UIのみのViewに置いてよいもの

- 表示する値（`let`）、UIの状態の`@Binding`、タップを伝えるクロージャ
- レイアウトと見た目の修飾子（`.safeAreaInset`、ツールバーの項目など。[prefire-preview.md](prefire-preview.md)の6）
- そのViewの中で閉じるUIの状態（ポップオーバーの開閉、スクロール位置など）の`@State`
- 表示の書式に使う環境値（`calendar`・`locale`・`timeZone`）
- `Model/`の値型から表示を判断すること（`HouseworkSelection`の組み立てなど。
  [presentation-logic-placement.md](presentation-logic-placement.md)）
- ロジックを持つ中身を差し込む`@ViewBuilder`の引数（長押しメニューの中身など）。
  UIのみのViewが、Storeを使うViewを直接組み立てないようにするため

```swift
// ✅ UIのみのView: 値とクロージャを受け取り、Storeを使うメニューは差し込んでもらう
struct HouseworkBoardView<RowMenu: View>: View {
    @Binding var selectedHouseworkState: HouseworkState
    let houseworkBoardList: HouseworkBoardList
    let ownUserId: String
    let onTapAdd: () -> Void
    let onTapThanks: (HouseworkBoardItem) -> Void
    @ViewBuilder let rowMenu: (HouseworkBoardItem) -> RowMenu
}

// ✅ ロジックを持つView: Environmentから値を集めて渡し、操作とシート・遷移を受け持つ
public struct HouseworkBoardScreen: View {
    @Environment(\.loginContext) var loginContext
    @State var isPresentingAddHouseworkView = false

    public var body: some View {
        NavigationStack(path: $navigationPath.path) {
            HouseworkBoardView(
                selectedHouseworkState: $selectedHouseworkState,
                houseworkBoardList: houseworkBoardList,
                ownUserId: loginContext.account.id,
                onTapAdd: { isPresentingAddHouseworkView = true },
                onTapThanks: { item in Task { await sendThanks(to: item) } },
                rowMenu: { item in HouseworkQuickActionMenuContent(item: item, ...) }
            )
        }
        .sheet(isPresented: $isPresentingAddHouseworkView) { ... }
        .trackScreenView(.houseworkBoard)
    }
}
```

## なぜこうするのか

- **同じUIを別の値で使い回せる。** グループ登録直後のチュートリアルは、家事がまだ1件もない画面の代わりに、
  UIのみのViewへサンプルの家事を渡して表示している（`HouseworkBoardTutorialView`・`DashboardTutorialView`）。
  UIを変えればチュートリアルにもそのまま反映され、チュートリアル用の画面を別に保守しなくて済む
- **Previewで表示のバリエーションを網羅できる。** Environmentへの依存が無ければ、引数を変えるだけで状態を
  作り分けられ、VRTの対象を増やせる（[prefire-preview.md](prefire-preview.md)の7）
- **判断と操作の置き場所が1箇所に揃う。** UIのあちこちでStoreを呼ぶと、同じ操作のエラー処理や
  Analyticsが散らばって食い違う

## 置き方の補足

- `#Preview`はUIのみのView側に書く。ロジックを持つView側はVRTの対象にしない
- `NavigationStack`はロジックを持つView側が持つ。UIのみのViewは`NavigationStack`の中に置かれる前提で
  ツールバーの項目を並べ、Previewでは`NavigationStack`で包む
- UIのみのViewが大きくなったら、さらに`XxxContent`へ分けてよい。分けた先もUIのみにする

## 既存コード

`RegisteredContent`（名前はContentだがStoreを使う）や`HouseworkQuickActionMenuContent`（Storeを呼ぶメニューの中身）
のように、この分け方になっていないViewが残っている。新しく書くコードはこれに倣わず、触る機会があれば分ける。
