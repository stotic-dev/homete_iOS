## タイトル: Remote Configはfetch・activateを即時に行い、値をいつ画面へ反映するかはキーごとに決める

* **ステータス**: 承認済
* 意思決定者: taichisato（プロダクトオーナー）, Claude（調査・実装担当）
* 日付: 2026-10-01
* 技術的背景: [#331](https://github.com/stotic-dev/homete_iOS/issues/331)（広告表示のON/OFF）、[#330](https://github.com/stotic-dev/homete_iOS/issues/330)（強制アップデート）

## 文脈、背景や問題点の説明

広告表示のON/OFF（`ads_enabled`）をアプリ更新なしで切り替えるため、Firebase Remote Configを導入する。Remote Configは「サーバーから値を取ってくる（fetch）」と「取ってきた値をアプリから読めるようにする（activate）」の2段階になっており、activateは**全キーまとめて**切り替わる。

広告は表示中に出たり消えたりするとレイアウトが崩れるため、起動中は値を変えたくない。一方、同じ基盤に乗る予定の強制アップデート（`minimum_required_version`）は、起動中に公開しても早く効いてほしい。

**反映タイミングの要求が逆向きのキーを、1つの基盤でどう扱うか？**

## 決定事項

* **基盤（`RemoteConfigClient`）は、なるべく早く最新の値をactivateすることだけに責任を持つ。**
  * 起動時に`fetchAndActivate()`を実行する。起動処理とは並行に走らせ、完了を待たない
  * バックグラウンドからの復帰時にも`fetchAndActivate()`を実行する（`RootView`）
  * fetchのタイムアウトは3秒（SDK既定は60秒）。サーバーへのリクエスト単位の値で、fetch全体の上限ではない（初回はFirebase Installationsのトークン取得が先に挟まる）。失敗・タイムアウト時は前回activate済みの値、それも無ければアプリ内デフォルト値が使われる
  * `minimumFetchInterval`はReleaseで12時間、Debug/Stgで0秒
* **値をいつ画面へ反映するかは、そのキーを使う領域のStoreで決める。** Remote Configは値の取得元という技術の都合なので、Remote Config単位のStoreは作らない
  * `ads_enabled`（`AdvertisementStore`）: 起動時のfetchが終わった時点（成功・失敗を問わない）で1回だけ読み、`isAdsEnabled`として起動中は固定する。復帰時のactivateでは読み直さない
  * `minimum_required_version`（#330で追加予定）: 強制アップデートの領域のStoreで、activateのたびに再判定する想定
* `AdDisplayPolicy.isEnabled`（ハードコード定数）は廃止し、`EnvironmentValues.isAdsEnabled`経由でRemote Configの値を判定に使う。プレミアム加入者は広告非表示という判定式（`isEnabled && !isPremium`）は変えない
* App Checkは適用しない。App Checkが保護できるのはAuth（プレビュー）/ Firestore / Realtime Database / Storage / Callable Functions / SQL Connect / AI Logicで、Remote Configは対象外のため（配信する値は広告のON/OFFや最低バージョンで、漏れても実害がない）

## 考慮した選択肢

* **fetchとactivateを分け、起動時は前回fetchした値をactivateするだけにする（Firebaseの「次回起動時に反映」パターン）**: 起動中に値が変わらないことをSDKの仕組みで保証できる。ただしactivateが全キー共通のため、強制アップデートも「fetch → 次回起動」まで効かなくなる。Releaseのfetch最小間隔（12時間）と合わせると、公開から反映まで12時間以上＋再起動1回かかり得る
* **起動時に`fetchAndActivate()`の完了を待ってから画面を出す**: 起動中の値が最初から最新になるが、オフラインやタイムアウトで起動が遅れる。「起動を遅延させない」という#331の受け入れ条件を満たせない
* **fetch・activateは即時、反映タイミングはキーごとに使う側で決める（採用）**: 基盤はキーの性質を知らずに済み、#330はactivateのたびに判定するだけで乗れる

## 決定結果

### 決定にあたり考慮したメリット

* 広告は、起動時のfetchが間に合えばその起動から反映される（次回起動を待たない）
* 強制アップデートなど即時性が要るキーを、同じ基盤に後から足せる
* 起動処理はRemote Configの完了を待たないため、オフライン・初回起動でも起動が遅れない

### 決定にあたり考慮したデメリット

* 起動時のfetchがホーム画面の表示より遅れた場合（通常は3秒以内。初回起動や回線が弱いときはさらに遅れ得る）、`ads_enabled=true`のときに広告バナーが遅れて1回だけ現れる。逆方向（表示中に消える）は起きない
* Releaseでは`minimumFetchInterval`の12時間内はサーバーに問い合わせないため、コンソールで切り替えてから全ユーザーに届くまで最大12時間程度かかる。強制アップデートで即時性が足りない場合は、#330でリアルタイム更新（`addOnConfigUpdateListener`）の導入を検討する

## 参考

* [Firebase Remote Config: Loading strategies](https://firebase.google.com/docs/remote-config/loading)
* [Firebase App Check](https://firebase.google.com/docs/app-check)
* 運用手順: [doc/remote_config.md](../remote_config.md)
