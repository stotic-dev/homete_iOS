## タイトル: 変更に関係するモジュールだけをビルド・テスト・VRTする

* **承認済**
* 意思決定者: stotic-dev
* 日付: 2026-10-18
* 関連: [ADR-0046](0046-split-infra-package-from-local-package.md)、[ADR-0047](0047-vrt-dedicated-xcode-project.md)、Issue #444

## 文脈、背景や問題点の説明

ローカルの検証（Claude Codeの`swift-code-verification`スキル）とCI（`ci_local_package.yml`）は、どのファイルを変えても
LocalPackage全体のビルドと全テストを流していた。InfraPackage（ADR-0046）とVRT専用プロジェクト（ADR-0047）に分けて
モジュールの境界がはっきりしたので、変更がどのモジュールまで届くかは`Package.swift`の依存関係から決められる。

VRTはローカルでは流さない運用だった。テストホストに`Secret_dev.xcconfig`が必要だったり、全プレビューの完走に時間がかかったり
したためだが、VRT専用プロジェクトとテストホストの分離でどちらも解消している。

## 決定事項

* `scripts/affected-modules.py`で、変更されたファイルから影響範囲を割り出す
  * 起点は`origin/main`（CIではPRのベースブランチ）との分岐点。そこからのコミットと、未コミットの変更・追跡外のファイルを見る
  * ファイルの属するターゲットを、LocalPackage・InfraPackageの`swift package dump-package`のターゲットのパスから決める
  * 変更されたターゲットと、それに推移的に依存するターゲットを影響範囲にする
  * `LocalPackage/Package.swift`・`Package.resolved`・`ProjectTools/`・`.swiftlint.yml`（SwiftLintはビルドプラグイン）が変わったら、LocalPackageの全ターゲットを対象にする
* ローカルは`make affected`で範囲を確かめ、`make build-affected`（iOS向けビルドと、必要ならInfraPackageのビルド）と`make test-affected`だけを流す
* CIは、PRでは`make test-affected COVERAGE=1`で関係するテストだけを流し、InfraPackageのビルドも影響範囲が届くときだけにする。mainへのpushと手動実行では全部流す
* ローカルVRTは`make snapshot-affected`で流す
  * 対象は**直接変えた**HometeUI・Featureのプレビューだけ。依存するFeatureへは広げない。全プレビューはCIのVRTが見る
  * CIのVRT（`VRT_light`）も、PRでは推移的な影響範囲のプレビューだけに絞った（[ADR-0063](0063-split-ui-modules-from-domain-for-affected-vrt.md)）
  * 必ずiOS 27.0のiPhone 16で流す。参照スナップショットを記録しているXcode Cloudと、マイナーバージョンまでそろえないと描画に差分が出る
  * 参照スナップショットは書き換えない。参照の無い新しいプレビューで書き出されたPNGは消し、記録はCIに任せる
* 生成テストのテンプレートに`SNAPSHOT_REFERENCE_DIR`を足し、ローカルでは参照PNGの場所を渡す。Prefire 6では生成コードがDerivedDataに置かれ、
  `#filePath`から辿ると参照PNGに届かず全件「No reference was found」で失敗していた

## 考慮した選択肢

* **全体を流し続ける**: 判定を誤る心配は無いが、関係ないモジュールのビルド・テストを毎回待つことになる
* **変更行に`public`が含まれるかで、他パッケージへの影響を判定する**: InfraPackageのビルドをもっと減らせるが、
  `public`なプロトコルへの要件追加や`public`なenumへのケース追加は、行に`public`が出ないのに依存先を壊す。ADR-0046で
  防ぎたかったのはまさにこの種の壊れ方なので採らない
* **テストのビルドもテストターゲット単位に絞る**: SwiftPMはテストターゲットを1つのテストバンドルにまとめるため、
  `swift test`ではビルドを絞れない（`--filter`は実行だけを絞る）。xcodebuildでターゲットごとのスキームを作れば絞れるが、
  ユニットテストは`swift test`で回す方針（xcodebuildを使わない）なので採らない
* **ローカルVRTを影響範囲（推移的な依存）全体で流す**: HometeUIやHometeDomainを変えると全プレビューが対象になり、
  CIのVRTと同じ重さになる。ローカルは直接変えたモジュールの崩れをPR前に見る用途に絞る

## 決定結果

### 決定にあたり考慮したメリット

* Featureだけ・テストだけの変更では、関係ないテストの実行とiOS向けビルドが無くなる
* テストやHometeSnapshotTestSupportだけの変更では、CIのInfraPackageのビルドが走らない
* Viewの崩れを、CIのVRTを待たずにローカルで確かめられる

### 決定にあたり考慮したデメリット

* テストのビルドは全テストターゲット分のまま。ローカルは差分ビルドなので効きにくいが、キャッシュの無いCIでは実行時間しか減らない
* 判定スクリプトの対応表（全ターゲットを対象にするファイル、VRTのモジュール一覧など）を、構成を変えたときに保守する必要がある。
  VRTのモジュール一覧は`.prefire.yml`の`testable_imports`と同じにしておく
* PRのカバレッジ（Danger）は、流したテストの分だけになる
* ローカルVRTには、iOS 27.0のランタイムとiPhone 16のシミュレータが要る

## 参考

* `scripts/affected-modules.py`、`scripts/run-affected-snapshots.sh`
* `.claude/skills/swift-code-verification/SKILL.md`
