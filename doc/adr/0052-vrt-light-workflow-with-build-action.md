## タイトル: VRTを1回だけ流すVRT_lightワークフローをBuildアクションで作り、VRTの診断収集を止める

* **ステータス**: 提案済
* 意思決定者: taichisato（プロダクトオーナー）, Claude（調査担当）
* 日付: 2026-10-23
* 技術的背景: [ADR-0005](0005-vrt-snapshot-recording-on-xcode-cloud.md)（Xcode Cloud上での参照スナップショットの記録）、[ADR-0030](0030-vrt-snapshot-commit-ci-skip.md)、[ADR-0047](0047-vrt-dedicated-xcode-project.md)

## 文脈、背景や問題点の説明

`VRT` ワークフロー（テストアクション）は1回に約12分かかる。PR #474のBuild #15のログで内訳を見ると、テストを流しているのは2回分で計約6分、残りはランナーの準備・clone・ビルド・結果のアップロードだった。

| 区間 | 時間 |
|---|---|
| ランナーの起動・clone | 約1分 |
| パッケージ解決・build-for-testing | 約1分15秒 |
| `ci_post_xcodebuild.sh` の記録用の再実行（シミュレータ起動45秒 + テスト300件） | 約2分55秒 |
| テスト用ランナーの準備 | 約1分20秒 |
| test-without-building（判定用。シミュレータ起動45秒 + テスト300件） | 約2分50秒 |
| テスト後の後処理（結果の回収・アップロード） | 約2分 |

ADR-0005のとおり、test-without-buildingのランナーにはgitのチェックアウトが無いので、記録・pushはbuild-for-testing側でテストを流し直して行っている。そのため同じテストを2回流し、判定用のテストのためだけに別ランナーの準備と結果のアップロードを待っている。

また、判定用のテストアクションは失敗時に診断情報を集める（`-collect-test-diagnostics` の既定値 on-failure）。クラッシュ時にはこの収集が600秒でタイムアウトしてCIを大きく遅らせたことがある。記録用の再実行には `-collect-test-diagnostics never` を付けたが、Xcode Cloudが起動するテストアクションにはオプションを渡せない。テストプランの `diagnosticCollectionPolicy` に `"never"` を入れたときは、テストプランが読めなくなって戻した。

## 決定事項

### VRT_lightワークフロー

* Xcode Cloudに **Buildアクションだけの `VRT_light` ワークフロー**を作る。スキームは新しく共有する `hometeVRTHost`（空のホストアプリだけをビルドする）
* Buildアクションのあとの `ci_post_xcodebuild.sh`（`CI_WORKFLOW == "VRT_light"` かつ `CI_XCODEBUILD_ACTION == "build"`）で `xcodebuild test` を記録モード（`TEST_RUNNER_SNAPSHOT_TESTING_RECORD=failed`）で1回だけ流し、変わった参照PNGをVRTと同じ手順でcommit・pushする。記録・commit・pushの処理は `record_and_push_snapshots` にまとめてVRTと共有する
* Buildアクションは `generic/platform=iOS` 向けにビルドするので、シミュレータ向けのテストの成果物は使い回せない。Buildアクションでは軽いホストアプリだけをビルドし、テストのビルドはpostの `xcodebuild test` に任せる
* 記録モードでは不一致があっても失敗しないので、xcodebuildが0以外で終わったとき（ビルドの失敗やクラッシュ）だけpostを失敗させ、ワークフローを赤にする。見た目の差分は、ほかの記録と同じくbot commitとDangerのbefore/after画像で確かめる
* 既存の `VRT` ワークフローは残す。切り替えるかどうかはVRT_lightを実際に流して決める

### VRTの診断収集を止める

* `hometeSnapshotTestsForCI.xctestplan` の `defaultOptions` に `"diagnosticCollectionPolicy" : "Never"` を入れる。値は先頭が大文字の `"Never"`。ローカルのbuild-for-testingで試したところ、`"never"` / `"onFailure"` / 数値 / 真偽値ではテストプランが読めず、`"Never"` だけが読めた。そのとき生成されたxctestrunの `DiagnosticCollectionPolicy` は 1（on-failure）から 0 に変わった

## 考慮した選択肢

* **VRTのテストアクションの中で判定用のテストをやめる**: テストアクションは必ずtest-without-buildingを流すので、Xcode Cloudの設定では外せない
* **判定用のテストで記録もする**: ランナーにgitのチェックアウトが無く、pushできない（ADR-0005）
* **Buildアクションでテスト対象までビルドする**: デバイス向けのビルドになり、テストでは使い回せないうえ、テストバンドルの署名も要る
* **GitHub Actionsで流す**: 記録環境をXcode Cloudに一本化する方針（ADR-0005）に反する

## 決定結果

### 決定にあたり考慮したメリット

* テストを流すのが1回になり、テスト用ランナーの準備と結果のアップロードも待たない。PR #474の内訳では、約6分（記録用の再実行を除いた判定用のテスト・ランナーの準備・後処理）が減る見込み
* 判定用のテストでクラッシュしても、診断の収集で最大600秒待たされない

### 決定にあたり考慮したデメリット

* Xcode Cloudの画面にテスト結果（失敗したテストやxcresult）が出ない。結果は `ci_post_xcodebuild.log` で見る
* 見た目の差分ではワークフローが赤にならない。気付けるのはbot commitとDangerのコメントだけになる
* PRのブランチの実HEADへcheckoutしてからビルドするので、mainとのマージプレビューではなくブランチ自体のコードで描画する（pushしないビルドではマージプレビューのまま）
* ホストアプリを `generic/platform=iOS` 向けにビルドするので、Xcode Cloudの自動署名で `taichi.satou.hometekure.vrthost` の署名が要る
* Xcode Cloud側のワークフローはApp Store Connectで手で作る。環境変数（`GH_APP_ID`、`GH_APP_PRIVATE_KEY_BASE64`、`GITHUB_REPOSITORY`）はワークフロー単位なので、VRT_lightにも登録が要る

## 参考

* 内訳を取ったビルド: PR #474のVRT Build #15（`scripts/xcode-cloud.sh status 474`）
* `diagnosticCollectionPolicy` を戻したコミット: b5fcd18c
