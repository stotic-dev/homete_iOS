# ローカライズ

> 日本語の文言をキーにしてモジュールごとにString Catalogを置く方式を採用した経緯は [ADR-0042](adr/0042-localization-with-per-module-string-catalogs.md) を参照。

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
| `bundle`を受け取れないAPI（`Button`・`Label`・`Toggle`・`Picker`・`Section`・`navigationTitle`・`alert`・`accessibilityLabel`・Chartsの`.value`など） | `Button(.localized("閉じる")) { … }` |
| `TextField`・`Tab`（`LocalizedStringResource`を受け取る初期化がiOS 26以降にしか無い） | ラベルを`Text`で渡す。`TextField(text: $name) { Text("カテゴリの名前", bundle: #bundle) }` |
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

キーは日本語の文言そのものなので、**日本語を書き換えると別の文言として扱われる。** 新しいキーには英訳が無く（英語の端末で日本語のまま表示される）、
古いキーは使われないまま訳ごと残る。文言を足す・変えるときは、同じ変更で英訳も入れる。

1. ビルドして、コード中の文言を各モジュールの`Localizable.xcstrings`へ取り込む（Xcodeならビルド時に自動。Xcodeを使わない場合は下記の`xcstringstool sync`）
2. 新しいキーに英訳（`en`、`state`は`translated`）を入れる。Xcodeの「Generate Translation」を使っても、Catalogを直接編集してもよい
3. 書き換える前の古いキーが残っていれば消す（`extractionState`が`stale`のもの）
4. `make check-translations`で、英訳の抜けと使われなくなった文言が無いことを確かめる
5. 変更した`Localizable.xcstrings`を、文言を変えたコードと同じコミットに含める

Xcodeを使わずにCatalogへ抽出だけしたい場合は、`swift build`が出力する`.stringsdata`を`xcstringstool`で取り込める
（Xcodeのビルド時の同期と同じ処理）。訳の無い古いキーはこのとき消える。

```bash
B=LocalPackage/.build/out/Intermediates.noindex/LocalPackage.build/Debug-iphonesimulator
xcrun xcstringstool sync LocalPackage/Sources/HometeUI/Localizable.xcstrings \
  --stringsdata $B/HometeUI-t.build/Objects-normal/arm64/*.stringsdata
```

### 英訳の書き方

日本語を1語ずつ置き換えず、英語のアプリとして自然な言い方にする（UXライティングのルールの「英語の構文をそのまま日本語化しない」の逆向き）。

* ボタン・見出しはTitle Case（`Add Chore`、`View Premium Plan`）、説明文・メッセージは文の形（`No chores for today`）
* 敬称の「さん」は付けない（`%@さん` → `%@`）。名前を並べる区切りの「・」は`, `
* 数を含む文言は複数形を分ける（`variations.plural`の`one`/`other`。例: `%lld chore` / `%lld chores`）
* 値が2つ以上ある文言は、日本語の訳と同じ位置指定（`%1$@`・`%2$lld`）を使い、英語の語順に並べ替える（`全%1$lldステップ中%2$lldステップ目` → `Step %2$lld of %1$lld`）
* 1つの日本語キーが英語では訳し分けが必要になる場合（「月」= Month と「/ 月」= /month など）は、訳で無理に合わせずコードを1文ずつの文言に分ける
* プレビュー・デバッグメニューだけで使う文言は訳さず、`shouldTranslate`を`false`にする

用語は既存の訳とそろえる。

| 日本語 | 英語 |
|---|---|
| 家事 | chore |
| いつもの家事 | Go-to Chores（文中は go-to chores） |
| 家事テンプレート | Chore Templates |
| 同居人 / パートナー / グループ | housemate / partner / group |
| ありがとう（を伝える） | Thanks（Say Thanks） |
| がんばり（ふつう / がんばった / すごくがんばった） | Effort（Normal / Worked Hard / Went All Out） |
| 完了 / 未完了 / やらない | Done / To Do / Won't Do |
| メモ | Note |
| ポイント（数値の後） | Points（`%lldpt`） |
| プレミアムプラン / 無料プラン | Premium Plan（文中は Premium） / Free Plan |
| ふりかえり通知 | Daily Recap |
| 退会 | Delete Account |

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
