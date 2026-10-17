## タイトル: クリエイティブアセットはASC APIを直接叩いてsync-metadataで同期する

* **ステータス: 承認済**
* 意思決定者: stotic-dev
* 日付: 2026-10-12
* 関連: [ADR-0016](0016-release-pipeline-automation.md)、[ADR-0032](0032-sync-metadata-on-release-branch-push.md)

## 文脈、背景や問題点の説明

2026年10月から、App Storeのプロダクトページヘッダーと検索結果に、スクリーンショットとは別の画像（クリエイティブアセット）を載せられるようになった（iOS 27以降で表示）。
テキストのメタデータとスクリーンショットは`sync-metadata.yml`が`fastlane deliver`でASCへ同期しているが、fastlane（2.239.0）はクリエイティブアセットに対応していない。
リリースのたびにASCの画面から手で載せると忘れやすく、ロケールごとの差し替えも漏れる。どうやって同期に乗せるか。

## 決定事項

* 画像は`fastlane/creative_assets/<ロケール>/`に置き、ファイル名で配置を決める
  * `product_page_header.png` → `PRODUCT_PAGE_HEADER_ASSET`
  * `search_results.png` → `APP_STORE_SEARCH_RESULTS_ASSET`
* 画像は`doc/design/store_assets/generate_creative_assets.py`で生成する。手で直さず、スクリプトを直して書き出し直す
* 同期は`scripts/appstoreconnect.sh creative-assets sync <version>`で行う。`sync-metadata.yml`の`deliver`の後に流し、pathsフィルタに`fastlane/creative_assets/**`を足す
* 同期の流れ: アセットライブラリへアップロード（`appAssetLibraryImages`）→ 処理完了を待つ → バージョンのロケールに配置（`appAssetLibraryPlacements`）
  * 処理完了は最大30分待つ。最初の実行（v2.0.0）でヘッダー画像の処理が5分を超え、`UPLOAD_COMPLETE`のまま失敗したため
  * 同じ`referenceName`の画像がアセットライブラリにあれば、アップロードせずにそれを使う。処理待ちで失敗した後に再実行したとき、同じ画像を上げ直して処理待ちをやり直さないようにするため（アップロード途中・失敗・アーカイブ済みのものは使わない）
* 配置グループ（`placementGroup`）は直書きせず、参照データ（`appAssetLibraryRefData`）から引く。アップロードした画像の仕様（`specId`）を受け付けるグループすべてに配置する。グループの識別子は端末の種類ごとの文字列で、Appleが端末を足すと増えるため（公式記事「Discovering asset specifications」でも直書きしないよう書かれている）
* 審査への提出はしない。配置した画像はバージョンと一緒に審査される（`deliver`の`submit_for_review(false)`と同じ扱い）
* 画像のsha256を`referenceName`に入れ、配置済みの画像と同じなら何もしない。違えば新しい画像の準備ができてから、グループごとに古い配置を外して付け替える
  * グループごとに置ける数に上限があり（ヘッダーは1枚）、新しい配置を先に作れないため、外してから作る
  * 作れなかったときは、外した配置を元の画像で作り直してから失敗として止める。そのロケールの画像が消えたままにならないようにするため

## 考慮した選択肢

* A. `scripts/appstoreconnect.sh`にサブコマンドを足す（採用）
* B. Fastfileのレーンに、fastlane内部のSpaceshipでAPIを叩く処理を書く
* C. fastlaneが対応するまで、ASCの画面から手で載せる

## 決定結果

### 決定にあたり考慮したメリット

* JWT生成・API呼び出し・アップロード操作の分割送信は、`appstoreconnect.sh`で実機確認済みの処理を使い回せる
* Bは、Spaceshipの公開されていない内部APIに依存するため、fastlaneの更新で壊れやすい
* Cは、リリースのたびに手作業が残る。メタデータは自動、画像は手動という分かれ方は忘れやすい
* 同じ`sync-metadata.yml`で流れるので、`release/*`へのpushでメタデータ・スクリーンショット・クリエイティブアセットが揃って反映される

### 決定にあたり考慮したデメリット

* 実装は公式のOpenAPI仕様（4.5.1）に沿っているが、本物のASCでの確認は最初の実行まで済んでいない。モックのAPIサーバーで、アップロード・付け替え・冪等性・失敗時の停止は確認した
* リポジトリからファイルを消しても、ASCの配置は外さない。外すときはASCの画面で外す
* 付け替えた古い画像はアセットライブラリに残る。カスタムプロダクトページなど別の場所で使っている可能性があるため、自動ではアーカイブしない
* 配置できるのは編集できる状態のバージョンだけ。審査中や承認済みのバージョンには付け替えられない
* 動画（`appAssetLibraryVideos`）、16:9の汎用アセット、カスタムプロダクトページへの配置には対応していない。必要になったら同じ仕組みで足す

## 参考

* [Creative assets specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications)
* [Manage your App Store assets](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets)
* [App Store Connect API OpenAPI specification](https://developer.apple.com/sample-code/app-store-connect/app-store-connect-openapi-specification.zip)
* `.github/workflows/sync-metadata.yml`
* `scripts/appstoreconnect.sh`の`sync_creative_assets`
