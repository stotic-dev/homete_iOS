## タイトル: 匿名認証で始めて、パートナー登録の後にAppleアカウントと連携する

* **ステータス: 承認済**
* 意思決定者: 佐藤汰一
* 日付: 2026-10-18
* 技術的背景: [Issue #461](https://github.com/stotic-dev/homete_iOS/issues/461)、[doc/strategy/onboarding-before-login.md](../strategy/onboarding-before-login.md)、[ADR-0017](0017-create-cohabitant-on-invitation-join.md)

## 文脈、背景や問題点の説明

初回起動ではいきなりSign in with Appleを求めており、アプリの価値が伝わる前にログインで離脱している可能性が高い。
ログインの前にニックネームとパートナー登録まで進めてもらえれば、ここまで進めたことを手放したくない気持ちが働いて離脱を抑えられる。
しかしパートナー登録（P2P登録・招待リンクの発行と参加）は、Firestoreルールもcallableも`request.auth.uid`で本人とメンバーを判定するため、認証なしでは行えない。

ログインの前にパートナー登録まで済ませるには、どう認証すればよいか。

## 決定事項

* 「はじめる」でFirebaseの匿名認証にサインインし、匿名のuidでアカウント登録・パートナー登録を行う
* パートナー登録で行動した直後（招待の共有を完了・P2P登録が完了・参加が完了）に、`link(with:)`でAppleの認証情報を同じuidに紐づける。この連携はスキップできない
* パートナー登録を後回しにした人は匿名のまま未参加ホームに入れる。匿名でグループに参加した状態は、起動状態（`LaunchState.accountLinkRequired`）で連携の画面に固定し、ホームに入れない
* 購入の前には必ずApple連携を求める
* Apple IDが既存のアカウントで使われていたら、匿名のアカウントを削除してから既存のアカウントでログインする（匿名で作った内容は引き継がない）
* 匿名のアカウントの削除（退会・既存のアカウントへの切り替え）は、callable（`deleteanonymousaccount`）でサーバー側から行う。匿名のアカウントは再認証できず、最後のサインインから時間がたつと端末からの削除が`requires-recent-login`で失敗するため
* 最後に使われてから30日たった匿名アカウントは、定期実行のFunction（`cleanupanonymousaccounts`）で削除する。データの後片付けは既存の`deleteuserdata`に任せる
  * 匿名のアカウントは使い続けてもサインインし直さず、最終サインイン日時が作成時のまま動かない。使われているかはIDトークンの最終更新日時（`lastRefreshTime`）で判定する
  * `deleteUsers`でまとめて削除すると削除トリガーが呼ばれないため、1件ずつ削除する

## 考慮した選択肢

* **選択肢1: 今のまま最初にAppleでログインし、説明画面だけ足す**
  * 影響範囲は小さいが、ログインの手前で離脱する問題は残る
* **選択肢2: ログイン前は端末内だけで登録内容を持ち、ログイン時にサーバーへ登録する**
  * ニックネームは端末内に持てるが、パートナー登録は相手の端末とサーバーを介すため、端末内だけでは完結しない
* **選択肢3: 匿名認証で始め、パートナー登録の後に必ずApple連携する（採用）**
  * ルールとcallableはuidしか見ていないため変更が要らない。連携でuidが変わらないので、グループ・家事・RevenueCatの紐付けもそのまま
* **選択肢4: 匿名のまま使い続けられるようにし、連携は任意で促す**
  * 離脱はさらに減るが、機種変更・アンインストールでグループや家事のデータを失う。退会・購入・設定などアプリ全体で匿名を考慮する必要が出る

## 決定結果

### 決定にあたり考慮したメリット

* ニックネームとパートナー登録まで、Appleの認証を挟まずに進められる
* 連携してもuidが変わらないため、サーバー側のデータの移し替えが要らない
* 匿名でグループに参加した状態をアプリ本体に持ち込まないので、ホーム以降の画面は匿名を考慮しなくてよい

### 決定にあたり考慮したデメリット

* 未参加ホーム・設定・Paywallの起点では匿名を考慮する必要がある（ログアウトを連携に置き換える、退会で再認証を飛ばす、購入の前に連携する）
* Apple連携の画面で離脱した人は、匿名のままグループに入っていることがある。その場合、相手のグループには30日間使われないメンバーが残る
* 既存のApple IDと衝突したら、匿名で作った内容（グループを含む）は捨てることになる
* 匿名認証のプロバイダをstg / prodの両方で有効にする必要がある
* 定期実行のFunctionのために、Cloud Schedulerを使う

## 参考

* [Firebase: Authenticate with Firebase Anonymously on Apple Platforms](https://firebase.google.com/docs/auth/ios/anonymous-auth)
* [Firebase: Link Multiple Auth Providers to an Account on Apple](https://firebase.google.com/docs/auth/ios/account-linking)
* `firebase/firestore.rules`
* `firebase/functions/src/deleteUserData.ts`
