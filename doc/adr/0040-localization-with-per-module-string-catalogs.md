## タイトル: 英語対応のため、日本語の文言をキーにしたString Catalogをモジュールごとに置く

* **ステータス**: 承認済
* 意思決定者: stotic-dev
* 日付: 2026-10-10
* 関連: [ADR-0001](0001-spm-multimodule-structure.md)（マルチモジュール構成）、[ADR-0021](0021-daily-completion-reminder-on-device.md)（Notification Service Extension）、[ADR-0029](0029-vrt-dedicated-host-app-target.md)（VRT専用ホストのローカライズ）

## 文脈、背景や問題点の説明

アプリの文言を英語でも表示したい。文言のほとんどは`LocalPackage`のSwiftコードに日本語のリテラルとして書かれていた。
`Text("家事")`は`LocalizedStringKey`として扱われるが、SPMパッケージの中では`bundle`を指定しないと
アプリ本体（`Bundle.main`）を引くため、訳を用意してもどの言語でも表示されない状態だった。
また、同居人へのプッシュ通知は送る側の端末で文面を組み立てているため、受け取る側と言語が違うと読めない。

## 決定事項

* 日本語の文言をそのままキーにする。`LocalPackage`は`defaultLocalization: "ja"`とし、英語などの訳はXcodeの「Generate Translation」で入れる
* String Catalog（`Localizable.xcstrings`）は文言を持つモジュールごとに置き、呼び出し側で`#bundle`を指定してそのモジュールのCatalogを引く
  * `Text`は`Text("…", bundle: #bundle)`
  * `bundle`を受け取れないAPI（`Button`・`navigationTitle`・`alert`など）や共通コンポーネントには`LocalizedStringResource.localized("…")`を渡す。
    デフォルト引数の`#bundle`が呼び出し元で展開される（SE-0422）ため、呼び出し元モジュールのCatalogを引ける
  * 文言を受け取る共通コンポーネント・ドメインの表示用プロパティの型は`LocalizedStringResource`にする
* 画面の外で文字列が必要な箇所（通知の文面など）は`LocalizedStringResource.resolved(locale:)`で文字列にする
* 同居人へのプッシュ通知は、文面に加えて通知の種類と差し込む値をdataに載せる。受け取った端末の
  Notification Service Extensionが、受け取った側の言語で文面を組み立て直す
* アプリ本体の開発言語は`en`のまま変えない（日本語・英語以外の端末では英語で表示する）。権限ダイアログの文言は
  `InfoPlist.xcstrings`に英語を元の文言として置く

## 考慮した選択肢

* **キーの持ち方**
  * 日本語の文言をそのままキーにする（採用）
  * 英語の文言をキーにする — 全文言の書き換えになり、UXライティングのルール（日本語の文言が基準）との対応も追いにくい
  * 意味ベースのID（`home.tab.dashboard`）をキーにする — 文言の変更には強いが、コード上で表示される文言が読めなくなる
* **Catalogの配置**
  * モジュールごとに置く（採用） — ビルド時の自動抽出がモジュールごとに効く
  * `HometeResources`に1つにまとめる — 自動抽出が効かず、キーを手で管理することになる
* **プッシュ通知の言語**
  * 受け取った端末のNotification Service Extensionで組み立て直す（採用） — Cloud Functionsを変えずに済み、古いアプリには送った側の文面がそのまま届く
  * APNsの`loc-key`/`loc-args`で送る — Cloud Functionsの改修が要り、キーを持たない古いアプリではキーがそのまま表示されうる
* **`bundle`の指定方法**
  * すべての呼び出しで`LocalizedStringResource("…", bundle: #bundle)`と書く — 記述が長く、書き漏れやすい
  * 文言をアプリ本体のCatalogにまとめ、`bundle`を指定しない — Xcodeの自動抽出がパッケージから本体のCatalogへは効かない

## 決定結果

### 決定にあたり考慮したメリット

* 既存の日本語の文言がそのままキーになるため、日本語の表示は変わらず、VRTの参照スナップショットにも差分が出ない
* 文言の追加・変更はコードを書いてXcodeでビルドすればCatalogへ反映され、Generate Translationで訳を入れられる
* 同居人ごとに表示の言語が違っても、通知はそれぞれの言語で届く

### 決定にあたり考慮したデメリット

* 文言を書くたびに`bundle: #bundle`か`.localized`が要る。書き漏れてもビルドは通り、日本語のまま表示されるだけなので気付きにくい
  （`.claude/rules/localization.md`で新規の文言の書き方を定める）
* 訳の言語は実行中のアプリ（メインbundle）が対応している言語で決まる。ローカライズを持たない`swift test`のランナーでは常に英語になるため、
  文言を確かめるテストは`resolved(locale:)`で言語を指定する必要がある
* `LocalizedStringResource.localized`は`comment`を抽出させるために`@_semantics("string.init_localized")`を付けている。
  アンダースコア付きの属性のため、将来のSwiftで挙動が変わる可能性がある
* 日本語の文言をキーにしているため、日本語の文言を変えると訳を入れ直す必要がある

## 参考

* [doc/localization.md](../localization.md)
* [SE-0422: Expression macro as caller-side default argument](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0422-caller-side-default-argument-macro-expression.md)
