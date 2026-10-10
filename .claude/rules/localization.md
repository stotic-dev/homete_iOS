---
paths:
  - "LocalPackage/Sources/**/*.swift"
  - "LocalPackage/Tests/**/*.swift"
---

# 文言のローカライズのルール

画面・通知に出す文言は、日本語の文言をキーにして各モジュールの`Localizable.xcstrings`から引く（[ADR-0040](../../doc/adr/0040-localization-with-per-module-string-catalogs.md)）。
書き方の詳細と訳を入れる手順は [doc/localization.md](../../doc/localization.md) が正。

## 必須事項

**`LocalPackage`の中で文言のリテラルを書くときは、必ずそのモジュールのbundleを指定する。** 指定しないとアプリ本体の
bundleを引き、ビルドもテストも通るのに訳が使われない（英語の端末でも日本語のまま表示される）。

```swift
// ✅
Text("家事を追加", bundle: #bundle)
Button(.localized("閉じる")) { … }
.navigationTitle(.localized("メモ"))
SectionCard(.localized("担当者")) { … }

// ❌ アプリ本体のbundleを引いてしまう
Text("家事を追加")
Button("閉じる") { … }
```

- 文言を受け取る共通コンポーネントの引数・文言を返すプロパティは`String`や`LocalizedStringKey`ではなく`LocalizedStringResource`にする
- 文の断片をつなげて1文にしない（語順が言語で変わる）。条件ごとに1文ずつの文言にする
- 1〜2文字の文言など意味を取り違えやすいものには`comment:`を付ける（Generate Translationの精度が上がる）
- ユーザーが入力した文字（家事の名前・コメント・カテゴリ名）は翻訳しない
- 文言を足す・変えたら、同じ変更で`Localizable.xcstrings`に英訳を入れ、古いキーを消す。`make check-translations`で抜けを確かめる
  （日本語がキーなので、書き換えると新しいキーには訳が無い。詳細は`ux-writing.md`の原則5）

## テスト

`swift test`のランナーはローカライズを持たず、言語を指定しないと**英語の訳**になる。訳が入った後もテストが落ちないよう、
文言を確かめるときは日本語を指定して文字列にする。

```swift
let actual = rule.label.resolved(locale: Locale(identifier: "ja"))
```

文面そのものではなく「通知の種類と差し込む値」のように言語に依存しない値で比較できる設計にできるなら、そちらを優先する（`PushNotificationContent`が実例）。
