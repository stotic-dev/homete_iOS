## タイトル: アプリプレビューはASC APIを直接叩いてsync-metadataで同期する

* **ステータス: 提案済**
* 意思決定者: stotic-dev
* 日付: 2026-10-18
* 関連: [ADR-0016](0016-release-pipeline-automation.md)、[ADR-0032](0032-sync-metadata-on-release-branch-push.md)、[ADR-0045](0045-sync-creative-assets-via-asc-api.md)

## 文脈、背景や問題点の説明

App Storeのアプリプレビュー（動画）を載せることにした。テキストのメタデータとスクリーンショットは`sync-metadata.yml`が`fastlane deliver`でASCへ同期しているが、`deliver`はアプリプレビューのアップロードに対応していない。
クリエイティブアセット（ADR-0045）と同じく、ASCの画面から手で載せると、差し替えやロケールの追加のたびに漏れやすい。どうやって同期に乗せるか。

## 決定事項

* 動画は`fastlane/app_previews/<ロケール>/`に置き、ファイル名を`<previewType>-<順番>-<名前>.mp4`（`.mov` / `.m4v`も可）にする
  * 先頭の`previewType`（例: `IPHONE_67`）で載せる枠を決める。解像度からは決めない。886×1920は6.9インチから6.1インチまでの枠で同じなので、解像度ではどの枠か決まらないため
  * iPhoneは`IPHONE_67`（6.9インチ）の枠にだけ載せる。小さい画面の枠が空なら、ASCが大きい枠のものを縮小して使うため
  * 1つの枠に3本まで。ファイル名の順番に並べる
* 同期は`scripts/appstoreconnect.sh app-previews sync <version>`で行う。`sync-metadata.yml`のクリエイティブアセットの後に流し、pathsフィルタに`fastlane/app_previews/**`を足す
* 同期の流れ: 枠（`appPreviewSets`）が無ければ作る → 要らない動画を外す → 足りない動画をアップロード（`appPreviews`の予約 → 分割アップロード → `uploaded: true`でコミット）→ 処理完了を待つ → ファイル名の順番に並べ替える
  * 要らない動画を先に外す。1つの枠に3本までで、先に足すと上限を超えることがあるため（`Deliverfile`の`overwrite_screenshots(true)`と同じく、差し替えの間は一時的に枠から消える）
* 動画のMD5を、ASCの`sourceFileChecksum`と比べる。同じ動画が同じ順番で載っていれば何もしない
  * クリエイティブアセットのような`referenceName`は、アプリプレビューには無い。代わりに、コミットのときに送る`sourceFileChecksum`がそのまま返ってくるので、それを使う
  * 処理に失敗した動画（`FAILED`）は外して、アップロードし直す
* 処理の状態は`videoDeliveryState`で見る。`assetDeliveryState`は非推奨のため、`videoDeliveryState`が返らないときだけ使う
  * 処理は最大30分待つ。Appleの説明では処理に最大24時間かかるため、30分で終わらなければ警告だけ出して成功として終える。失敗（`FAILED`）ならエラーで止める
* ファイルが無いロケール・`previewType`の枠には触らない。リポジトリから消したファイルの動画も、その枠のファイルが全部無くなった場合は外さない
* 審査への提出はしない。載せた動画はバージョンと一緒に審査される

## 考慮した選択肢

* A. `scripts/appstoreconnect.sh`にサブコマンドを足す（採用）
* B. Fastfileのレーンに、fastlane内部のSpaceshipでAPIを叩く処理を書く
* C. ASCの画面から手で載せる

## 決定結果

### 決定にあたり考慮したメリット

* ADR-0045と同じ理由。JWT生成・API呼び出し・分割アップロードは`appstoreconnect.sh`の処理を使い回せる（分割アップロードとバージョンの引き当ては、クリエイティブアセットと共通の関数に切り出した）
* 同じ`sync-metadata.yml`で流れるので、`release/*`へのpushでメタデータ・スクリーンショット・クリエイティブアセット・アプリプレビューが揃って反映される

### 決定にあたり考慮したデメリット

* 実装は公式のOpenAPI仕様（4.5.1）に沿っているが、本物のASCでの確認は最初の実行まで済んでいない。モックのAPIサーバーで、初回のアップロード・変更なしでの再実行・追加・差し替え・並べ替え・処理の失敗と、失敗した後の再実行は確認した
* 差し替えのときは、古い動画を外してから新しい動画を上げるので、アップロードに失敗するとその枠が空のまま止まる。再実行すれば上げ直す
* 動画はリポジトリに入るため、差し替えるたびにgitの履歴が膨らむ（1本で数十MB）
* 載せられるのは編集できる状態のバージョンだけ。審査中や承認済みのバージョンには載せられない
* ポスターフレーム（`previewFrameTimeCode`）は指定しない。ASCの既定（5秒の時点）のまま。変えるときはASCの画面で変える
* カスタムプロダクトページ・プロダクトページの最適化（A/Bテスト）の枠には対応していない

## 参考

* [App preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications)
* [App Previews（ガイドライン）](https://developer.apple.com/app-store/app-previews/)
* [App Store Connect API OpenAPI specification](https://developer.apple.com/sample-code/app-store-connect/app-store-connect-openapi-specification.zip)
* `.github/workflows/sync-metadata.yml`
* `scripts/appstoreconnect.sh`の`sync_app_previews`
