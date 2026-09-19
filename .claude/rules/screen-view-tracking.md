---
paths:
  - "LocalPackage/Sources/**/*.swift"
---

# 画面追加時のscreen_view送信ルール

**画面を1つ追加したら、`screen_view`イベントの送信も必ず同じPRで足す。**

Firebase Analyticsの自動収集`screen_view`は`UIViewController`単位で動作するため、SwiftUIのみで構成している本アプリでは何もしなければ画面遷移が記録されない。送信漏れが1画面でもあると、その画面は「表示0回」としてGA4に載り、離脱箇所や機能への到達率の分析が成立しなくなる。後から気づいても過去のデータは取り戻せない。

## 追加手順

新しい画面のルートViewを作ったら、以下を1セットで行う。

1. `HometeDomain/AnalyticsLog/AppScreen.swift` にケースを追加する（`rawValue`はsnake_case）
2. 画面のルートViewの`body`の**最後のModifier**として `.trackScreenView(.追加したケース)` を付ける
3. [doc/analytics_events.md](../../doc/analytics_events.md) の `### screen_view` にある画面一覧の表に行を追加する

```swift
// AppScreen.swift
case houseworkStatistics = "housework_statistics"
```

```swift
// HouseworkStatisticsView.swift
var body: some View {
    VStack {
        // ...
    }
    .padding(.horizontal, .space16)
    .trackScreenView(.houseworkStatistics)  // bodyの最後に付ける
}
```

`AppScreen`のケース追加だけでテストは自動的にカバーされる（`AnalyticsEventTest`が`AppScreen.allCases`でパラメータ化されているため、テストの追記は不要）。

## 判断基準

### 「画面」として数えるもの

ナビゲーションで積まれる、あるいはモーダル/フルスクリーンで前面に出る、**ユーザーが独立した画面として認識する単位**。

| 対象 | 扱い |
|---|---|
| プッシュ遷移先・シート・フルスクリーンカバーのルートView | 画面として追加する |
| 同一画面内の状態違い（読み込み中・エラー・空状態など） | 追加しない |
| 親Viewの一部として描画されるサブView・コンポーネント | 追加しない |
| デバッグ用画面（`DebugMenuView`など） | 追加しない（本番の分析対象外） |

同一画面内のフェーズ遷移（例: `CohabitantRegistrationView`のスキャン中 → ピア一覧 → 処理中）は画面を分けず、機能単位のイベントの`action`パラメータで区別する（[ADR-0009](../../doc/adr/0009-analytics-event-parameter-design.md)）。画面を分けると`screen_view`と機能イベントで同じ遷移を二重に持つことになり、どちらを見ればよいか分からなくなる。

### 付ける場所

**画面のルートViewの`body`の最後**に付ける。サブViewや条件分岐の内側に付けると、条件によって送信されたりされなかったりして数が合わなくなる。

`.trackScreenView(_:)`は`HometeUI`にあるため、`HometeUI`に依存しないモジュール（`HometeInfrastructure`など）のViewには直接付けられない。計測のためだけに依存を増やさず、**画面を組み立てる側**で付ける。`PaywallScreen`が`AppRoot/ResolverImpl/RouteResolverInjection.swift`で付けているのがこのケース。

## 禁止事項

- 画面のViewで`analyticsClient.log(.screenView(...))`を直接呼ぶ（`onAppear`の書き漏れ・重複の温床になるため、必ずModifierを使う）
- `AppScreen`を経由せず`screen_name`の文字列を手書きする（表記ゆれで同じ画面がGA4上で複数行に割れる）
- `screen_view`以外の独自イベント名で画面表示を送る（GA4の予約イベント名を使うことで「画面とビュー」レポートにそのまま載り、イベント名の登録上限も消費しない）
