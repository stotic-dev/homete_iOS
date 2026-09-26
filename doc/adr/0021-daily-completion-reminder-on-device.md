## タイトル: 今日の完了家事のふりかえり通知を、サーバーの定期実行を使わず端末側で予約する

* **ステータス: 提案済**
* 意思決定者: 佐藤汰一、Claude Code
* 日付: 2026-09-25
* 技術的背景: 当日に完了した家事がある日だけ、ユーザーが決めた時刻に確認（ふりかえり）の通知を出したい

## 文脈、背景や問題点の説明

「今日完了した家事があるか」は同居人の操作でも変わるため、通知を出す瞬間に条件を判定する必要がある。
iOSのローカル通知は予約時点で内容が固定され、発火時に条件を確かめる仕組みがない。
一方で、1日1件の通知のためにサーバーを定期実行し続けるのはコストに見合わない。

## 決定事項

* 条件を満たした時点で、各端末がその日の通知を1件だけローカル通知として予約する（識別子を日付ごとに固定し、何度予約しても上書きされるようにする）
* 予約のきっかけは次の2つ
  * アプリで家事一覧を購読している間に、今日の完了家事が見つかったとき（`HouseworkListStore`）。0件に戻れば取り消す
  * アプリが起動していない間に、同居人が今日の家事を完了したときの通知が届いたとき（Notification Service Extension）
* 家事の完了通知には`data`（種類と家事の日付）を載せ、`mutable-content`付きで送る。拡張は通知の内容を書き換えず、予約だけ行う
* 通知の設定（ON/OFF・時刻）と「今日完了があったか」はApp GroupのUserDefaultsに保存し、アプリ本体と拡張で共有する
* ローカル通知のlive実装は、拡張からも使えるようFirebaseに依存しない`HometeLocalNotification`モジュールに置く

## 考慮した選択肢

* Cloud Functionsの`onSchedule`で15分おきに対象ユーザーを探し、今日の完了件数を数えてFCMで送る
* 家事の完了時にCloud Tasksで各メンバーの指定時刻にタスクを登録し、実行時に件数を確認してFCMで送る
* 端末側のローカル通知のみ（アプリ起動中にだけ予約する）
* 端末側のローカル通知 + Notification Service Extensionで完了通知の受信時にも予約する（採用）

## 決定結果

### 決定にあたり考慮したメリット

* サーバー側の追加処理がない。既存の完了通知にフラグとdataを足すだけで、Firestoreの読み取りも定期実行も増えない
* 家事が完了した日にだけ、その端末で処理が走る
* 同居人が完了した家事は自分の端末では操作していないが、完了通知をきっかけに拡張が起動するため、アプリを開いていなくても予約できる

### 決定にあたり考慮したデメリット

* 拡張からの`UNUserNotificationCenter.add`は、Appleのドキュメント上禁止されていないが、明示的な保証もない。iOS 12のベータで一時的に拒否された事例がある（Apple Developer Forums thread/108340）ため、OSの更新ごとに実機で確認が必要
* 端末の通知表示をオフにしている人の端末では拡張が起動しない（ただし、その人にはふりかえり通知も届かないため実害はない）
* 完了通知の受信後に完了が取り消されても、アプリを開くまで予約は残る
* 同居人間でタイムゾーンが異なる場合、「今日」の判定が端末ごとにずれうる
* App Group・拡張のバンドルIDの登録が必要になる

拡張からの予約がOSに拒否されるようになった場合は、Cloud Tasksで家事が完了した日だけサーバー側で予約する方式に切り替える。

## 参考

* [UNUserNotificationCenter | Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
* [UNNotificationServiceExtension | Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)
* [Apple Developer Forums thread/108340（iOS 12でのService Extensionからのローカル通知予約）](https://developer.apple.com/forums/thread/108340)
* [Handle background notification in terminated status app | Apple Developer Forums](https://developer.apple.com/forums/thread/744901)

## 追記（2026-09-26）

承認ステータスの廃止（#295）により、家事は実行者が直接「完了」にし、その時点で同居人へ完了通知が送られるようになった。予約のきっかけも承認通知から完了通知（`completedMessage` / `completedBulkMessage`）に移した。仕組みそのものは変わらない。

## 追記（2026-09-26）表示する完了通知の廃止とサイレント通知への置き換え

家事のステータスに関わる同居人への通知は、ふりかえり通知だけにする方針になった。これに合わせて、家事の登録時・完了時に送っていた表示する通知（`addNewHouseworkItem` / `completedMessage` / `completedBulkMessage`）を廃止した。ありがとう通知は残す。

完了通知は同居人の端末で予約するきっかけを兼ねていたため、代わりに次の仕組みにした。

* 家事を完了した端末は、表示しないサイレント通知（`content-available`、APNsのpush typeは`background`）で`data`だけを送る。`notifyothercohabitants`に`silent: true`を渡すと、`title` / `body`なしで送れる
* 受け取った端末はアプリをバックグラウンドで起こし、`AppDelegate`の`application(_:didReceiveRemoteNotification:)`で予約する。起動中は家事一覧の購読（`HouseworkListStore`）が予約するため、ここでは予約しない
* サイレント通知は今日の家事の完了でだけ送り、送った端末ごとに1日1回までにする（App GroupのUserDefaultsに送った日を記録する）。受け取った端末の予約は1日1件で足りるため、同じ日に何度送ってもサーバーの実行回数が増えるだけになる。送信に失敗した日は記録せず、次の完了で送り直す
* 古いアプリは引き続き`data`付きの表示する完了通知を送るため、Notification Service Extensionは残す

### この変更で増えたデメリット

* サイレント通知はOSの判断で遅れたり間引かれたりする。ユーザーがアプリをタスク一覧から終了していると届かない。届かなかった場合でも、その人がその日にアプリを開けば家事一覧の購読で予約される
* 1日1回の送信記録は端末ごとなので、同居人それぞれが家事を完了すると、その日のサイレント通知は人数分送られる（ベストエフォート）
* 1日のうち最初に完了した家事を送った後、その家事が未完了に戻されても、受け取った側の予約はアプリを開くまで残る

通知フィルタ権限（`com.apple.developer.usernotifications.filtering`）を取得すれば、表示する通知をNotification Service Extensionで握りつぶし、今と同じ確実さで予約できる。ただしAppleへの申請と承認が必要なため、今回は見送った。

## 追記（2026-09-26）サイレント通知をやめ、1日1回の表示する完了通知に戻す

実機で確かめたところ、ユーザーがアプリをタスク一覧から終了していると、サイレント通知ではアプリが起動せず予約できなかった。iOSの仕様で、強制終了されたアプリはユーザーが次に開くまでバックグラウンドで起動されない。

アプリが終了していても予約できるよう、完了は再び`data`付きの表示する通知（`mutable-content`、APNsのpush typeは`alert`）で送り、Notification Service Extensionで予約する。

* 表示する完了通知は、この端末から1日1回だけ送る（サイレント通知のときの送信制限をそのまま使う）。家事のステータスに関わる通知を増やさないという方針に対し、1日1件の表示は許容した
* 文言は以前の完了通知と同じ（「〇〇さんが家事を終えました」「「家事名」が完了しました」、一括完了は件数）
* `AppDelegate`でのサイレント通知の受信と、`notifyothercohabitants`の`silent`オプションは使わなくなったため削除した

### 通知を表示せずに拡張を起動する方法について

Notification Service Extensionが起動するのは、アラートを表示する通知に`mutable-content: 1`が付いている場合だけで、サイレント通知では起動しない。拡張でアラートの文言を消しても無視され、元の通知が表示される。表示させずに受け取るには、通知フィルタ権限（`com.apple.developer.usernotifications.filtering`）が必要になる。この権限はAppleへの申請と承認が必要なため、今回は1日1件の表示を受け入れる方針とした。

### この変更で解消・残るデメリット

* 解消: アプリを強制終了している同居人の端末でも、完了通知を受け取った時点で予約できる
* 残る: 端末の通知表示をオフにしている人の端末では拡張が起動しない（その人にはふりかえり通知も届かないため実害はない）
* 残る: 1日のうち最初に完了した家事を送った後、その家事が未完了に戻されても、受け取った側の予約はアプリを開くまで残る

## 参考（追記分）

* [UNNotificationServiceExtension | Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)
* [didReceive(_:withContentHandler:) | Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension/didreceive(_:withcontenthandler:))
* [com.apple.developer.usernotifications.filtering | Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.filtering)

## 追記（2026-09-26）コメント付きの完了は1日1回の対象外にする

* 家事の完了時にコメントを添えられるようにした（[#291](https://github.com/stotic-dev/homete_iOS/issues/291)、[実装方針](../strategy/housework-executor-selection.md)）。コメントは「ありがとう」と同じくユーザーが明示的に送るメッセージなので、1日1回の制限に従うと入力したコメントが送られずに消えてしまう
* コメントを入力した完了は毎回通知を送る。ふりかえり通知の予約用データは今までどおり「今日の家事で、その日まだ送っていない」ときだけ付け、付けたときだけ送った日を記録する
* コメントなしの完了は今までどおり1日1回。家事のステータスに関わる通知を増やさない方針の例外は、ユーザーがコメントを書いたときに限る
