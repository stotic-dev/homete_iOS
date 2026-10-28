## タイトル: UIのモジュールをStore・UseCase・Clientから切り離し、VRTを影響範囲だけに絞る

* **提案済**
* 意思決定者: stotic-dev
* 日付: 2026-10-25
* 関連: [ADR-0046](0046-split-infra-package-from-local-package.md)、[ADR-0047](0047-vrt-dedicated-xcode-project.md)、[ADR-0048](0048-verify-only-affected-modules.md)、[ADR-0052](0052-vrt-light-workflow-with-build-action.md)、移行計画は [doc/strategy/affected-vrt-ui-module-split.md](../strategy/affected-vrt-ui-module-split.md)

## 文脈、背景や問題点の説明

CI（Xcode Cloud）のVRTは、どのファイルを変えても全プレビュー（参照PNGは約1400枚）を流している。
ローカルはADR-0048で、直接変えたモジュールのプレビューだけに絞った。CIで絞るには推移的な依存まで広げる必要があるが、
今はすべてのFeatureと`HometeUI`が`HometeDomain`に依存しているため、`HometeDomain`を変えると全件になる。

`HometeDomain`の変更には、画面に出ないもの（Store・UseCase・Clientの実装の都合、Analyticsのイベントなど）も多い。
2026-04以降に`HometeDomain`のSwiftを変えたコミット311件のうち、171件はStore・UseCase・Clientのファイルだけの変更だった。
それでも全件のVRTになるのは、UIのモジュールが表示に関係しない型まで見えてしまう構成になっているためである。

## 決定事項

* `HometeDomain`から、UIが使う値型（ドメインモデル）を新しいモジュール`HometeModel`へ切り出す
  * 移すのは、`HometeUI`と各`XxxFeatureUI`が参照する型だけ。AnalyticsLog・RemoteConfigのキー・App Intent用の型など、
    UIが使わない値型は`HometeDomain`に残す
  * `HometeModel`はStore・UseCase・Clientのプロトコル・`previewValue`を持たない。依存は無し（最下層）
  * `HometeModel`の型が表示に使う文言は、`HometeModel`のString Catalogに置く
* Featureごとに、UIのみのView（`XxxView` / `XxxContent`）とプレビューを入れる`XxxFeatureUI`モジュールを作る
  * `XxxFeatureUI`の依存は`HometeModel`・`HometeUI`・`HometeResources`と、必要なら他の`YyyFeatureUI`だけ。**`HometeDomain`には依存させない**
  * `XxxFeature`には、ロジックを持つView（`XxxScreen` / `XxxComponent`）とStore連携を残す。依存は`XxxFeatureUI`・`HometeDomain`
  * プレビューは`XxxFeatureUI`と`HometeUI`にだけ置く。`XxxFeature`にはプレビューを置かない
* `HometeUI`の依存を`HometeModel`・`HometeResources`に変え、`HometeDomain`から切り離す
* CIのVRT（`VRT_light`）は、PRでは推移的な影響範囲に入ったVRTのモジュールのプレビューだけを流す
  * 影響範囲は`scripts/affected-modules.py`で、ADR-0048と同じ依存グラフから割り出す。VRTのモジュールは`.prefire.yml`の`testable_imports`
  * 次の場合は全件を流す
    * `HometeModel`・`HometeUI`・`HometeResources`の変更（推移的な依存で、結果的に全件になる）
    * `Package.resolved`の変更（swift-snapshot-testing・Prefireの更新で描画が変わる。#451で実際に約30枚変わった）
    * VRTの設定（`.prefire.yml`・テストプラン・`hometeVRT.xcodeproj`・`hometeSnapshotTests/Sources`・`hometeVRTHost`）の変更
    * リリースPR（`release/*` → `main`）。依存グラフに出ない変化（Xcode Cloudの環境の更新など）をリリース前に拾う
    * 差分の起点を決められなかったとき
  * 対象が無ければテストを流さずに成功させる

## 考慮した選択肢

* **CIは全件のまま**: 判定を誤る心配は無いが、Featureだけを変えたPRでも全プレビューを待つ
* **今の構成のまま、CIだけ推移的な依存で絞る**: すぐ入れられるが、`HometeDomain`の変更で全件になる。移行の第一歩としては採る（後述）
* **`HometeDomain`のうち描画に関係しないディレクトリを、判定スクリプトの除外リストで外す**: モジュール構成を変えずに済むが、
  除外が正しいかはコンパイラが保証せず、リストの保守も要る。UIが本当にその型を使っていないかを依存関係で保証できる方を採る
* **`XxxFeatureUI`が`HometeDomain`に依存したまま、モジュールだけ分ける**: UIのみのViewがドメインの型を受け取る限り、
  `HometeDomain`の変更はすべてのUIに届くので絞れない
* **UIを`HometeDomain`から完全に切り離し、表示用の型（ViewState）だけを受け取る**: 構造的にはもっとも確実だが、
  ドメインモデルと同じ形の型を画面ごとに持つことになり、変換層の工数と二重管理の負担が大きい。値型のドメインモデルは
  UIから使ってよいことにして、Store・UseCase・Clientからだけ切り離す
* **すべての値型を`HometeModel`へ移す**: ルールは単純になるが、AnalyticsLog（2026-04以降で55回変更）などの変更でも全件になる
* **`FeatureUI`を1つのモジュールにまとめる**: モジュールは1つ増えるだけだが、モジュール単位の判定ではどのFeatureのUIを変えても
  全Featureのプレビューが対象になる

## 決定結果

### 決定にあたり考慮したメリット

* Store・UseCase・Client・AnalyticsLogだけの変更や、Screenだけの変更では、CIのVRTが流れない（または一部だけになる）
* 「UIはStoreに依存しない」というルール（`ui-logic-view-separation`）を、レビューではなくモジュールの依存関係で保証できる
* プレビューがStoreや`previewValue`を使えなくなり、値を直接渡す形に統一される。表示のバリエーションを引数だけで並べられる
* 判定スクリプトに「移行済みかどうか」の分岐を持たせずに済む。未移行のFeatureは`HometeDomain`に依存したままなので、
  依存グラフから自然に対象に入る

### 決定にあたり考慮したデメリット

* モジュールが9つ増える（`HometeModel`と8つの`XxxFeatureUI`）。`Package.swift`・`.prefire.yml`の`testable_imports`・
  `hometeVRT.xcodeproj`のリンク設定・`affected-modules.py`の対応表を保守する必要がある
* Store・Screenの中にある表示用の派生状態を、`HometeModel`の値型か`XxxFeature`側へ移す作業が要る
* Storeを使っていたプレビュー（約20ファイル）は、UIのみのViewに分けてから値を渡す形に書き直す
* `HometeModel`を変えたときは全件のままになる（表示に効くので正しい挙動ではある）
* 依存グラフに出ない変化は、リリースPRまで見つからない

## 参考

* `scripts/affected-modules.py`、`scripts/run-affected-snapshots.sh`、`ci_scripts/ci_post_xcodebuild.sh`
* `.claude/rules/ui-logic-view-separation.md`、`.claude/rules/presentation-logic-placement.md`
* `doc/multimodules_structure.md`
