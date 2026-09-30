## タイトル: 家事の入力履歴をAppStorageからSQLite（GRDB）へ移す

* **ステータス: 承認済**
* 意思決定者: stotic-dev
* 日付: 2026-09-30
* 技術的背景: [Issue #280](https://github.com/stotic-dev/homete_iOS/issues/280)（家事の入力履歴でポイントも復元する）

## 文脈、背景や問題点の説明

家事の登録シート「新しく入力」タブの入力履歴は、家事の名前（`[String]`）だけを`@AppStorage`にJSON文字列として持っていた。そのため履歴から復元しても完了ポイントが戻らず、毎回ポイントを入れ直す必要があった。

履歴に持たせる情報を増やすとなると、`UserDefaults`に構造体をJSON文字列で押し込む今の形は限界に近い。値を1つ足すたびに`RawRepresentable`の手書きエンコード・デコードを直し、旧形式との互換も自分で面倒を見ることになる。履歴という「行が増えていく一覧」を置く器として適切なのはどれか。

## 決定事項

* 入力履歴の永続化先を`UserDefaults`から端末内のSQLiteに移し、SQLiteラッパーには **GRDB.swift 7.11.1** を使う
* 履歴の要素を`String`から`HouseworkEntryHistoryItem`（名前 + 完了ポイント）に変え、履歴タップ時はポイントも復元する
* **並び順はドメインの値型（`HouseworkHistoryList`）が持ち、DBは並び順を含めて保存するだけにする。** 「最後に使ったものを先頭に出す」判断をSQLに寄せず、`HometeDomainTests`でユニットテストできる場所に残す
* 旧`@AppStorage`の履歴は、DBの初回読み出し時に取り込んでキーを削除する。ポイントは登録フォームの初期値（10）で埋める
* 履歴の保持件数に上限は設けず、これまでどおり無制限に積む

## 考慮した選択肢

* **SwiftData** — Apple純正で内部もSQLite。追加依存ゼロで済む。一方で`@Model`はクラスとマクロ前提のため、`HometeDomain`の値型 + Clientプロトコルという既存の層構成に馴染ませにくく、Swift 6のactor分離（`ModelActor`）の扱いも持ち込むことになる
* **SQLite3（libsqlite3）を直接叩く** — 依存を増やさず完全に制御できるが、SQL文とバインド処理・マイグレーション管理を手書きすることになり、履歴1テーブルのために持つコード量に見合わない
* **GRDB.swift（採用）** — SQLiteラッパーのサードパーティ。マイグレーション機構・型安全なクエリ・`async`API・`Sendable`対応が揃っている

## 決定結果

### 決定にあたり考慮したメリット

* 履歴に持たせる値を増やすときは、レコードの型とマイグレーションを1つ足すだけで済む。旧形式の互換を手書きするコストが消える
* `DatabaseMigrator`によってスキーマ変更の履歴がコードに残り、既存ユーザーの端末への適用も同じ仕組みに乗る
* `DatabaseQueue`が読み書きを直列化し`Sendable`なため、Swift 6のstrict concurrency下で追加のロックを書かずに済む
* 端末ローカルのDB基盤（`AppDatabase`）ができたので、今後「同居人と共有しないがFirestoreに置くほどでもないデータ」の置き場所が定まる

### 決定にあたり考慮したデメリット

* SPMの依存が1つ増える。プロジェクトはDIなど自作方針を採ってきたため、方針としては例外に当たる
* DBへの読み書き自体はユニットテストの対象外になる（`HometeInfrastructure`はFirebase一式を抱えており、テストターゲットを新設するコストが見合わない）。並び順のロジックをドメイン側に残したのはこの制約への対処でもある
* 旧`@AppStorage`から移行した履歴のポイントは実際に登録したときの値ではなく一律10になる。履歴から復元したあとにポイントを直せば、次回以降は正しい値が残る

## 参考

* [GRDB.swift](https://github.com/groue/GRDB.swift)
* `LocalPackage/Sources/HometeInfrastructure/LocalDatabase/`
* `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkHistoryList.swift`
