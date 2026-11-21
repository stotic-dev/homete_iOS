## タイトル: 画面単位のViewModelをHometeAppCoreに置き、同じViewModelをCLIと行動テストから動かす

* **承認済**
* 意思決定者: stotic-dev
* 日付: 2026-11-14
* 関連: [ADR-0003](0003-usecase-layer.md)、[ADR-0063](0063-split-ui-modules-from-domain-for-affected-vrt.md)、[ADR-0071](0071-split-ui-package.md)、Issue #515

## 文脈、背景や問題点の説明

AIエージェントが実装した振る舞いを、シミュレーターを起動せずに短い周期で確かめたい。
StoreのユニットテストはLocalPackageで流せるが、画面ごとの状態（選んだ頑張り度・担当者・完了にしている途中・エラー・シートの表示・閉じる判断）は
`XxxScreen`の`@State`にあり、「今日の家事から完了にするシートを開く → 頑張り度を選ぶ → 完了にする → 演出の後に閉じる → 一覧から外れる」
という一連の振る舞いを確かめる手段が、シミュレーターでの操作しかなかった。

## 決定事項

* `HometeAppCore`（LocalPackage）に、画面単位のViewModelを置く。まず「今日の家事」（`TodayHouseworkViewModel`）と「完了にするシート」（`HouseworkCompleteViewModel`）から入れる
  * `@MainActor`・`@Observable`。UIからは`state`を読み、操作は`send(Action)`で送る。状態の変更は`update(Message)`に集め、非同期の結果も`Message`で戻す
  * 共有データの正はStore（`HouseworkListStore`）。一覧（`summary`）はStoreの写しを今日の分に絞ったもので、別に持たない
  * シートを出すか（`completion`）は親のViewModelを唯一の正にし、下へのスワイプで閉じたこともActionとして送る
  * 完了にしている途中の再要求・閉じる操作は、ボタンの非活性だけに頼らずViewModelで捨てる。閉じた画面に後から届いた結果は捨てる
  * エラーは`DomainError`で持ち、文言はUI側で決める
  * 非同期の処理は`TaskTracker`から始め、CLI・テストは`waitUntilIdle()`で完了を待つ（固定のsleepで待たない）
* `XxxScreen`（UIPackage）は、ViewModelの状態をUIのみのView（`XxxView`）へ渡し、Binding・ボタン・アラート・シートを`send(_:)`につなぐだけにする
* 新しく`AgentToolsPackage`を足す。ホスト（macOS）向けにだけビルドし、UIPackage・InfraPackageには依存しない
  * `HometeIntrospection`: 今の画面・状態・実行できる操作をJSONにし、JSONの操作をViewModelの`send(_:)`へ渡す。業務ロジックや画面の分岐は持たない
  * `HometeScenarioSupport`: シナリオごとに独立した保存先（`FixtureHouseworkBackend`）を作り、`HouseworkClient`の境界で書き込みの失敗を制御する
  * `HometeCLI`（`homete-cli`）: 標準入力の1行ごとのコマンド（`ls`・`do <JSON>`）を受け、標準出力へJSONを1行ずつ返す。Storeなどの`print`は標準エラー出力へ回す
  * `HometeBehaviorTests`: Introspection経由の行動テストと、CLIのプロセスの入出力のテスト
* `make build-cli`・`make test-behavior`・`make run-cli`を足し、`ci_agent_tools.yml`で行動テストを流す。`make affected`は行動テストの要否も出す
* 他の画面のViewModel化は、この決定に含めず、画面を触る機会に同じ形で進める

## 考慮した選択肢

* **StoreだけをCLIから公開する**: 変更は小さいが、入力・エラー・シート・閉じる判断がScreenに残り、確かめたい振る舞いに届かない
* **画面ごとの状態もStoreに持たせる**: 共有データと画面の一時的な状態が混ざり、Storeを画面に依存させない方針から外れる
* **UIテストで確かめる**: UIとのつなぎの確認には役立つが、シミュレーターが要り、短い周期で回せない
* **全画面を一度にViewModelにする**: 方針はそろうが、変更が大きすぎて1つのPRでレビューできない
* **画面単位のViewModelをHometeAppCoreに置き、CLIは別パッケージにする（採用）**

## 決定結果

### 決定にあたり考慮したメリット

* iOSのUIとCLI・行動テストが同じViewModelの`state`と`send(_:)`を使うので、CLIで確かめた振る舞いがそのままアプリの振る舞いになる
* シートの表示・閉じる判断・完了にしている途中の扱いを、SwiftUIを作らずにテストで確かめられる

### 決定にあたり考慮したデメリット

* モジュール（HometeAppCore）とパッケージ（AgentToolsPackage）が増え、Makefile・CI・判定スクリプトの保守が増える
* Screenに書いていた処理を、ViewModelのAction・Message・updateに書き直す手間がかかる
* `HouseworkListStore`は書き込んだ家事を`HouseworkManager`の通知から受け取るため、CLI・テストは処理の完了後にMainActorの順番を譲ってから状態を読む（`AgentSession.settle()`）

## 参考

* [doc/tech/agent-cli.md](../tech/agent-cli.md)
* [doc/multimodules_structure.md](../multimodules_structure.md)
* 参考にした構成: [rikugame-biyori-ios](https://github.com/stotic-dev/rikugame-biyori-ios) の ADR-0014
