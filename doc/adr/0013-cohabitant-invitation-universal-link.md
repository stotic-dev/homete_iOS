## タイトル: 離れた相手をグループへ招待する仕組みとして、Universal Link + サーバ発行の招待トークンを採用する

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-08-30
* 技術的背景: [Issue #182 グループ作成、メンバー追加時のアプリ共有機能](https://github.com/stotic-dev/homete_iOS/issues/182)

## 文脈、背景や問題点の説明

グループ登録は MultipeerConnectivity による近接P2Pのみで、「同じ場所にいて、双方がアプリをインストール済み」であることが前提になっていた。
相手がアプリ未インストールの場合や離れて暮らしている場合にグループを作れず、初回のグループ作成でつまずく。
リンクを共有してグループに参加してもらう導線を、どの技術で実現するか。

## 決定事項

* 招待リンクは **Universal Link** で実現し、AASA（`apple-app-site-association`）とフォールバックページを **Firebase Hosting** で配信する
* リンクの形式は `https://<host>/invite/<token>` とし、トークンはパスに載せる
* 招待トークンの発行と、それを使ったグループ参加は **Cloud Functions（v2 callable）** で行う
  （`issuecohabitantinvitation` / `joincohabitant`）
* トークンは有効期限24時間・使用回数無制限とし、`Invitation/{token}` に保存する
* **deferred deep link は実装しない。** アプリ未インストールのユーザーには、フォールバックページで
  「①App Storeでインストール ②リンクをもう一度タップ」という手順を案内する
* 既存の近接P2P登録は残し、招待リンクを並列の選択肢として追加する

## 考慮した選択肢

* **Firebase Dynamic Links**: 2025年8月にサービス終了済みのため採用不可。
  インストール後に自動で招待画面へ遷移する deferred deep link は、これに代わる無償の標準手段が存在しない
* **カスタムURLスキーム**: 未インストール時にリンクが何も起きない（App Storeへ誘導できない）ため、
  Issueの目的である「未インストールの相手ともスムーズに」を満たせない
* **参加処理をクライアント（Firestore直接更新）で行う**: Functionsの追加・デプロイが不要で実装量は少ないが、
  トークンの有効期限・重複参加の検証をクライアントに委ねることになる。
  現行の `firestore.rules` が「認証済みなら全許可」であるため、検証を迂回した参加を防げない
* **インストール後に招待コードを手入力させる画面を用意する**: リンク再タップより確実だが、
  入力画面・バリデーション・コピー導線が増える。まずは追加実装ゼロで済む「リンク再タップ」で運用し、
  成立率が低ければ後から足せる

## 決定結果

### 決定にあたり考慮したメリット

* 離れて暮らす同居人・アプリ未インストールの相手ともグループを作れるようになり、初回登録の離脱を減らせる
* トークン検証と `members` 更新をサーバ側のトランザクションに寄せることで、
  期限切れトークンでの参加・別グループへの誤参加・メンバー配列の競合を確実に防げる
* Hostingは静的ファイルのみで、AASAの配信要件（ドメイン直下・`Content-Type: application/json`）を素直に満たせる
* 既存P2Pを残すため、対面での登録体験は変わらない

### 決定にあたり考慮したデメリット

* インストール直後に自動で招待画面へ遷移できず、ユーザーにリンクの再タップを求めることになる（案内文で補う）
* Firebase Hosting・Associated Domains capability・AASA という運用対象が増える
* 本番ドメインが未確定のため、Releaseビルドでは招待リンクを生成できない状態が一時的に残る
  （`CohabitantInvitationLink.isAvailable` が false の間は共有導線自体を出さない）

## 参考

* 実装方針: [doc/strategy/cohabitant-invitation-link.md](../strategy/cohabitant-invitation-link.md)
* [Supporting associated domains (Apple Developer)](https://developer.apple.com/documentation/xcode/supporting-associated-domains)
