# 家事の実施状況に応じたポジティブなコメント 実装方針

> 関連Issue: [#354 Feature: 家事の実施状況に応じたポジティブなコメントの表示](https://github.com/stotic-dev/homete_iOS/issues/354)
> ブランチ: `feat/analytics-comment`
> 生成方式の判断: ADR-0040（本対応で作成）
> 関連Issue（後続）: [#400 Private Cloud Compute（Foundation Models）のentitlement申請と設定](https://github.com/stotic-dev/homete_iOS/issues/400)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

ホームのダッシュボードにコメントカードを1枚置き、次の2つを表示する。

1. **自分へのねぎらい**: 自分の家事の実績を肯定するコメント。端末内のFoundation Modelsで1日1回生成し、使えないときは固定文言を出す
2. **同居人への感謝の促し**: 同居人がやってくれた家事に気づかせるコメントと「ありがとうを伝える」ボタン。ボタンから、ありがとうを伝えられる家事の一覧画面へ遷移する

家事の記録を「やった/やらない」の事実だけで終わらせず、本人への肯定と同居人への感謝のきっかけを作る。

## 要件

### 機能要件

#### コメントカードの配置

- ダッシュボード（`RegisteredContent`）の**今日の家事サマリーの上**に置く
- 全ユーザーに無料で提供する（プランで出し分けない）

#### 自分へのねぎらい

| 自分の当日の実績 | 表示するもの |
|---|---|
| 0件 | 中立・励ましの固定文言（例:「今日はゆっくり過ごせていますか。できることから、少しずつ進めていきましょう」）。LLMでは生成しない |
| 1件以上 | Foundation Modelsで生成したコメント。使えないときは、ねぎらいの固定文言 |

- 生成には、自分の実績に加えて**今日の家事サマリー**と**今月の家事貢献度（メンバー別）**を渡し、全体を見たコメントにする（Issueの「ねぎらいは自分の実績のみを参照」から変更）
- **生成は節目ごとに1回、1日最大2回**。当日のキャッシュは節目ごとに持ち、節目が変わるまでは作り直さない

  | 節目 | 条件 | 生成 |
  |---|---|---|
  | 実績なし | 自分の当日の完了0件 | しない（中立の固定文言） |
  | 取りかかり中 | 自分の完了1件以上、今日の家事に未完了がある | その日の最初の表示で1回 |
  | 全部完了 | 自分の完了1件以上、今日の家事が全て完了 | 全て完了した後の最初の表示で1回 |

- 実績0件の間は固定文言を出すだけなので、LLMの生成は実績が出た後だけになる
- 固定文言は数パターンから日付をもとに選び、同じ日は同じ文言、前日と同じ文言が続かないようにする
- 生成を待つ間はカード内にプレースホルダー（`redacted`）を出し、ダッシュボードの他の表示を止めない
- Foundation Modelsを使えない次のケースでは、ねぎらいの固定文言にフォールバックする
  - iOS 26未満、非対応端末、Apple Intelligenceがオフ、モデルの準備中、日本語に対応していない
  - 生成エラー、タイムアウト（10秒）
  - 生成結果に禁止表現が含まれる、空文字、長すぎる（80文字超）

#### 同居人への感謝の促し

- **今日・昨日に同居人が完了した家事で、自分がまだありがとうを送っていないもの**が1件以上あるときだけ表示する。ない場合や同居人がいない場合は、ねぎらいだけを出す
  - 昨日も含めるのは、同居人が夜遅くにやった家事に翌朝気づけるようにするため（`HouseworkListStore`が持つ±3日の範囲内）
- 文言は**件数入りの固定テンプレート**（LLMでは生成しない）。ありがとうを送るたびにその場で件数を更新し、0件になったら促しを消す
  - 1人: 「{名前}さんが{n}件の家事をしてくれました。ありがとうを伝えてみませんか？」
  - 2人以上: 「{名前}さん・{名前}さんが{n}件の家事をしてくれました。ありがとうを伝えてみませんか？」
  - 「あなたが送っていない」ことは書かない（相手がやってくれたことに焦点を当てる）
- カードに「ありがとうを伝える」ボタンを置き、タップで**ありがとうを伝えられる家事の一覧画面**（新規）へ遷移する

#### ありがとうを伝えられる家事の一覧画面（新規）

- ダッシュボードのナビゲーション（`RegisteredContentRoute`）にpushする。タイトルは「ありがとうを伝える」
- 今日・昨日に完了した家事のうち、自分以外が担当者に含まれるもの（`isThankable`）を、未送信 → 送信済みの順、各グループ内は完了日時の新しい順に並べる
  - 送った後も一覧から消さず、送信済みの表示に切り替える（送った直後に行が消えて戸惑わないように）
- 行は家事ボードの完了リストと同じ`HouseBoardListRow`（担当者名・ありがとうの状況つき）
  - ハートのタップ: コメントなしでありがとうを送る（家事ボードと同じ）
  - 行のタップ: 既存の「ありがとうを伝える」ハーフモーダル（`HouseworkThanksView`）を開く。送信済みならメッセージの編集として開く
- 0件のとき: 「ありがとうを伝えられる家事はありません」
- 初めてありがとうを送ったときの演出は家事ボードと同じものを出す（既存の`onSentFirstThanks`を流用）

### トーンのガイドライン

- 禁止: 家事量の偏り・少なさを責める表現、同居人との比較・順位づけ、「〜しかしていない」「もっと〜すべき」などの要求・評価、未完了・遅れの指摘
- 同居人のメンバー別の実績も生成に渡すため、比較・順位づけの文が出やすくなる。次の2段で防ぐ
  1. instructionsで「同居人の実績は、一緒に家事を回していることを認める材料にだけ使い、人と人を比べない・割合や差を述べない・どちらが多いかに触れない」と明示する
  2. 生成結果を禁止表現リストで検証し、引っかかったら固定文言にフォールバックする。比較を表す語（「一番」「偏り」「差」「割合」「％」など）も禁止表現に含める
- 同居人の名前に触れるときは、その人がやってくれたことへの感謝・称賛にとどめる
- Foundation Modelsのinstructionsでトーンを指示したうえで、生成結果を禁止表現リストで検証し、引っかかったら固定文言にフォールバックする
- 固定文言・テンプレート・instructionsは`.claude/rules/ux-writing.md`に沿って敬体で書く

### 非機能要件 / 制約

- 生成は端末内で完結する（`SystemLanguageModel`）。Private Cloud Computeは初回リリースでは使わず、#400で追加する
- アプリのデプロイターゲットはiOS 17のため、Foundation Modelsは`#if canImport(FoundationModels)` + `#available(iOS 26, macOS 26, *)`で囲む
- CI（Xcode 26.4.1）でもビルドが通るAPIだけを使う（iOS 26 SDKのAPIに限る）
- ユニットテストはLLMを呼ばない。生成Clientをモックに差し替えて、表示の出し分けとフォールバックを検証する

## 設計方針

### 1. 生成Client（`EncouragementCommentClient`）

`HometeDomain/Dependencies/EncouragementCommentClient.swift`にClientを定義し、`liveValue`を既存のClientと同じく`AppRoot/Dependency/Impl/ImplEncouragementCommentClient.swift`に実装する。instructionsとプロンプトの組み立ては`HometeDomain/Encouragement/EncouragementPrompt.swift`に置き、live実装はモデルを呼ぶだけにする。

```swift
public struct EncouragementCommentClient: Sendable {

    /// Foundation Modelsで、ねぎらいのコメントを生成する
    /// - Throws: 使えない端末・生成エラー・タイムアウト。呼び出し側は固定文言にフォールバックする
    public let generate: @Sendable (EncouragementContext) async throws -> String

}
```

- `liveValue`の中で、`SystemLanguageModel.default.availability`と`supportsLocale`を確認し、使えなければ`EncouragementCommentError.unavailable`を投げる
- `LanguageModelSession(instructions:)`にトーンのガイドラインを書いたinstructionsを渡し、`respond(to:)`で文字列を生成する
- タイムアウトは`withThrowingTaskGroup`で10秒

### 2. 入力データ（`EncouragementContext`）

`HometeDomain/Encouragement/`に置く。生成時はこれを箇条書きのプロンプトに変換して渡す（数百トークン程度で、端末内モデルのコンテキスト約4Kに収まる）。

**自分**

| 項目 | 内容 |
|---|---|
| `todayCompletedTitles` | 今日自分が完了した家事のタイトル（最大5件） |
| `todayCompletedCount` | 今日自分が完了した件数 |
| `todayEffortfulCount` | 今日「がんばった」「超頑張った」で完了した件数 |
| `weeklyCompletedCount` | 今日を含む直近7日に自分が完了した件数 |
| `streakDays` | 今日まで連続で1件以上完了した日数 |

**今日の家事サマリー**（ダッシュボードの「今日の家事サマリー」と同じ値）

| 項目 | 内容 |
|---|---|
| `todayTotalCount` | 今日の家事の件数（テンプレートの未登録分を含む） |
| `todayHouseholdCompletedCount` | 今日完了した件数（世帯全体） |
| `isTodayAllCompleted` | 今日の家事が全て完了したか |

**今月の家事貢献度**（メンバー別。自分を含む）

| 項目 | 内容 |
|---|---|
| `userName` / `isOwn` | 名前と、自分かどうか |
| `completedCount` / `point` | 今月の完了件数とポイント（担当者ごとに配分されたポイント） |
| `frequentTitles` | 今月よく完了した家事（上位3件） |

- 複数人で担当した家事は、担当者それぞれに1件と数える（`HouseworkContribution`・`TodayHouseworkSummary.memberContributions`と同じ考え方）
- 今日の件数はテンプレートの未登録分を含めて数える必要があるため、Viewが`TodayHouseworkSummary`から`todayTotalCount`を渡す
- 直近7日・連続日数・今月の集計は±3日の`HouseworkListStore`では足りないため、`HouseworkManager`が持つワンショットフェッチ分（プランに応じた期間）から集計する。`ContributionStore`と同じく`houseworkManager.createObserver`で購読する
- 未完了の家事のタイトルや件数そのものは渡さない（「まだ終わっていない」ことを指摘する材料を与えない）。渡すのは完了の件数と、全て完了したかどうかだけ

### 3. 表示状態のStore（`EncouragementCommentStore`）

`HometeDomain/Encouragement/EncouragementCommentStore.swift`（`@MainActor @Observable`）。

- 状態: `selfPraise: SelfPraiseState`（`.loading` / `.loaded(EncouragementComment)`）
- `EncouragementComment`は`text`と`kind`（`.neutral` / `.selfPraise`）と`source`（`.generated` / `.fixed`）を持つ
- 処理の流れ
  1. 節目を判定する（実績なし / 取りかかり中 / 全部完了）
  2. 実績なし → 中立の固定文言
  3. 当日・同じ節目のキャッシュがある → キャッシュ
  4. キャッシュがない → `generate` → `EncouragementToneValidator`で検証 → キャッシュに保存
  5. 4で失敗 → ねぎらいの固定文言（これもその節目のキャッシュに入れ、同じ節目で何度も生成を試みない）
- キャッシュは`EncouragementCommentCacheClient`（`UserDefaults`）に、ユーザーID・日付・節目・文言を1件だけ保存する。どれかが違えば無効
- 全て完了した後に誰かが家事を追加して未完了に戻っても、その日に「取りかかり中」を作り直さない（全部完了のキャッシュを持っている間はそれを出す）
- 生成中に日付が変わる・同じ日に二重に生成が走る、を防ぐため、生成中のTaskを1つだけ持つ

### 4. 禁止表現の検証（`EncouragementToneValidator`）

`HometeDomain/Encouragement/`。純粋な関数として、禁止語（「しかしていない」「もっと」「すべき」「サボ」「少ない」「足りない」「負け」「勝ち」「比べ」「順位」「ランキング」「一番」「偏り」「差」「割合」「％」「未完了」「遅れ」「なさい」など）を含まないか、空でないか、80文字以内かを判定する。固定文言とテンプレートもこのValidatorを通ることをテストで担保する。

### 5. 感謝の促し（`ThanksPromptSummary`）

`HouseworkFeature/Model/ThanksPromptSummary.swift`。`HouseworkBoardItem`の`isThankable` / `sentThanks`を使うためHouseworkFeatureに置く。

```swift
public struct ThanksPromptSummary: Equatable, Sendable {

    /// 今日・昨日に完了した、ありがとうを伝えられる家事（未送信 → 送信済み、完了日時の新しい順）
    public let thankableItems: [HouseworkBoardItem]
    /// まだありがとうを送っていない家事の件数
    public let notSentCount: Int
    /// 未送信の家事の担当者（自分以外）の名前
    public let executorNames: [String]

    public static func make(
        storedAllItems: StoredAllHouseworkList,
        members: CohabitantMemberList,
        ownUserId: String,
        now: Date,
        calendar: Calendar
    ) -> Self

    /// 促しを出すかどうか
    public var shouldPrompt: Bool { notSentCount > 0 }

}
```

`HouseworkListStore.items`から毎回計算するので、ありがとうを送ればリスナー経由で自動的に件数が変わる。

### 6. 画面

- `EncouragementCommentCard`（`HomeFeature/HomeView/SubViews/RegisteredContent/Components/`）: ねぎらい + 感謝の促し（条件付き）+ 「ありがとうを伝える」ボタン
- `ThanksTargetListView`（`HouseworkFeature/ThanksTargetList/`）: ありがとうを伝えられる家事の一覧。`IncompleteHouseworkListView`と同じ作り
- `RegisteredContentRoute`に`.thanksTargetList`を追加し、`RegisteredContent.navigationHandler`で解決する
- `HouseworkThanksView`に`step`引数（デフォルト`.thanks`）を足し、一覧画面からは`.commentPrompt`を渡す

### 7. Analytics

[doc/analytics_events.md](../analytics_events.md)の方針どおり、機能単位のイベントを1つ追加し、既存のパラメータ名を再利用する。

| イベント | パラメータ | 値 | 送信タイミング |
|---|---|---|---|
| `encouragement_comment` | `action` | `shown` / `tapped` | `shown`: カードの表示時（ねぎらい・促しそれぞれ）、`tapped`: 「ありがとうを伝える」ボタンのタップ時 |
| | `kind` | `self_praise` / `neutral` / `thanks_prompt` | 表示した・タップしたコメントの種類 |
| | `step` | `dashboard` | 表示場所（将来の家事完了直後のひとことに備える） |
| `housework`（既存） | `step` | `comment_prompt`（追加） | ありがとうを伝えられる家事の一覧から`send_thanks` / `edit_thanks`したとき |

- 生成方式（LLM/固定文言）は分析の必要が出るまでパラメータにしない（カスタムディメンションを増やさない）
- 一覧画面の`screen_view`に`thanks_target_list`を追加する

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/EncouragementCommentClient.swift` | 生成Clientの定義と`previewValue` |
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/EncouragementCommentCacheClient.swift` | 当日のコメントのキャッシュ |
| 修正 | `LocalPackage/Sources/HometeDomain/Dependencies/AppDependencies.swift` | 2つのClientを追加 |
| 新規live | `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplEncouragementCommentClient.swift` | Foundation Modelsでの生成（可否判定・タイムアウト） |
| 新規live | `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplEncouragementCommentCacheClient.swift` | `UserDefaults`での保存 |
| 修正 | `LocalPackage/Sources/AppRoot/Dependency/AppDependencies+liveValue.swift` | `liveValue`の注入 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Encouragement/` | `EncouragementContext`、`EncouragementComment`、固定文言、`EncouragementToneValidator`、`EncouragementCommentStore` |
| 新規Analytics | `LocalPackage/Sources/HometeDomain/AnalyticsLog/EncouragementCommentAnalyticsAction.swift` | `encouragement_comment`のパラメータ |
| 修正Analytics | `LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift`、`AppScreen.swift`、`AnalyticsEvent.swift` | `comment_prompt`、`thanks_target_list`、イベント追加 |
| 新規モデル | `LocalPackage/Sources/Features/HouseworkFeature/Model/ThanksPromptSummary.swift` | 感謝の促しの集計 |
| 新規View | `LocalPackage/Sources/Features/HouseworkFeature/ThanksTargetList/ThanksTargetListView.swift` | ありがとうを伝えられる家事の一覧 |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkThanks/HouseworkThanksView.swift` | `step`引数の追加 |
| 新規View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/Components/EncouragementCommentCard.swift` | コメントカード |
| 修正View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/RegisteredContent.swift`、`HomeView.swift` | カードの配置、Storeの生成・注入、遷移先の追加 |
| 新規ADR | `doc/adr/0040-encouragement-comment-with-foundation-models.md` | 生成方式の判断 |
| 修正Doc | `doc/analytics_events.md` | イベントの追加 |

## タスク

### Phase 1: 設計確定

- [x] 生成方式: 端末内Foundation Models + 固定文言フォールバック（PCCは#400）
- [x] 表示場所: ダッシュボードの今日のサマリーの上
- [x] 実績0件の日: 中立の固定文言を出す
- [x] 生成の入力: 自分の実績 + 今日の家事サマリー + 今月のメンバー別貢献度
- [x] 生成のタイミング: 節目（取りかかり中・全部完了）ごとに1回、1日最大2回
- [x] 感謝の促し: 件数入りの固定テンプレート + 「ありがとうを伝える」ボタン → ありがとうを伝えられる家事の一覧画面
- [x] 本ドキュメントのレビュー（集計期間・キャッシュ・一覧画面の振る舞い）

### Phase 2: 実装

- [x] ADR-0040の作成
- [x] `EncouragementToneValidator`と固定文言
- [x] `EncouragementContext`の集計（自分・今日のサマリー・今月のメンバー別貢献度）
- [x] `EncouragementCommentClient` / `EncouragementCommentCacheClient`の定義とlive実装
- [x] `EncouragementCommentStore`
- [x] `ThanksPromptSummary`
- [x] `ThanksTargetListView`と`HouseworkThanksView`の`step`引数
- [x] `EncouragementCommentCard`とダッシュボードへの配置
- [x] Analytics（`encouragement_comment`、`comment_prompt`、`thanks_target_list`）
- [x] `doc/analytics_events.md`の更新
- [x] Preview（VRT）の追加

### Phase 3: 検証

- [x] `swift build` でビルド通過
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過
- [x] ユニットテスト（Validator・固定文言、`EncouragementContext`の集計、Storeの節目判定・フォールバック・キャッシュ、`ThanksPromptSummary`の出し分け、Analyticsのパラメータ）
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] 実機/シミュレータで動作確認（Apple Intelligence対応端末で実際に生成されること）

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/354
- 後続Issue（PCC）: https://github.com/stotic-dev/homete_iOS/issues/400
- 既存実装（参考）:
  - `LocalPackage/Sources/Features/ContributionFeature/Model/ContributionStore.swift`（`HouseworkManager`の購読）
  - `LocalPackage/Sources/Features/HouseworkFeature/IncompleteHouseworkListView/IncompleteHouseworkListView.swift`（ダッシュボードからpushする一覧）
  - `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkThanksStatus.swift`（ありがとうの状況）
  - `LocalPackage/Sources/Features/HouseworkFeature/HouseworkThanks/HouseworkThanksView.swift`
