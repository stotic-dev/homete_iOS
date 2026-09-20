## タイトル: 招待リンクからのグループ作成は発行時ではなく参加時に行う

* **ステータス: 承認済**
* 意思決定者: 佐藤汰一
* 日付: 2026-09-20
* 技術的背景: [ADR-0013](0013-cohabitant-invitation-universal-link.md)、[doc/strategy/cohabitant-invitation-link.md](../strategy/cohabitant-invitation-link.md)

## 文脈、背景や問題点の説明

招待リンク導入時（ADR-0013）は、発行者がグループ未所属なら `issuecohabitantinvitation` が**発行時点で本人ひとりのグループを作成**し、`Account.cohabitantId` に紐づけていた。招待ドキュメントに参加先のグループIDを持たせるための単純な設計だったが、次の問題がある。

* 「リンクで招待」をタップしただけで（共有をキャンセルしても・誰も参加しなくても）グループが作られ、アプリはその瞬間から「グループ参加済み」として振る舞う。ダッシュボードにはメンバーのいない家事画面が出て、同居人登録画面へ戻る導線を失う
* 誰も参加しないひとりグループが Firestore に残り続ける
* クライアントは発行結果の `cohabitantId` をオンメモリの `Account` に手で反映する必要があり（`applyCohabitantId`）、サーバーとクライアントの状態同期が発行フローに紛れ込んでいた

グループを「いつ」作るべきか。

## 決定事項

* `issuecohabitantinvitation` はグループを作らない。発行者が未所属なら `Invitation.cohabitantId` を `null` で保存する
* `joincohabitant` が参加先を決める。`Invitation.cohabitantId` → 発行者の現在の `Account.cohabitantId`（発行後にP2P登録などで所属した場合）→ どちらも無ければ**発行者と参加者の2人でグループを新規作成**する
* 新規作成したグループIDは `Invitation.cohabitantId` にも書き戻し、同じリンクからの2人目以降が同じグループへ入るようにする
* 発行者側は、相手の参加でサーバーが自分の `Account.cohabitantId` を書き換えるため、サインイン中は自分の `Account` ドキュメントを購読する（`AccountStore.startObservingIfNeeded`）。購読の開始・停止はサインイン／登録／サインアウトを束ねる `AuthSubscriptionSyncUseCase` に置く
* 参加でメンバーが増えたら、`joincohabitant` が参加者以外のメンバー全員（発行者と、同じリンクから先に参加したメンバー）へ Push 通知を送る。発行時に何も起きなくなった分、アプリを開いていない発行者が参加を知る手段として必要になる。通知の失敗で参加を失敗扱いにはしない

## 考慮した選択肢

* **選択肢1: 発行時に作る（従来）**
  * 実装は単純だが、上記の通り「タップしただけで参加済み扱い」になる
* **選択肢2: 共有シートで共有を完了したタイミングでクライアントが作る**
  * `UIActivityViewController` の完了コールバックで `Cohabitant` を作成する
  * 共有「完了」はOS側の通知に過ぎず、相手に届いたことも参加することも保証しない。ひとりグループが残る問題は解消しない
  * クライアント側での作成処理が P2P登録（リーダーが作成）と招待で二重になる
* **選択肢3: 参加時にサーバーが作る（採用）**
  * グループは常に2人以上の状態で生まれ、「参加メンバーがいないグループ」が存在しない。未参加画面の表示条件を `Account.cohabitantId` の有無のまま保てる
  * トランザクション内で作成・紐づけまで完結し、クライアントの手動同期が不要になる
  * 代わりに、発行者が自分の `Account` の変化をサーバーから受け取る仕組み（購読）が必要になる

## 決定結果

### 決定にあたり考慮したメリット

* 招待リンクをタップしただけの状態では何も変わらず、同居人登録画面から P2P登録・再共有のどちらにも進める
* ひとりグループが作られないため、`Cohabitant` に「メンバーがいないグループを未参加として扱う」ような表示ロジックを足さずに済む
* 発行者が発行後に別経路でグループに入っていても、参加者はその時点の発行者のグループへ入れる

### 決定にあたり考慮したデメリット

* 発行時点では招待先が確定しないため、発行者が退会した後にリンクを開くと参加先を作れず `cohabitant-not-found`（無効なリンク）として扱う
* 自分の `Account` を購読するリスナーが常時1本増える。読み取りは自分のドキュメント1件のみで、Firestore ルール上も `get` は本人に許可済み
* 発行者自身が自分の招待リンクを開いた場合、参加先が無いときは `cohabitant-not-found` として扱う（自己参加は成立しないため）

## 参考

* `firebase/functions/src/models/InvitationManager.ts`
* `firebase/functions/test/e2e/cohabitantInvitation.test.ts`
* `LocalPackage/Sources/HometeDomain/Account/AccountStore.swift`
* `LocalPackage/Sources/HometeDomain/UseCase/AuthSubscriptionSyncUseCase.swift`
