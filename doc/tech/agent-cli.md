# CLIと行動テストでアプリの振る舞いを確かめる

> この仕組みを入れた背景は [ADR-0072](../adr/0072-app-core-view-models-and-behavior-cli.md) を参照。

`AgentToolsPackage` の `homete-cli` と行動テストは、`HometeAppCore` のViewModel（iOSのアプリが使うものと同じ）を、
シミュレーターを起動せずに動かす。ViewModelにした画面の振る舞いを短い周期で確かめるときは、まずここで確かめる。

| 道具 | 使いどころ |
|---|---|
| `make run-cli` | 画面の状態と操作を対話的に確かめる。実装の途中で「この操作でこうなるか」を見る |
| `make test-behavior` | 一連の振る舞いを行動テストとして残し、CIで流し続ける |
| `make test-affected` | ViewModel単体（`HometeAppCoreTests`）・Store（`HometeDomainTests`）のユニットテスト |

見た目（レイアウト・文言）は確かめられない。それはVRTとシミュレーターで確かめる（`swift-code-verification`・`simulator-e2e-check` スキル）。

いまCLIから動かせる画面は、ダッシュボードの「今日の家事」と「完了にするシート」だけ。ほかの画面は、ViewModelにしたときに足す（下の「画面・操作・シナリオを足す」）。

## CLIを動かす

```bash
make run-cli                                  # シナリオ today（今日の家事が3件）で起動
make run-cli SCENARIO=complete-fails-once     # シナリオを選ぶ
```

標準入力から1行に1つのコマンドを受け取り、標準出力へ1行に1つのJSONを返す。ビルドのログ・Storeの`print`などの診断は標準エラー出力に出るので、
標準出力はそのままJSONとして読める。

| コマンド | 返すもの |
|---|---|
| `ls` | 今の画面・状態・実行できる操作（`snapshot`） |
| `do <JSON>` | 操作を実行し、非同期の処理（書き込み）が終わった後の `snapshot` |
| `scenarios` | 選べるシナリオ |
| `quit` | 終了する |

まとめて流すときはパイプで渡す。

```bash
printf '%s\n' \
  'do {"action":"complete","arguments":{"id":"laundry"}}' \
  'do {"action":"selectEffort","arguments":{"effort":"hard"}}' \
  'do {"action":"toggleMember","arguments":{"userId":"partner"}}' \
  'do {"action":"save"}' \
  'do {"action":"finishPraise"}' \
  | make run-cli 2>/dev/null
```

### 出力

```json
{"ok":true,"snapshot":{"availableActions":[{"arguments":[],"name":"dismiss","summary":"シートを下へスワイプして閉じる"}, …],
  "currentScreen":"houseworkComplete",
  "houseworkComplete":{"completedPoint":12,"effort":"hard","executors":[{"percentage":50,"userId":"own"},{"percentage":50,"userId":"partner"}],
    "houseworkId":"laundry","isCompleting":false,"selectableMemberIds":["own","partner"],"title":"洗濯","totalPoint":12},
  "todayHousework":{"completedCount":2,"incomplete":[{"id":"cleaning","point":20,"title":"掃除"}],"totalCount":3}}}
```

- `currentScreen` は一番上に出ている画面。`availableActions` はその画面（と、それを出している親のシートを閉じる操作）で実行できる操作だけが並ぶ
- iOSの画面で押せない・出ていない操作も並ばない。完了にしている途中は `save`・`close`・`dismiss` が無く、完了にした後は入力と `close` が無く `finishPraise` が並ぶ。`dismissError` はエラーが出ているときだけ並ぶ
- 未完了の家事は、iOSと同じくポイントの大きい順に並ぶ
- 受け付けられない操作は `{"ok":false,"error":{"code":"…","message":"…"}}` で返り、続くコマンドも受け付ける

| `error.code` | 意味 |
|---|---|
| `invalidRequest` | JSONとして読めない・不明なコマンド |
| `unknownAction` | そういう名前の操作は無い |
| `actionNotAvailable` | 今の画面・状態では実行できない（シートが出ている間の背景の操作など） |
| `invalidArguments` | 引数が足りない・余っている・値が読めない |

### 今ある操作

| 画面 | 操作 | ViewModelへ送るAction |
|---|---|---|
| `todayHousework` | `complete`（`id`。未完了の家事があるときだけ） | `TodayHouseworkViewModel.Action.completeTapped` |
| `houseworkComplete` | `selectEffort`（`effort`: `normal`・`hard`・`veryHard`） | `HouseworkCompleteViewModel.Action.effortSelected` |
| `houseworkComplete` | `toggleMember`（`userId`） | `.memberToggled` |
| `houseworkComplete` | `save`（完了にできるときだけ） | `.completeTapped` |
| `houseworkComplete` | `close`（完了にする前だけ） | `.closeTapped` |
| `houseworkComplete` | `dismiss`（完了にしている途中は無い） | `TodayHouseworkViewModel.Action.completionDismissed`（シートを下へスワイプ） |
| `houseworkComplete` | `finishPraise`（完了にした後だけ） | `.praiseFinished` |
| `houseworkComplete` | `dismissError`（エラーが出ているときだけ） | `.errorDismissed` |

### シナリオ

| 名前 | 開始時点 |
|---|---|
| `empty` | 今日の家事が無い |
| `today` | 今日の家事が3件（洗濯 `laundry`・掃除 `cleaning` が未完了、料理 `cooking` が完了済み）。自分 `own` とパートナー `partner` の2人 |
| `complete-fails-once` | `today` と同じ。最初の書き込みだけ失敗する |

現在日時は2026/1/1 12:00（JST）に固定している。プロセスごとに新しい保存先を作るので、起動をまたいで完了は残らない。

## 行動テストを書く・流す

```bash
make test-behavior                                      # 全部
make test-behavior FILTER=HouseworkCompleteBehaviorTests
```

テストは `AgentToolsPackage/Tests/HometeBehaviorTests/` に置き、`BehaviorDriver` でCLIと同じ `AppIntrospector` を通して操作する。

```swift
let driver = BehaviorDriver(.today)
try driver.perform("complete", ["id": "laundry"])
try await driver.performAndSettle("save")

#expect(driver.snapshot == AppSnapshot(…))   // 状態は丸ごと比べる（swift-test-implementation スキル）
```

- 非同期の処理の完了は `performAndSettle` / `introspector.settle()` で待つ。固定時間のsleepは使わない
- 書き込んだ家事は `driver.backend.items` で確かめる
- CLIのプロセスそのもの（JSONの入出力）は `CLIProcessTests` で確かめている。操作を足しただけなら、行動テストはIntrospection経由で書けばよい

## 画面・操作・シナリオを足す

1. 画面の状態と操作を `HometeAppCore` のViewModel（`State`・`Action`・`Message`・`update`）に足し、`HometeAppCoreTests` でテストする。
   UIPackageの `XxxScreen` は状態を読んで `send(_:)` するだけにする（[multimodules_structure.md](../multimodules_structure.md)）
2. `HometeIntrospection` の `AppSnapshot` に状態を、`AppIntrospector` の `availableActions()` と `allActionNames` に操作を足す。ここではActionへ渡すだけにし、判断はViewModelに置く
3. 外部依存の振る舞いを変えたいなら、`HometeScenarioSupport` のfixture（`FixtureHouseworkBackend` など）に制御を足し、`Scenario` に名前付きのシナリオを足す（CLIから選べるのは `Scenario.all` に入れたものだけ）
4. 一連の振る舞いを `HometeBehaviorTests` に足し、このドキュメントの「今ある操作」「シナリオ」の表を更新する

Introspectionに業務ロジックや画面ごとの分岐を書き足さない。CLIからDomainのStoreを直接呼んでViewModelを迂回しない。
