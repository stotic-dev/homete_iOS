---
paths:
  - "LocalPackage/Sources/**/*.swift"
---

# 表示の属性はViewに書く

**画面に出す文言・SF Symbol名・色・VoiceOverの読み上げ文言など、見た目やアクセシビリティに
直接効く値はView側で決める。** `HometeDomain`のモデルや、Feature配下の`Model/`に置く値型には
持たせない。

`Model/`の値型が持つのは「どの状態か」「何件か」「誰か」といった**表示の元になる事実**まで。
それを何色のどのアイコンで、どんな言葉で見せるかはViewの責務とする。

## やってはいけないこと

- 状態を表すenumに`label` / `systemImage` / `foregroundStyle` / `accessibilityLabel`などの
  算出プロパティを生やす
- `Model/`の値型に表示用の既定文言（`static let defaultMessage = "ありがとう！"`など）を置き、
  `nil`を文言で埋めた状態で返す
- 表示のためだけに`Model/`や`HometeDomain`で`SwiftUI` / `HometeResources`をimportする

```swift
// ❌ 誤り: 状態のenumが見た目と読み上げ文言まで持っている
enum HouseworkThanksStatus {
    case notSent, sent, received

    var systemImage: String { ... }
    var foregroundStyle: Color { ... }
    var accessibilityLabel: String { ... }
}

// ✅ 正しい: enumは状態だけを表し、見せ方はそれを描くViewが決める
enum HouseworkThanksStatus {
    case notSent, sent, received
}

private extension HouseBoardListRow {
    func thanksSystemImage(_ status: HouseworkThanksStatus) -> String {
        switch status { ... }
    }
}
```

```swift
// ❌ 誤り: コメントが無いときの表示文言をモデルが決めている
struct HouseworkThanksMessage {
    static let defaultMessage = "ありがとう！"
    let message: String  // comment ?? defaultMessage を詰めて返す
}

// ✅ 正しい: モデルは「コメントが無い」事実を返し、何と出すかはViewが決める
struct HouseworkThanksMessage {
    let comment: String?
}
Text(thanksMessage.comment ?? "ありがとう！")
```

## なぜこうするのか

- **見た目の変更がViewの差分だけで済む。** 色や文言の調整のたびにモデルとそのテストまで触ると、
  変更の意図（見た目の調整なのか判定の変更なのか）がレビューで読み取れなくなる
- **モデルのテストが表示に引きずられない。** 文言を詰めて返すと、文言を変えただけで判定ロジックの
  テストが落ちる。事実だけを返せば、テストは判定の正しさだけを見られる
- **同じ状態を別の画面で違う見せ方にできる。** モデルに見た目を持たせると、2画面目で見せ方を
  変えたくなったときにモデル側へ分岐が増えていく

## 置き場所

見せ方の分岐は、その値を描くViewの`private extension`に関数として書く。複数のViewで同じ見せ方を
共有する必要が出たら、Viewと同じFeature内（`SubViews/`など）にView用の拡張として切り出し、
`Model/`には戻さない。

[presentation-logic-placement.md](presentation-logic-placement.md)（「何を表示するか」の判断は
Screen/Viewの呼び出し側に置く）とは補い合う関係にある。「どの状態か」の判断は`Model/`の値型に
切り出してよいが、その状態の見せ方はViewに残す。

## 例外

- Push通知の本文（`PushNotificationContent`）のように、画面ではなく相手の端末に届く文言は
  送信処理と一体なのでドメイン側に置いてよい
- 既存コードには`HouseworkQuickAction`・`HouseworkItemMetaData`のように`Model/`が表示の属性を
  持つものが残っている。新しく書くコードはこれに倣わず、触る機会があればViewへ移す
