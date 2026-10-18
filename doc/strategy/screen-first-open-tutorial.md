# 画面を初めて開いたときのチュートリアル 実装方針

> 関連Issue: [#392 Feature: 画面を初めて開いたときのチュートリアル](https://github.com/stotic-dev/homete_iOS/issues/392)
> 親Issue: [#390 Feature: グループ登録後のチュートリアル](https://github.com/stotic-dev/homete_iOS/issues/390)（第1段は [#391](https://github.com/stotic-dev/homete_iOS/issues/391) / PR #402 でマージ済み）
> ブランチ: `feat/screen-first-open-tutorial`

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

家事登録シートと家事テンプレート画面を初めて開いたときに、その画面の使い方を一度だけ説明する。
グループ登録の直後（第1段）にまとめて説明すると長くなりすぎるため、ユーザーが自分でその画面を開いたときに出す。

## 要件

### 対象の画面

Issueの表から、方針整理（2026-10-17）で次のとおり絞った。

| 画面 | 扱い | 理由 |
|---|---|---|
| 家事登録シート | **出す** | 「いつもの家事」と「新しく入力」の違いが画面のどこにも書かれていない |
| 家事テンプレート画面 | **出す** | 空の表示は自分がまだ作っていないときしか出ず、パートナーが先に作っていると説明が無いまま一覧を見ることになる |
| 家事ボード | 出さない | 第1段（`RegistrationTutorialStep`）とほぼ重なる |
| 家事詳細 | 出さない | ナビゲーションバーにありがとうのボタンが出るので気づける |
| いつもの家事の管理画面 | 出さない | 空の表示で説明済み。役割は家事登録シートのチュートリアルで伝わる |

### 機能要件

- 各画面を初めて開いたときに一度だけ出す。最後まで見ても、途中で「閉じる」を押しても、二度と出さない
- アップデート前から使っている既存のユーザーにも出す
- 記録は第1段と同じく端末単位（`UserDefaults`）。再インストール・機種変更では引き継がない
- 第1段と同じく、スポットライトで対象のUIを切り抜き、説明のカードを重ねる。操作はさせず説明だけにとどめる。「前へ」「次へ」「閉じる」を置く
- 第1段の直後に続けて出さない
  - どちらの画面もユーザーの操作でしか開かず、第1段の表示中は後ろの画面を操作できないため、特別な制御は不要
- ほかのシート・Paywallに重ねない
  - 画面を開いた直後（ほかのシートが何も出ていない状態）に出す。チュートリアルの表示中は後ろの画面を操作できないため、途中でシートが重なることはない
  - 家事登録シートでは、表示中は下に引いて閉じられないようにする（`interactiveDismissDisabled`）

#### 家事登録シートのステップ

本番の画面をそのまま切り抜く。開いた直後は入力が空なので、サンプルの画面は作らない。

| # | ステップ | 切り抜くUI | 説明する内容 |
|---|---|---|---|
| 1 | 2つの入力方法 | 上の「いつもの家事 / 新しく入力」のタブ | 「いつもの家事」は登録しておいた家事をタップで選べる。「新しく入力」は名前を入れて登録する |
| 2 | まとめて登録 | 「続けて入力する」ボタン | 続けて入力すると家事がたまっていき、右上のボタンでまとめて登録できる |
| 3 | いつもの家事に保存 | 「いつもの家事に保存する」のトグル | オンにすると、次から「いつもの家事」タブでタップするだけで選べる |

- 2・3は「新しく入力」タブにしかないUIのため、ステップ2に進んだときに「新しく入力」タブへ切り替える
  - いつもの家事が登録済みのユーザーは「いつもの家事」タブで開くので、ステップ1はそのタブのまま見せる
- 無料プランでいつもの家事が上限に達しているときは、ステップ3を飛ばして2ステップにする。トグルの代わりにプランの案内が出ており、説明どおりに操作できないため

#### 家事テンプレート画面のステップ

「作成 → 家事を追加 → 自動で並ぶ → 保存」の流れを順に説明する。テンプレートを作成済みなら作成の説明は要らないため、ステップ1を飛ばして3ステップで出す。
画面の状態（空・作成済み・読み込み中）によって切り抜けるUIが変わるため、第1段の`HouseworkBoardTutorialView`と同じく、
**サンプルの値で描いた画面を本番の画面の上に重ねて**説明する。

| # | ステップ | 重ねる画面 | 切り抜くUI | 説明する内容 |
|---|---|---|---|---|
| 1 | テンプレートを作る | 空の表示 | 「テンプレートを作成する」ボタン | まずテンプレートを作成すると、家事を登録できるようになる |
| 2 | 家事を追加する | サンプルの一覧 | ＋ボタン | ＋から、曜日や毎月の日にちを選んで家事を追加できる |
| 3 | 自動で並ぶ | サンプルの一覧 | 先頭の曜日（月曜日）のセクション | 登録した家事は、その曜日・その日の家事ボードに自動で並ぶ |
| 4 | 保存して反映 | サンプルの一覧 | ナビゲーションバー全体（右上の✓を含む） | 変更は✓で保存するまでボードに反映されない。保存するとパートナーとも共有される |

- 3では「毎月」のセクションも切り抜く予定だったが、画面の下にあり説明のカードと重なるため切り抜かない（本文で触れる）
- 1を飛ばすかどうかは、`ScreenTutorialStore.startIfNeeded(skipping:)`に飛ばすステップを渡して決める。カードの「n / 全体」と「前へ」の有無も、飛ばした後のステップの並び（`steps`）から決める
- 4の✓は、ナビゲーションバーにボタンを1つだけ置いているため、iOS 26以降はシステムのボタンとして描かれ、`tutorialSpotlightTarget`を付けても（`HStack`で包んでも）位置を測れない。✓の見た目を変えずに済むよう、`tutorialSpotlightNavigationBarTarget`でバーごと切り抜く

- 説明の文言は`ux-writing.md`に沿って敬体・結果ベースで書き、英訳も同じ変更で入れる
- 文言の細部は実装時に決め、PRで確認する

### 非機能要件 / 制約

- 見せ方の部品（`tutorialSpotlight`）は第1段のものを使う
- 「見たか」の記録は、第1段の`RegistrationTutorialStateClient`とは意味が逆（第1段は「まだ見終わっていない」をtrueで持ち、未設定なら出さない。こちらは「見た」をtrueで持ち、未設定なら出す）なので、別のClientにする
- Analyticsは新しいイベントを1つ足し、画面はパラメータで区別する（[ADR-0009](../adr/0009-analytics-event-parameter-design.md)）
- テスト: Store・ステップの順番はユニットテスト、カード・サンプル画面はPreview（VRT）で確かめる

## 設計方針

### 1. ドメイン（`HometeDomain/Tutorial/`）

```swift
/// 初めて開いたときにチュートリアルを出す画面
public enum ScreenTutorial: String, CaseIterable, Sendable {
    case registerHousework = "register_housework"
    case houseworkTemplate = "housework_template"
}

public enum RegisterHouseworkTutorialStep: String, CaseIterable, Sendable {
    case inputSource = "input_source"
    case queue
    case saveAsFrequent = "save_as_frequent"
}

public enum HouseworkTemplateTutorialStep: String, CaseIterable, Sendable {
    case create
    case addItem = "add_item"
    case autoPlacement = "auto_placement"
    case save
}
```

- ステップの`index` / `next` / `previous`は`RegistrationTutorialStep`と同じものが要る。
  `CaseIterable`のステップに共通のプロトコル（`TutorialStep`）を切り出し、`RegistrationTutorialStep`も準拠させる（リファクタとして先に積む）

### 2. 「見た」の記録（`ScreenTutorialStateClient`）

```swift
public struct ScreenTutorialStateClient: Sendable {
    public let loadHasSeen: @Sendable (ScreenTutorial) async -> Bool
    public let saveHasSeen: @Sendable (ScreenTutorial) async -> Void
}
```

- `liveValue`は`AppRoot/Dependency/Impl/`に置き、`UserDefaults`のキーは`hasSeenScreenTutorial_<rawValue>`。未設定は`false`なので、既存のユーザーにも出る
- `AppDependencies`に足す。デバッグメニューに「画面のチュートリアルの記録を消す」を足して、何度でも確かめられるようにする

### 3. 表示状態（`ScreenTutorialStore<Step>`）

画面ごとに1つ作り、その画面のScreenが`@State`で持つ（画面を閉じれば破棄してよい）。

```swift
@MainActor
@Observable
public final class ScreenTutorialStore<Step: TutorialStep> {
    public private(set) var currentStep: Step?

    /// まだ見ていなければ最初のステップから出す
    public func startIfNeeded() async
    public func next(from step: Step) async   // 最後なら見たと記録して completed を送る
    public func back(from step: Step)
    public func close() async                 // 見たと記録して skipped(step) を送る
}
```

- `next` / `back`で「押したときのステップ」を受け取り、素早い2回押しでステップを飛ばさない作りは第1段と同じ
- 途中でアプリを終了されたときは出し直す（見たと記録するのは最後まで見たか閉じたときだけ）

### 4. 説明のカード（`HometeUI/Components/Tutorial/`）

- `RegistrationTutorialCard`の見た目（ステップ数・閉じる・アイコン・タイトル・本文・前へ/次へ）を、文言とアイコンを引数で受け取る`TutorialCard`に切り出す
  - 「どこから開けるか」の行は第1段専用なので、省略できる引数にする
  - `RegistrationTutorialCard`は`TutorialCard`を使う形にする（リファクタとして先に積み、VRTの差分が出ないことを確かめる）
- 各画面のステップごとの文言・アイコンは、その画面のFeatureに置く（`ui-attributes-in-view.md`）

### 5. 家事登録シート（`RegisterHouseworkView`）

- `NavigationStack`の外側に`.tutorialSpotlight`を付け、ナビゲーションバーの項目も切り抜けるようにする
- タブ・「続けて入力する」・トグルに`.tutorialSpotlightTarget(_:)`を付ける（`RegisterSourceTabs` / `ManualHouseworkForm`）
- `onAppear`で`startIfNeeded()`。いつもの家事が上限に達していれば`startIfNeeded(skipping: [.saveAsFrequent])`。ステップが`.queue`に変わったら`selectedTab = .manual`にする
- 表示中は`interactiveDismissDisabled`

### 6. 家事テンプレート画面

- `HouseworkTemplateView`は`HouseworkTemplateListStore`をEnvironmentから引いており、UIのみのViewになっていない。
  一覧部分（曜日・毎月のセクション、＋ボタン、✓ボタン）をUIのみの`HouseworkTemplateListContent`に切り出す（リファクタとして先に積む。`ui-logic-view-separation.md`）
- `HouseworkTemplateTutorialView`（新規）で、ステップ1は`HouseworkTemplateEmptyView`、ステップ2〜4は`HouseworkTemplateListContent`にサンプルの家事を渡して描く
- `HouseworkTemplateTutorialView`自身が`.tutorialSpotlight`と説明のカードを持ち、`HouseworkTemplateScreen`は表示中に本番の画面の上へ重ねるだけにする。
  スポットライトがチュートリアルの画面の中で閉じるので、後ろの本番の画面のUIは切り抜かれない。PreviewもScreenと同じ見た目（切り抜きとカード込み）を撮れる
- テンプレートの読み込みが終わってから出す。読み込みが終わるまでは`selectedTemplateId`がnilでも「テンプレートが無い」とは限らず、ステップ1を飛ばすかどうかを決められないため（`.task(id:)`で待つ。読み込みに失敗したら出さず、リトライで読み込めた時点で出す）
- テンプレートを作成済みなら、編集の準備（`HouseworkTemplateEditStore.startEditing`）が済むまで待つ。準備に失敗するとエラーの表示に切り替わり、その上でチュートリアルを最後まで見ると、使えない画面のまま見たことになってしまうため

### 7. Analytics（`screen_tutorial`イベント）

| パラメータ | 必須 | 値 |
|---|---|---|
| `screen` | ○ | `register_housework` / `housework_template` |
| `action` | ○ | `completed` / `skipped` |
| `step` | — | 閉じたときのステップ（`skipped`のときのみ） |

- `ScreenTutorialAnalyticsAction`を足し、`doc/analytics_events.md`に追記する
- 独立した画面ではないため`screen_view`は送らない

### 確認した技術的リスク

`tutorialSpotlight`は、切り抜くUIの位置をウィンドウの座標（`TutorialSpotlightWindowFrameReader`）で測り、
重ねる側の位置（`.global`）を引いて切り抜く。シートの中で両者の座標がずれないかを心配していたが、
シミュレータ（iOS 27）で家事登録シートの切り抜きが対象のUIとずれない（1〜2pt以内）ことを確かめた。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Tutorial/TutorialStep.swift` | ステップ共通のプロトコル（`index` / `next` / `previous`） |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Tutorial/RegistrationTutorialStep.swift` | `TutorialStep`に準拠させる |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Tutorial/ScreenTutorial.swift` | 対象の画面と、各画面のステップ |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Tutorial/ScreenTutorialStore.swift` | 表示状態 |
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/ScreenTutorialStateClient.swift` | 「見た」の記録 |
| 新規Client実装 | `InfraPackage/Sources/AppRoot/Dependency/Impl/ImplScreenTutorialStateClient.swift` | `UserDefaults`での実装 |
| 修正 | `LocalPackage/Sources/HometeDomain/Dependencies/AppDependencies.swift` ほか`liveValue` | Clientを足す |
| 新規Analytics | `LocalPackage/Sources/HometeDomain/AnalyticsLog/ScreenTutorialAnalyticsAction.swift` | `screen_tutorial`のパラメータ |
| 修正Analytics | `LocalPackage/Sources/HometeDomain/AnalyticsLog/AnalyticsEvent.swift` | イベントを足す |
| 新規UI | `LocalPackage/Sources/HometeUI/Components/Tutorial/TutorialCard.swift` | 説明のカードの共通部分 |
| 修正UI | `LocalPackage/Sources/HometeUI/Components/Tutorial/RegistrationTutorialCard.swift` | `TutorialCard`を使う |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/RegisterHouseworkView/RegisterHouseworkView.swift` | スポットライトとStore |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/RegisterHouseworkView/SubViews/ManualHouseworkForm.swift` ほか | 切り抜くUIに識別子を付ける |
| 新規View | `LocalPackage/Sources/Features/HouseworkFeature/Tutorial/RegisterHouseworkTutorialCard.swift` | ステップごとの文言・アイコン |
| 新規View | `LocalPackage/Sources/Features/HouseworkTemplateFeature/Template/SubViews/HouseworkTemplateListContent.swift` | 一覧部分のUIのみのView |
| 修正View | `LocalPackage/Sources/Features/HouseworkTemplateFeature/Template/HouseworkTemplateView.swift` | `HouseworkTemplateListContent`を使う |
| 修正View | `LocalPackage/Sources/Features/HouseworkTemplateFeature/Template/HouseworkTemplateScreen.swift` | スポットライトとStore |
| 新規View | `LocalPackage/Sources/Features/HouseworkTemplateFeature/Tutorial/HouseworkTemplateTutorialView.swift` | サンプルの値で描く画面と、スポットライト・カード |
| 新規View | `LocalPackage/Sources/Features/HouseworkTemplateFeature/Tutorial/HouseworkTemplateTutorialCard.swift` | ステップごとの文言・アイコン |
| 修正View | `LocalPackage/Sources/Features/SettingFeature/Debug/DebugMenuView.swift` | 記録を消す項目 |
| 修正Doc | `doc/analytics_events.md` | `screen_tutorial`を追記 |
| 修正 | 各モジュールの`Localizable.xcstrings` | 文言と英訳 |

## タスク

### Phase 1: 設計確定

- [x] 対象の画面を家事登録シートと家事テンプレート画面に絞る
- [x] 既存のユーザーにも出す
- [x] 家事登録シートのステップ（2つの入力方法 / まとめて登録 / いつもの家事に保存）
- [x] 家事テンプレート画面は、作成から保存までをサンプルの画面で説明する。テンプレートを作成済みなら作成のステップを飛ばす
- [x] 家事テンプレート画面のステップ（作成 / 追加 / 自動で並ぶ / 保存）
- [x] シートの中でスポットライトの切り抜きの位置が合うか、シミュレータで確かめる

### Phase 2: 実装

- [x] refactor: `TutorialStep`プロトコルを切り出し、`RegistrationTutorialStep`を準拠させる
- [x] refactor: `RegistrationTutorialCard`から`TutorialCard`を切り出す
- [x] refactor: `HouseworkTemplateView`の一覧部分を`HouseworkTemplateListContent`に切り出す
- [x] fix: 保存のステップでナビゲーションバーを切り抜く（`tutorialSpotlightNavigationBarTarget`を追加）
- [x] fix: 自動で並ぶステップで、カードが「毎月」の切り抜きを隠さないようにする
- [x] feat: `ScreenTutorial`・ステップ・`ScreenTutorialStateClient`・`ScreenTutorialStore`・Analytics（ユニットテスト含む）
- [x] feat: 家事登録シートのチュートリアル
- [x] feat: 家事テンプレート画面のチュートリアル
- [x] feat: デバッグメニューに記録を消す項目
- [x] docs: `doc/analytics_events.md`に`screen_tutorial`を追記
- [x] Preview（カードの各ステップ、`HouseworkTemplateTutorialView`の各ステップ）

### Phase 3: 検証

- [x] `swift build` でビルド通過
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過
- [x] ユニットテスト実行（追加分含む）通過
- [x] `make check-translations` 通過
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [x] シミュレータで動作確認（`simulator-e2e-check`。iPhone 18 Pro / iOS 27。iPhone SEのような小さい画面はVRTのカードのみで、実機の重なりは未確認）

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/392
- 既存実装（参考）:
  - `LocalPackage/Sources/HometeUI/Components/Tutorial/TutorialSpotlight.swift`
  - `LocalPackage/Sources/HometeUI/Components/Tutorial/RegistrationTutorialCard.swift`
  - `LocalPackage/Sources/HometeDomain/Tutorial/RegistrationTutorialStore.swift`
  - `LocalPackage/Sources/Features/HouseworkFeature/Tutorial/HouseworkBoardTutorialView.swift`
  - `InfraPackage/Sources/AppRoot/AppTabView.swift`（第1段の組み込み）
