## タイトル: リリースPR作成〜App Store提出までのパイプラインを自動化し、タグ作成をGitHub Actions側に一本化する

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-09-05
* 技術的背景やその他関連チケット No: [#237](https://github.com/stotic-dev/homete_iOS/issues/237) / [#238](https://github.com/stotic-dev/homete_iOS/issues/238)

## 文脈、背景や問題点の説明

Issue #238で、`fastlane release`レーンの`Deliverfile`が`submit_for_review(true)` + `force(true)`のまま実行されると、確認プロンプト無しでApp Store審査に提出されてしまうことが判明した。しかも`release_notes.txt`が空、`review_information/notes.txt`がSign in with Apple必須という実態と不一致（「サインイン不要」と記載）、スクリーンショット未整備など、提出に必要なメタデータが揃っていなかった。

これに合わせて、リリースフロー全体を「手動実行のリリースPR作成 → mainマージ → タグ/GitHub Release publish → メタデータ同期 → Xcode Cloud起動 → App Store提出」という一連の自動パイプラインに再構成したい、という要望が出た。また、リリースPRへの変更の度に外部TestFlightへ配信し、レビュー前のリリース候補を関係者が試せるようにしたい。

## 決定事項

* **リリースPR作成**: 新規ワークフロー`create-release-pr.yml`（`workflow_dispatch`、バージョン番号を手動入力）が`release/vX.Y.Z`ブランチを作成し、`agvtool new-marketing-version`でMARKETING_VERSIONを更新してPRを作成する
* **タグ作成をXcode CloudからGitHub Actionsへ移す**: 従来`ci_scripts/ci_post_xcodebuild.sh`がarchive成功時に`agvtool what-marketing-version`からタグを作成・pushしていたが、これを`release-merged.yml`（PRマージ時）に移す。理由は「マージ→タグ/Release→メタデータ同期→Xcode Cloud起動」という順序を保証するため。archiveより前にタグが必要なため、archive内で打つ従来方式のままではこの順序を実現できない
* **リリースの公開はrelease-drafterに依存せず独立して行う**: 既存の`create-release-note.yaml`（release-drafter）はmainへのpush毎に「次バージョン」のドラフトを更新し続けるプレビュー用途として維持する。手動指定したバージョン番号とrelease-drafterの自動解決バージョンがズレるリスクがあるため、実際のタグ作成・publishは`release-merged.yml`側で`gh release create`により独立して行う
* **Xcode Cloud起動はApp Store Connect APIを直接叩く**: 新規`scripts/trigger-xcode-cloud-build.sh`を追加し、`scripts/appstoreconnect.sh`と同じES256 JWT生成・API呼び出しパターンを踏襲する。`ciWorkflows` → `scmRepositories` → `gitReferences` → `ciBuildRuns`の順でIDを解決してビルドを開始する
* **リリース候補の外部TestFlight配信は新規Xcode Cloudワークフローを追加する前提とする**: `ci_scripts/ci_post_clone.sh`に`"Upload Release Candidate TestFlight"`分岐を追加した。ただしXcode Cloudワークフロー自体の定義（トリガー条件・ビルド構成・配信先グループ）はApp Store Connect/Xcode側のUI設定であり、リポジトリのコードとしては管理できないため、実際のワークフロー作成は手動で行う
* **メタデータ同期はテキストのみ**: `fastlane sync_metadata`レーン（`deliver(skip_binary_upload: true, skip_app_version_update: true)`）で`fastlane/metadata`配下のテキストメタデータを同期する。スクリーンショットは`fastlane/screenshots/`の実体が無く、このセッションでは実機/シミュレータのキャプチャを生成できないため、`skip_screenshots(true)`を維持し対象外とした。アセット追加後に`skip_screenshots`を外せばそのままフル同期に切り替わる
* **初回審査提出は手動確認に変更**: `Deliverfile`の`submit_for_review`を`true`から`false`に変更した。CIから無人実行されるようになった以上、確認無しの自動提出はリスクが大きい
* **メタデータの実態不一致を修正**: `release_notes.txt`（1.0.0初回リリース向け）と`review_information/notes.txt`（Sign in with Apple必須・同居人グループ作成・招待リンクの試し方、[ADR-0013](0013-cohabitant-invitation-universal-link.md)の内容に基づく）を記入した

## 考慮した選択肢

* **タグ作成を従来通りXcode Cloud側（archive成功時）に残す**: 既存実装をそのまま使えるが、要望の実行順序（マージ→タグ→メタデータ同期→Xcode Cloud起動）を満たせない。メタデータ同期がXcode Cloud側のarchive完了をトリガーにする必要が生じ、依存関係が逆転してしまうため不採用
* **既存の`Upload Stg TestFlight`ワークフローをRelease構成に変更して転用する**: 新規ワークフロー追加が不要になるが、Stg配信自体の運用に影響する可能性があるため不採用。新規ワークフロー追加を選んだ
* **`release`レーンの`gym`/`upload_to_app_store`をGitHub Actions内で直接実行する**: Xcode Cloud側の署名管理・ビルド番号自動反映の仕組みを使わずに済むが、GitHub Actions runner側で証明書・プロビジョニングプロファイルの管理が新たに必要になり、Xcode Cloudの自動管理から外れる。既存のXcode Cloud基盤をAPI経由でキックする方式を採用した

## 決定結果

### 決定にあたり考慮したメリット

* マージ→タグ/Release→メタデータ同期→Xcode Cloud起動、という要望通りの順序を1つのワークフロー（`release-merged.yml`）内の直列ステップとして保証できる
* `scripts/appstoreconnect.sh`の実績あるJWT生成パターンを再利用でき、新規に認証まわりを実装するリスクが小さい
* `submit_for_review(false)`への変更により、メタデータ不備のまま無人提出される事故を防げる

### 決定にあたり考慮したデメリット

* `scripts/trigger-xcode-cloud-build.sh`の`ciBuildRuns`作成部分はApple公式ドキュメントの仕様に基づく実装だが、実機（実際のApp Store Connect環境）での動作確認はできていない。GitHub Secrets登録・Xcode Cloud新規ワークフロー作成後、初回実行時に動作確認が必要
* リリース候補の外部TestFlight配信ワークフロー自体（トリガー条件・配信先グループ）はコードで管理できず、App Store Connect/Xcode側の設定変更がドキュメント外で行われるとリポジトリの記述と食い違うリスクがある
* スクリーンショットはこのタイミングでは同期対象外のまま。App Store提出前に別途素材を用意し`skip_screenshots`を外す作業が残る
* 年齢制限（広告あり）の設定はApp Store Connect側の手動対応が必要で、このリポジトリの変更だけでは完結しない

## 参考

* Issue #237, #238
* `.github/workflows/create-release-pr.yml`
* `.github/workflows/release-merged.yml`
* `.github/workflows/sync-metadata.yml`
* `scripts/trigger-xcode-cloud-build.sh`
* `scripts/appstoreconnect.sh`
* [ADR-0008](0008-deploy-functions-workflow.md)（workflow_run活用の前例）
* [ADR-0013](0013-cohabitant-invitation-universal-link.md)（招待リンクの仕様、review_information/notes.txtに反映）
