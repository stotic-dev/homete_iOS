## タイトル: WebView経由の招待リンクは着地ページとカスタムURLスキームで受け、未インストール時はクリップボードで招待を引き継ぐ

* **ステータス: 承認済**
* 意思決定者: 佐藤汰一
* 日付: 2026-09-20
* 技術的背景: [ADR-0013](0013-cohabitant-invitation-universal-link.md)、[Issue #274](https://github.com/stotic-dev/homete_iOS/issues/274)、[doc/strategy/invitation-landing-page.md](../strategy/invitation-landing-page.md)

## 文脈、背景や問題点の説明

招待リンクは Universal Links（ADR-0013）で実装したが、LINE をはじめとする SNS はリンクを内蔵ブラウザ（WebView）で開く。WebView は AASA の照合を行わないため Universal Links が発火せず、アプリがインストール済みでもアプリに遷移できない。メモアプリから同じリンクを開くとアプリが起動することは確認済みで、AASA や entitlements の設定に問題は無い。

また、アプリ未インストールのユーザーは App Store でインストールした後に招待トークンを引き継ぐ手段が無く、「LINE に戻ってリンクをもう一度タップする」案内に頼っていた。Firebase Dynamic Links は 2025-08-25 に終了しており使えない。

どの経路で共有されても招待された人がグループに参加できるようにするには、何を採用すべきか。

## 決定事項

* 着地ページ（Firebase Hosting の `/invite/<token>`）を「WebView で開かれた場合の正規の画面」として作り替え、**ユーザーのタップ起点**で開く「アプリで開く」ボタン（カスタム URL スキーム `homeau://invite/<token>`、dev は `homeau-dev`）と、App Store への「初めての方はこちら」を併置する。ページロード時の自動リダイレクトは行わない
* 共有する URL には `?openExternalBrowser=1` を常に付与する。LINE はこのクエリで外部ブラウザ（Safari）を開くため Universal Links に到達でき、他のアプリは無視するので SNS ごとの個別対処にはならない
* 未インストール時の招待の引き継ぎは**クリップボード**で行う。着地ページの「初めての方はこちら」タップ時に招待 URL をコピーし、アプリ側はグループ未所属のダッシュボードでフォアグラウンド復帰のたびに `UIPasteboard.detectPatterns(for: [.probableWebURL])` で **URL の有無だけ**を確認する。該当時は「招待リンクを確認する」導線を出し、ユーザーがタップしたときだけ内容を読み取る
* 参加前に招待情報（招待者名・有効性）をサーバーから取得し、「〇〇さんのグループに参加しますか？」の確認を挟む。クリップボード経由は誤ったリンクを拾う可能性があるため、参加先を目視で確認できるようにする
* Smart App Banner と OGP を着地ページに設定する（Safari で開かれた場合と、SNS 上での見え方の補助）

## 考慮した選択肢

* **選択肢1: SNS ごとにクエリパラメータや UA 判定で個別対処する**
  * 各 SNS の仕様変更に追従し続ける必要があり維持できない。`openExternalBrowser=1` は付けるだけで副作用が無いため例外的に採用するが、これを基本方針にはしない
* **選択肢2: 着地ページのロード時にカスタムスキームへ自動リダイレクトし、失敗したら App Store へ送る**
  * 未インストール時に Safari が「アドレスが無効です」のダイアログを出す。Android Chrome はブロックする。タイマーによる成否判定は端末やブラウザで誤爆する
* **選択肢3: 外部 SDK（AppsFlyer OneLink / Adjust / Branch）のディファードディープリンク**
  * 導入・運用コストと SDK 依存が増える。主目的は広告計測であり、招待の引き継ぎだけのためには過剰。取りこぼしが問題化してから再検討する
* **選択肢4: フィンガープリント（IP・UA）による確率的マッチング**
  * iCloud Private Relay / CGNAT で精度が安定せず、同一 Wi-Fi 下の別世帯と誤マッチして**誤ったグループに参加させる**リスクがある。家事データを共有する性質上、確率的な紐づけは採用しない
* **選択肢5: App Clip**
  * 未インストールでも即時に参加できるが、App Clip ターゲットの追加と別途の審査・配信設定が必要。将来の検討事項として残す
* **選択肢6: 着地ページ＋カスタム URL スキーム＋クリップボード補助（採用）**
  * 全て自前で完結し、外部依存が無い。クリップボードの読み取りはユーザー操作起点に限定するため iOS 16 以降のペースト通知も「ユーザーが押した結果」として自然に受け入れられる

## 決定結果

### 決定にあたり考慮したメリット

* WebView・Safari・メモアプリのどこから開かれても、インストール済みならワンタップでアプリの参加確認画面に到達できる
* 未インストールでも、着地ページ → App Store → 初回起動の流れで招待を引き継げる。クリップボードを消していても「リンクをもう一度タップ」の従来経路は残る
* 参加先の確認画面に招待者名が出るため、誤ったグループへの参加が起きない

### 決定にあたり考慮したデメリット

* 「アプリで開く」を未インストール状態でタップすると Safari のエラーダイアログが出る。ユーザー操作起点であることと「初めての方はこちら」の併置で許容する
* クリップボードの内容を読み取るとシステムのペースト通知が出る。`detectPatterns` は URL らしきものがあれば何でも反応するため、無関係な URL をコピーしていても案内が出る（読み取り後に「見つかりませんでした」と表示し、同じ内容では再案内しない）
* カスタム URL スキームは他アプリと衝突しうる（Universal Links と違い一意性の保証が無い）。主経路は引き続き Universal Links とし、スキームは WebView 用の補助に留める
* Smart App Banner の App Store ID は本番アプリ固定のため、stg の着地ページからも本番アプリが案内される

## 参考

* `firebase/hosting/public/invite/index.html`
* `LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantInvitationLink.swift`
* `LocalPackage/Sources/HometeDomain/Cohabitant/PasteboardInvitationStore.swift`
* `LocalPackage/Sources/HometeInfrastructure/Pasteboard/ImplPasteboardClient.swift`
* [UIPasteboard.detectPatterns(for:)](https://developer.apple.com/documentation/uikit/uipasteboard/3618965-detectpatterns)
