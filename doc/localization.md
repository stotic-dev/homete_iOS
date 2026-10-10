# ローカライズ

> 日本語の文言をキーにしてモジュールごとにString Catalogを置く方式を採用した経緯は [ADR-0040](adr/0040-localization-with-per-module-string-catalogs.md) を参照。

## 構成

| 対象 | 置き場所 | 元の言語 |
|---|---|---|
| 画面の文言・通知の文面（`LocalPackage`） | 各モジュールの`Localizable.xcstrings` | 日本語（`defaultLocalization: "ja"`） |
| 権限ダイアログの文言（`Info.plist`） | `homete/Resouces/InfoPlist.xcstrings` | 英語（アプリ本体の開発言語） |
| App Storeのメタデータ | `fastlane/metadata/<言語>/` | 日本語（`ja`）と英語（`en-US`）を別々に書く |

String Catalogを持つモジュールは`LocalPackage/Package.swift`の`localizableStrings()`をresourcesに指定している。
文言を持つモジュールを新しく足したら、空の`Localizable.xcstrings`（`sourceLanguage`は`ja`）を置いて同じ指定を足す。

## 文言の書き方

キーは日本語の文言そのもの。**パッケージの中では必ずそのモジュールのbundleを指定する。** 指定しないとアプリ本体の
bundleを引き、ビルドは通るのに訳が使われない（日本語のまま表示される）。

| 使う場所 | 書き方 |
|---|---|
| `Text` | `Text("家事を追加", bundle: #bundle)` |
| `bundle`を受け取れないAPI（`Button`・`Label`・`TextField`・`Toggle`・`Picker`・`Section`・`Tab`・`navigationTitle`・`alert`・`accessibilityLabel`・Chartsの`.value`など） | `Button(.localized("閉じる")) { … }` |
| 共通コンポーネント（`SectionCard`・`DescriptionPopoverButton`など）の引数 | `SectionCard(.localized("担当者")) { … }` |
| 文言を返すプロパティ・関数 | 戻り値を`LocalizedStringResource`にして`.localized("…")`を返す |
| 画面の外で文字列が必要な箇所（通知の文面・共有する文など） | `LocalizedStringResource.localized("…").resolved()` |

`LocalizedStringResource.localized`は`HometeDomain`にある。デフォルト引数の`#bundle`が**呼び出し元で**展開されるため、
どのモジュールから呼んでもそのモジュールのCatalogを引く。

### 翻訳しやすくするために

* **文の断片をつなげない。** 「`\(単位)獲得ポイント`」のように語をつなげると、英語では語順が合わない。条件ごとに1文ずつの文言にする
* **短くて意味が取りにくい文言には`comment`を付ける。** 曜日の略称「月」（Monday）と「月」（month）のように、1〜2文字の文言は取り違えやすい

  ```swift
  .localized("月", comment: "曜日を選ぶボタンに出すMondayの1文字の略称")
  Text("あり", bundle: #bundle, comment: "メモが書かれているか")
  ```

* 値を差し込むときは文字列の連結ではなく補間を使う（`.localized("毎月\(day)日")`）。Catalogには`毎月%lld日`のように入る
* 三項演算子で`Text`に渡すとコメントが片方にしか付かない。`Text`を2つに分ける
* ユーザーが入力した文字（家事の名前・コメント・カテゴリ名）は翻訳しない。`Text(verbatim:)`や`String`のまま表示する
* デバッグメニューなど開発者だけが見る文言は翻訳しなくてよい

## 訳を入れる手順

1. Xcodeで`homete`スキームをビルドする。コード中の文言が各モジュールの`Localizable.xcstrings`へ自動で抽出される
2. Xcodeで対象の`Localizable.xcstrings`を開き、英語（English）が無ければ左下の「+」から追加する
3. 英語を選び、未翻訳の文言に対して「Generate Translation」を実行する
4. 訳を確認し、UXライティングのルール（`.claude/rules/ux-writing.md`）に照らして不自然なものは手で直す
5. 変更した`Localizable.xcstrings`をコミットする

Xcodeを使わずにCatalogへ抽出だけしたい場合は、`swift build`が出力する`.stringsdata`を`xcstringstool`で取り込める
（Xcodeのビルド時の同期と同じ処理）。

```bash
B=LocalPackage/.build/out/Intermediates.noindex/LocalPackage.build/Debug-iphonesimulator
xcrun xcstringstool sync LocalPackage/Sources/HometeUI/Localizable.xcstrings \
  --stringsdata $B/HometeUI-t.build/Objects-normal/arm64/*.stringsdata
```

## 訳の言語の決まり方

訳の言語はOSの言語設定そのものではなく、**実行中のアプリ（メインbundle）が対応している言語**から選ばれる。
パッケージの訳もアプリ本体と同じ言語にそろう。

* アプリ本体（`homete`）とNotification Service Extensionは、`Info.plist`の`CFBundleLocalizations`で`en`・`ja`を明示している。
  拡張は文字列カタログを持たないため、明示しないと常に英語になる
* 日本語・英語以外の言語の端末では、アプリ本体の開発言語（`en`）で表示される
* `swift test`のランナーはローカライズを持たないため、**テストでは言語を指定しないと英語の訳になる**。
  文言を確かめるテストは`resolved(locale: Locale(identifier: "ja"))`で日本語を指定する
* VRTは`-AppleLanguages (ja)`で日本語に固定している（`hometeVRTHost`の`CFBundleLocalizations`も参照）

## 同居人へのプッシュ通知

送る側の端末で文面を組み立てて送るため、そのままでは受け取る側と言語が違うと読めない。

* 送る側は、自分の言語の`title`/`body`に加えて、通知の種類と差し込む値（`PushNotificationContent.Message`）をJSONにしてdataの`message`に載せる
* 受け取った端末のNotification Service Extensionが`message`を読み、受け取った側の言語で`title`/`body`を組み立て直す
* `message`を持たない通知（古いアプリから届いたもの）は、届いた文面のまま表示する

通知の種類を増やすときは`PushNotificationContent.Message`にケースを足し、`title(locale:)`/`body(locale:)`に文面を書く。
Cloud Functions（`notifyothercohabitants`）はdataを中継するだけなので変更は要らない。
