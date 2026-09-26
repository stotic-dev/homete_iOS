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
