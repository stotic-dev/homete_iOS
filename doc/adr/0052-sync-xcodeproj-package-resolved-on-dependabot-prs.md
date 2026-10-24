## タイトル: dependabotの依存更新がアプリに届かない問題を、xcodeproj側のPackage.resolvedを自動でそろえて解決する

* **ステータス: 承認済**
* 意思決定者: stotic-dev
* 日付: 2026-10-24
* 関連: PR #479（RevenueCat 5.96.0）、[ADR-0046](0046-split-infra-package-from-local-package.md)

## 文脈、背景や問題点の説明

xcodeprojでビルドすると、SwiftPMが使うのはルート（`homete.xcodeproj` / `hometeVRT.xcodeproj`）の`Package.resolved`だけで、依存として読み込んだInfraPackage・LocalPackageの`Package.resolved`は無視される。xcodeprojは外部ライブラリを直接参照していないが、ローカルパッケージ経由で入るライブラリの版もルート側に記録される。

dependabotはInfraPackage・LocalPackage側しか更新できないので、CIの`make build-infra-package`だけが新しい版でビルドされ、リリースされるアプリは古い版のまま固定されていた（2026-10-24時点でRevenueCatはInfraPackageが5.95.0、アプリが5.81.2）。

## 決定事項

* `scripts/sync-package-resolved.py`で、xcodeproj側にあるパッケージの版・revisionをパッケージ側の値で上書きする
  * `homete.xcodeproj` ← `InfraPackage`（LocalPackageに依存しているので、アプリが使うパッケージを全部含む）
  * `hometeVRT.xcodeproj` ← `LocalPackage`
  * パッケージの追加・削除は扱わない。依存を増やす・減らすときはXcodeで解決し直す
* `sync-package-resolved.yml`で、dependabotのPRには`pull_request_target`でそろえるコミットを積む。スクリプトはmainのものを使い、PRのチェックアウトはデータとして読むだけにする
* dependabot以外のPRでは、`pull_request`で`--check`を流し、ずれていたら失敗させる

## 考慮した選択肢

* **A. dependabotのPRにワークフローでコミットを積む（採用）**
* B. macOSのランナーで`xcodebuild -resolvePackageDependencies`を流してルート側を解決し直す
* C. ずれを検知して失敗させるだけにし、手で直す
* D. dependabotの監視対象にxcodeprojを足す

## 決定結果

Bは、既存の`Package.resolved`があると、SwiftPMは満たせる限り記録済みの版を据え置く。版は上がらないので解決にならない。macOSのランナーとFirebase一式の取得も重い。
Dは、dependabotのswiftエコシステムがxcodeprojに対応していない。
CだけだとdependabotのPRが毎回失敗し、手で直す手間が残る。

Aは、JSONを書き換えるだけなのでubuntuで数秒で終わる。Pythonの`json`で`indent=2`・`" : "`区切りで書くと、Xcodeが書く書式とバイト単位で一致することを確かめた。

### 決定にあたり考慮したメリット

* dependabotのPRをマージすれば、リリースされるアプリの版も上がる
* 手で依存を上げたPRでも、xcodeproj側の更新漏れをCIで検知できる

### 決定にあたり考慮したデメリット

* dependabotのPRに他人のコミットが入るので、dependabotは自動でrebaseしなくなる。コンフリクトしたら`@dependabot recreate`で作り直す（作り直したPRにもワークフローがもう一度コミットを積む）
* GITHUB_TOKENのpushでは他のワークフローが起動しない。xcodeproj側の`Package.resolved`を対象にするGitHub ActionsのCIは無いので影響はない。Xcode Cloudは通常どおり起動する
* `pull_request_target`は書き込み権限で動くので、同じリポジトリのdependabotのPRに限り、PRのコードは実行しない

## 参考

* [ADR-0030](0030-vrt-snapshot-commit-ci-skip.md)（`pull_request_target`を使う理由の前例）
