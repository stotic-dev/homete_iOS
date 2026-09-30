## タイトル: VRT参照スナップショットの自動commitを `[ci skip]` で止め、Dangerだけ `pull_request_target` で動かす

* **ステータス**: 承認済
* 意思決定者: taichisato（プロダクトオーナー）, Claude（調査・実装担当）
* 日付: 2026-09-30
* 技術的背景: [ADR-0005](0005-vrt-snapshot-recording-on-xcode-cloud.md)「実装構成 5. ループ対策は Custom Conditions のみで行う」の見直し

## 文脈、背景や問題点の説明

[ADR-0005](0005-vrt-snapshot-recording-on-xcode-cloud.md) で、VRTの参照スナップショットはXcode Cloudの`VRT`ワークフローが記録し、`ci_post_xcodebuild.sh`がPRブランチへ自動commit・pushする構成にした。

このbot pushが新たなVRTビルドを誘発するループを止める手段として、ADR-0005 は**Xcode Cloud側のCustom Conditions（ファイル/フォルダ条件）のみ**を採用し、コミットメッセージへの`[ci skip]`は「GitHub Actions側にも解釈され`ci_danger.yml`（Danger）まで止めてしまう」として不採用にしていた。

しかし運用してみると、**bot pushに対してVRTビルドが再度起動してしまっている**。Xcode CloudのFiles and Folders条件は「これらのファイルが変更されたときだけビルドする」という*包含*指定しか書けず、「スナップショットディレクトリ**のみ**の変更なら起動しない」という*除外*条件は表現できない。VRTは1回15〜25分のコンピュート時間を使うため（Apple Developer Programに含まれるのは25 compute h/月）、この空振りビルドは無視できないコストになる。

**`[ci skip]`でVRTの再起動だけを止めつつ、Dangerのbefore/after画像差分コメントはbot commitに対しても走らせられないか？**

## 決定事項

* **bot commitのメッセージに`[ci skip]`を付ける。** `chore: VRT参照スナップショットを自動更新 [ci skip]`。Xcode Cloudが公式にサポートするスキップ指示で、これによりVRTビルドの再起動が止まる。
* **`ci_danger.yml`のトリガーを`pull_request`から`pull_request_target`に変更する。** GitHubのスキップ指示は`push`と`pull_request`イベントにしか効かないため、`pull_request_target`にすればbot commitでもDangerが起動する。GitHub公式ドキュメントにも「`[skip ci]`をコミットメッセージに追加しても`on: pull_request_target`のワークフローは止まらない」と明記されている。
* **`pull_request_target`の副作用に2点手当てする。**
  1. `actions/checkout`に`ref: ${{ github.event.pull_request.head.sha }}`を指定する。`pull_request_target`のデフォルトはベースブランチのチェックアウトになるため、明示しないとDangerfileのSwiftLint（`.modifiedAndCreatedFiles`）が変更後のコードを見られない。
  2. ジョブに`if: github.event_name != 'pull_request_target' || github.event.pull_request.head.repo.full_name == github.repository`のガードを置き、**fork PRではジョブを実行しない**。`pull_request_target`はベースリポジトリのSecret（`DANGER_GITHUB_API_TOKEN`）をジョブに渡すため、ガードなしでhead SHAをチェックアウトして`swift build`すると、fork PRのコードにトークンを渡すことになる。
* ADR-0005 の「実装構成 5」は本ADRで置き換える。Xcode Cloud側のCustom Conditionsは`[ci skip]`があれば不要になるが、スナップショット以外の起動条件の絞り込み（コンピュート時間の節約）としては引き続き有効なので、設定の扱いはXcode Cloud側の運用判断とする。

### 他ワークフローへの影響

`[ci skip]`は当該コミットに対する`push` / `pull_request`起因の全ワークフローを止めるが、bot commitが触るのは参照スナップショットのディレクトリだけなので実害はない。

| ワークフロー | bot commitでの扱い |
|---|---|
| `ci_danger.yml` | `pull_request_target`のため**起動する**（本ADRの目的） |
| `ci_local_package.yml` | `paths: LocalPackage/**`で絞っており、そもそも起動対象外 |
| `functions-e2e-test.yml` | `paths: firebase/**`で絞っており、起動対象外 |
| Xcode Cloud `VRT` | `[ci skip]`により**起動しない**（本ADRの目的） |

## 考慮した選択肢

* **`pull_request_target`に切り替える（採用）**: 変更は`ci_danger.yml`のYAML数行のみ。`[skip ci]`が効かないことがGitHub公式ドキュメントで明言されており、挙動の根拠が強い。Danger JS側も`pull_request_target`での実行を公式にサポートしている（イベントペイロードの形が`pull_request`と同じため、PR番号の解決ロジックはそのまま動く）。デメリットはfork PRへのSecret露出リスクで、これは同一リポジトリ判定のガードで閉じる。
* **`repository_dispatch`をXcode Cloudから叩く**: `ci_post_xcodebuild.sh`のpush後に`POST /repos/{owner}/{repo}/dispatches`を呼び、`ci_danger.yml`に`repository_dispatch`トリガーを足す。`repository_dispatch`はスキップ指示の対象外で、`pull_request`トリガーを維持できる（=ワークフロー定義の変更をPR内で検証できる）点も利点。ただし、(a) PR文脈が無いイベントなのでDangerをFakeCI（`DANGER_FAKE_CI` / `DANGER_TEST_REPO` / `DANGER_TEST_PR`）で動かす配線が必要、(b) 検証がXcode Cloudのビルド待ちループになる（ADR-0005でも「デバッグの反復が遅い」として挙げた摩擦）。得られる結果が同じで手数と不確実性が多いため不採用。
* **Xcode Cloudだけが解釈する別のスキップ文字列を使う**: Apple側が公式に挙げるスキップ指示は`[ci skip]`のみで、これはGitHub Actionsのスキップ文字列（`[skip ci]` / `[ci skip]` / `[no ci]` / `[skip actions]` / `[actions skip]`）と重複する。片方だけに効く文字列は存在しないため不成立。
* **現状維持（Custom Conditionsのみ）**: 除外条件が表現できず、空振りのVRTビルドが起動し続ける。コンピュート時間の枯渇リスクが残るため不採用。

## 決定結果

### 決定にあたり考慮したメリット

* bot pushによる空振りのVRTビルドが止まり、Xcode Cloudのコンピュート時間（25 compute h/月）を消費しなくなる。
* Dangerのbefore/after画像差分コメントは、参照スナップショットを含む最新のhead commitに対して走る。ADR-0005 が前提にしていた「bot pushでDangerが自動で走る」性質を維持できる。
* 変更が`ci_danger.yml`とコミットメッセージ1行に収まり、Xcode Cloud側の設定変更（git管理外でレビューできない部分）を増やさない。
* fork PRは従来もSecretが渡らずDangerが動かなかったため、ガードによってジョブごとスキップされる方が挙動として明確になる。

### 決定にあたり考慮したデメリット

* **`ci_danger.yml`自体の変更をPR内で検証できない。** `pull_request_target`はベースブランチ（main）のワークフロー定義で実行されるため、この変更の効果はmainへマージした後のPRでしか確認できない。
* **`pull_request_target`はSecretをジョブに渡す。** 同一リポジトリ判定のガードが外れた／壊れた場合、fork PRのコードに`DANGER_GITHUB_API_TOKEN`（PAT）が渡る経路が開く。Dangerfileは`swift build`でPR内のコードを実行するため、ガードはこのワークフローの安全性の前提になる。今後`ci_danger.yml`を触るときはガードを外さないこと。
* **fork PRではDangerが完全に走らなくなる。** 従来はジョブが起動してトークン不在で失敗していた（実質機能していない）状態だったが、外部コントリビュータのPRにDangerのコメントが付かないことは明示的な仕様になる。
* `[ci skip]`は当該コミットの`push` / `pull_request`起因ワークフロー全体を止めるため、将来スナップショット以外のファイルをbot commitに含めるよう変えた場合、その変更に対するCIも止まる。

## 参考

* [ADR-0005: VRT参照スナップショットの記録をローカルから Xcode Cloud へ移す](0005-vrt-snapshot-recording-on-xcode-cloud.md) — 本ADRが「実装構成 5. ループ対策」を置き換える
* [Skipping workflow runs - GitHub Docs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs) — 「Skip instructions only apply to the `push` and `pull_request` events.（`[skip ci]`を付けても`on: pull_request_target`のワークフローは止まらない）」
* [Events that trigger workflows - `pull_request_target`](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request_target) — ベースブランチのワークフロー定義で実行され、Secretを持つ点
* [Configuring start conditions - Apple Developer](https://developer.apple.com/documentation/xcode/configuring-start-conditions/) — Xcode Cloudの`[ci skip]`とCustom Conditions
* [Danger JS - GitHub Actions](https://danger.systems/js/guides/getting_started.html) — `pull_request_target`での実行サポート
* `ci_scripts/ci_post_xcodebuild.sh` — bot commitのメッセージに`[ci skip]`を付ける実装箇所
* `.github/workflows/ci_danger.yml` — `pull_request_target`への切り替えとforkガード
