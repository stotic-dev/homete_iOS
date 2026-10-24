## タイトル: FCMトークンはAccount本体から分け、本人だけが読める`Account/{uid}/Private/fcm`に置く

* **ステータス: 承認済**
* 意思決定者: stotic-dev
* 日付: 2026-10-12
* 関連: [Issue #241](https://github.com/stotic-dev/homete_iOS/issues/241)、#233（セキュリティルールの厳格化）

## 文脈、背景や問題点の説明

`CohabitantStore`がメンバー一覧の`userName`を表示するため、同じグループのメンバーは互いの`Account`ドキュメントを読める。
Firestoreのルールはフィールド単位で読み取りを制限できないので、同じドキュメントにある`fcmToken`も同居人から読めていた。
FCMトークンは通知の送信先そのものなので、本人以外が読めない場所に置きたい。

## 決定事項

* FCMトークンは`Account/{uid}/Private/fcm`（フィールドは`token`）に置き、`Account`本体には持たない
  * ルールは`Private`配下への書き込み（作成・更新）を本人にだけ許す。アプリはトークンを書くだけで読み返さないので、本人にも読み取りは許さない
  * 書き込めるのは`Private/fcm`だけで、中身も`token`（文字列）だけに絞る。退会時に消すのは`fcm`だけなので、ほかのドキュメントを作れると退会後も残ってしまう
  * 通知の配信（`notifyothercohabitants`）はAdmin SDKで読むので、ルールの影響を受けない
* アプリはトークンを受け取るたびに、`Private/fcm`への書き込みと`Account.fcmToken`の削除を1つのバッチで行う
  * 既存ユーザーの値の移行はこれで済ませる。移行用のFunctionsは作らない。旧フィールドは新しいアプリで起動すれば消える
* 旧バージョンのアプリは引き続き`Account.fcmToken`へ書く。旧アプリの利用者にも通知を届けるため、Functionsは`Private/fcm`を優先し、無いユーザーだけ`Account.fcmToken`を読む
  * 旧アプリの書き込みを拒否すると、`Account`全体の保存（プレミアム状態の更新など）ごと失敗するため、ルールで`fcmToken`の書き込みは禁止しない
* 退会時（`deleteuserdata`）は`Private/fcm`も消す。Firestoreは親ドキュメントを消してもサブコレクションを消さないため

## 考慮した選択肢

* A. `fcmToken`をサブコレクションへ分ける（採用）
* B. `userName`を`Cohabitant`ドキュメントへ非正規化し、`Account`を本人だけが読めるようにする
* C. 移行用のFunctionsを1回実行し、既存の`Account.fcmToken`を一括で移す

## 決定結果

### 決定にあたり考慮したメリット

* 守りたいのは`fcmToken`なので、それだけを分ければ済む。Bは改名のたびに2箇所を更新する必要があり、`userName`が同居人から見えることも変わらない
* 移行をアプリの起動に任せるので、デプロイ手順が増えない（Cと比べて）。トークンは起動のたびに受け取るので、書き直す機会はすぐに来る

### 決定にあたり考慮したデメリット

* 新しいアプリで起動するまで、そのユーザーの`Account.fcmToken`は同居人から読めるまま残る
* 旧アプリの利用者がいる間は、Functionsのフォールバックとルールの緩さを残しておく必要がある。強制アップデート（`minimum_required_version`）で旧アプリがいなくなったら、フォールバックを消し、ルールで`Account`への`fcmToken`の書き込みを拒否する
* アプリはトークンを受け取るたびに書き込む（以前は変わったときだけ書いていた）。比べる値を`Account`に持たなくなったため。起動ごとに1回程度なので許容する
* 新しいアプリより先に、ルールとFunctionsをデプロイしておく必要がある。ルールが無いと`Private/fcm`への書き込みが拒否され、Functionsが古いと新しいアプリの利用者に通知が届かない

## 参考

* [`firebase/firestore.rules`](https://github.com/stotic-dev/homete_backend/blob/main/firebase/firestore.rules)（`match /Account/{userId}` 配下の `Private`）
* [`firebase/functions/src/models/FirestoreHelper.ts`](https://github.com/stotic-dev/homete_backend/blob/main/firebase/functions/src/models/FirestoreHelper.ts)（`getFcmTokensByUserIds`）
* `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplAccountInfoClient.swift`（`updateFcmToken`）
