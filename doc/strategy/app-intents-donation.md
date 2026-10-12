# App Intentsとドネーションでアプリ外から家事を進める 実装方針

> 関連Issue: [#434 App Intentsとドネーションで、アプリを開かずに家事の完了・ありがとう・がんばりの確認をできるようにする](https://github.com/stotic-dev/homete_iOS/issues/434)
> ブランチ: `feat/appintent`
> 技術選定: [ADR-0044](../adr/0044-app-intents-headless-usecase-and-title-keyed-entity.md)

## ステータス

- [x] 要件確定
- [ ] 設計確定（Phase 1の検証項目が残っている）
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

App Intentsを使って、アプリを開かなくてもSiri・Spotlight・ショートカットApp・アクションボタンから「家事の完了」「ありがとう」「がんばりの確認」をできるようにする。
アプリの中でこれらの操作をしたときにドネーション（寄付）しておき、OSがロック画面やSpotlightで「いつもの時間に、いつもの操作」を提案できるようにする。
アプリを開く手間をなくし、完了の記録とありがとうの回数を増やすのが狙い。

## 要件

### 確定した前提

| 論点 | 決定 |
|---|---|
| 家事の完了 | 「アプリを開かずに完了」と「アプリを開いて完了シートを出す」の両方を用意する |
| ありがとう | アプリを開かずに送る。コメントは任意の引数にし、入れたときだけ今と同じPush通知を送る |
| がんばりの確認 | 「Siriの結果に要約を出す」と「アプリの分析画面を開く」の両方を用意する |
| 入口 | App Shortcuts（Siri・Spotlight・ショートカットApp・アクションボタン）とドネーションによる提案。ウィジェット・コントロールセンターは今回のスコープ外 |

### 機能要件

#### Intent一覧

| Intent | アプリを開くか | 引数 | 結果 |
|---|---|---|---|
| `CompleteHouseworkIntent`（家事を完了にする） | 開かない | 家事（必須） | 「おつかれさまでした。洗濯を記録しました（+20pt）」と返す |
| `OpenHouseworkCompleteIntent`（家事の完了を記録する） | 開く | 家事（必須） | 家事ボードを開き、その家事の完了シートを出す |
| `SendThanksIntent`（ありがとうを伝える） | 開かない | 家事（任意）・コメント（任意） | 「はなこさんに、ありがとうを伝えました」と返す |
| `ShowContributionSummaryIntent`（今月のがんばりを見る） | 開かない | なし | 今月のメンバーごとのポイントと割合をスニペットで出す |
| `OpenContributionAnalyticsIntent`（がんばりの分析を開く） | 開く | なし | ダッシュボードを開き、分析画面へ遷移する |

#### 家事の完了（開かない）

1. 候補は**今日の未完了の家事**。Siriで名前を言ったときは家事の名前で探す
2. 担当者は自分だけ、頑張り度は「ふつう」で記録する（一括完了`completeBulk`と同じ既定値）。コメントは付けない
3. 実行した時点でサーバーから今日の家事を取り直し、同じ名前の未完了の家事の先頭（作成日時の古い順）を完了にする。見つからなければ「今日の家事に洗濯はありません」と返して何もしない（すでに完了していた場合は「洗濯はもう終わっています」）
4. 同居人への完了通知は、アプリで完了にしたときと同じ条件で送る（今日の家事なら1日1回）
5. 自分の端末のふりかえり通知の予約にも反映する（`DailyCompletionReminderUseCase.syncToday`）

#### 家事の完了（アプリを開く）

6. アプリを開いて家事ボードに切り替え、家事の読み込みを待ってから、その家事の完了シート（`HouseworkCompleteSheet`）を出す
7. 家事が見つからない・すでに完了している場合は、家事ボードを開くだけにする（通知のタップで家事詳細を開くときと同じ扱い）

#### ありがとう

8. 候補は、ダッシュボードの感謝の促し（`ThanksPromptSummary`）と同じく、**今日と昨日に同居人が終えた家事のうち、まだ自分がありがとうを送っていないもの**
9. 家事を指定しないで実行したときは、候補が1件ならそれに、複数ならSiriが聞き返して選ばせる。0件なら「今は、ありがとうを伝えられる家事はありません」と返す
10. コメントは任意。入れたときは今と同じ`thanksMessage`のPush通知を送り、入れなかったときは記録だけ残す（ハートのタップと同じ。[complete-list-thanks-status.md](complete-list-thanks-status.md)の要件12）
11. 実行時点でサーバーから家事を取り直し、未完了に戻されていた・すでに送っていた場合は記録しない（`HouseworkListStore.sendThanks`と同じ判定）

#### がんばりの確認

12. 要約は今月の集計で、分析画面の「今月」と同じ値（メンバーごとのポイント・割合）を出す。ほめっとのセリフは出さない
13. 分析画面を開くIntentは、ダッシュボードに切り替えてから分析画面へ遷移する

#### 共通

14. ログインしていない・グループに所属していない場合は、「hometeを開いて、ログインしてから使えます」「パートナーを招待すると使えます」のように返し、何もしない
15. 強制アップデートが必要なバージョン（最後に有効化したRemote Configの`minimum_required_version`）では、書き込み系のIntentは実行せず「アップデートしてから使えます」と返す
16. 端末がロックされているときは解除を求める（`authenticationPolicy = .requiresAuthentication`）。家事の名前や同居人の名前をロック画面に出さないため

#### App Shortcuts

17. 次の4つをApp Shortcutsとして登録する（`OpenHouseworkCompleteIntent`はショートカットAppと提案からだけ使う）

    | Intent | フレーズの例（日本語） | フレーズの例（英語） |
    |---|---|---|
    | `CompleteHouseworkIntent` | 「${applicationName}で${housework}を完了」 | "Complete ${housework} in ${applicationName}" |
    | `SendThanksIntent` | 「${applicationName}でありがとうを伝える」 | "Say thanks in ${applicationName}" |
    | `ShowContributionSummaryIntent` | 「${applicationName}で今月のがんばりを見る」 | "Show this month in ${applicationName}" |
    | `OpenContributionAnalyticsIntent` | 「${applicationName}でがんばりを分析」 | "Open analytics in ${applicationName}" |

    文言は実装時に`ux-writing.md`に沿って詰める

#### ドネーション

18. アプリの中で次の操作に**成功したとき**にドネーションする

    | 操作 | ドネーションするIntent | 引数 |
    |---|---|---|
    | 家事を1件完了にした（完了シート・クイックアクション） | `CompleteHouseworkIntent` | その家事（名前で表す） |
    | ありがとうを1件送った（ハート・詳細・感謝の促し） | `SendThanksIntent` | なし |
    | 分析画面を開いた | `ShowContributionSummaryIntent` | なし |

    - 一括操作・「もう一回やった」・コメントの編集ではドネーションしない（習慣的な操作ではなく、提案の学習を乱すため）
    - Intent経由で実行した操作はOSが自動でドネーションするため、アプリ側では重ねない（`step == .appIntent`なら送らない）
    - 同居人の完了を受けたときなど、ユーザー自身がしていない操作ではドネーションしない（OSの学習を誤らせるため）
19. ありがとうはその都度の家事を引数に入れない。家事は日ごとに別のIDなので、引数に入れると翌日の提案が終わった家事を指してしまう。実行時に候補から解決する
20. 家事の完了は**家事の名前**を引数に入れる。毎朝の「洗濯」のように、名前は日をまたいでも同じなので、翌日の同じ時間に「洗濯を完了」と提案できる

### 非機能要件 / 制約

- デプロイメントターゲットはiOS 17。iOS 17で使えるAPI（`AppIntent`・`AppEntity`・`AppShortcutsProvider`・`AppDependencyManager`・`IntentDonationManager`）で組む。iOS 18以降のAPIを使う場合は`if #available`で囲む
- 開かないIntentは、アプリのプロセスがバックグラウンドで起動して実行する（Extensionは作らない）。`AppDelegate`の`didFinishLaunching`でFirebase・App Checkの初期化が済んでから`perform`が呼ばれる前提で組む（Phase 1で確認する）
- Intentは`HouseworkListStore`を使わない。Storeはスナップショットリスナーを張るため、Intentの短い実行時間に合わない。書き込みと通知の処理はStoreとIntentで共有するUseCaseに切り出す（[ADR-0044](../adr/0044-app-intents-headless-usecase-and-title-keyed-entity.md)）
- Firestoreのセキュリティルール・Cloud Functionsは変更しない（書き込む内容はアプリからの操作と同じ）
- 文言は日本語キーで`Localizable.xcstrings`に入れ、英訳も同じ変更で入れる。App Shortcutsのフレーズはメインターゲットの`AppShortcuts.xcstrings`に置く
- Analyticsは`doc/analytics_events.md`を同じPRで更新する

## 設計方針

### 1. モジュール構成

新しいターゲット`HometeAppIntents`をLocalPackageに追加し、Intent・Entity・ドネーションのliveValueを置く。

| 置き場所 | 置くもの |
|---|---|
| `HometeDomain/AppIntent/` | Intentから使うUseCase（`AppIntentSessionUseCase`・`HouseworkCommandUseCase`など）、`IntentDonationClient`のプロトコルとpreviewValue、Intentの失敗の種類（`AppIntentFailure`） |
| `HometeAppIntents`（新規） | 各`AppIntent`・`HouseworkEntity`・`DynamicOptionsProvider`・`IntentDonationClient.liveValue`・`AppIntentsPackage` |
| `ContributionFeature` | スニペットに出すUIのみのView（`ContributionSnippetContent`）。`#Preview`を置きVRTの対象にする |
| `homete`（メインターゲット） | `AppShortcutsProvider`・`AppShortcuts.xcstrings`・`AppIntentsPackage`の宣言・`AppDependencyManager`への依存の登録 |

```
homete ──▶ HometeAppIntents ──▶ HometeDomain
   │              └────────────▶ ContributionFeature（スニペットのView・集計）
   └──▶ AppRoot / HometeInfrastructure（AppDependencies.liveValue）
```

`HometeAppIntents`は`HometeInfrastructure`に依存させない。Firebaseの実装は`homete`が`AppDependencyManager.shared.add(dependency:)`で`AppDependencies.liveValue`を渡し、Intentは`@Dependency`で受け取る。ユニットテストやPreviewでFirebaseを引き込まないため。

> Swift Package（静的ライブラリ）に置いたIntentのメタデータが抽出されるか、`AppShortcutsProvider`をパッケージに置けるかはPhase 1で確かめる。抽出されない場合は、Intent一式をメインターゲットの`homete/AppIntents/`に置き、UseCaseだけをパッケージに残す。

### 2. 書き込みをStoreとIntentで共有する（先にリファクタリング）

`HouseworkListStore.complete`・`sendThanks`は「リスナーで受け取った最新の家事を探す」処理と「書き込み・Analytics・通知」の処理が一体になっている。
後者を`HouseworkCommandUseCase`（`HometeDomain`、`Sendable`な値型）に切り出し、Storeからも呼ぶ形に変える。挙動を変えないリファクタリングとして先にコミットする。

```swift
/// 家事の完了・ありがとうの書き込みと、それに伴うAnalytics・通知
///
/// 最新の家事を探すのは呼び出し側の責務にする。Storeはリスナーで受け取った家事を、Intentはサーバーから取り直した家事を渡す。
public struct HouseworkCommandUseCase: Sendable {

    public func complete(current: HouseworkItem, now: Date, reporter: Account, ...) async throws
    @discardableResult
    public func sendThanks(current: HouseworkItem, sender: Account, comment: String?, ...) async throws -> Bool

}
```

Intentから使うときの「誰が・どのグループで」は、`AppIntentSessionUseCase`で解決する。

```swift
public struct AppIntentSessionUseCase: Sendable {

    /// ログイン中のアカウントと所属グループを取得する
    /// - Throws: 未ログインは`AppIntentFailure.notLoggedIn`、未所属は`.noCohabitant`、アップデートが必要なら`.updateRequired`
    public func resolve() async throws -> AppIntentSession

}
```

- 未ログインの判定は`AccountAuthClient.makeListener()`の最初の値で行う（Firebase Authは端末に保存したユーザーを起動直後に復元する）
- アカウントは`AccountInfoClient.fetch`、家事は`HouseworkClient.fetchItems`（今日・昨日の範囲）で1回だけ取る

### 3. 家事のEntityと候補

`HouseworkEntity`は2種類に分ける。

| Entity | ID | 使うIntent | 理由 |
|---|---|---|---|
| `HouseworkTitleEntity` | 家事の名前 | `CompleteHouseworkIntent`・`OpenHouseworkCompleteIntent` | ドネーションした提案が翌日も使えるように、日をまたいで変わらない名前で表す |
| `ThanksTargetEntity` | 家事のID | `SendThanksIntent` | 送る相手の家事を1件に決めるため。ドネーションでは引数に入れない |

- 候補（`EntityQuery.suggestedEntities`）は、取り直した家事から`HometeDomain`の値型で絞り込む
  - 完了の候補: 今日の未完了の家事の名前（重複は1つにまとめる）
  - ありがとうの候補: `ThanksPromptSummary`の判定を使う。`ThanksPromptSummary`は`HouseworkFeature/Model`にあるため、判定部分を`HometeDomain`に移すか、Intentから`HouseworkFeature`に依存するかをPhase 1で決める
- `EntityStringQuery`を実装し、Siriで言った名前から探せるようにする

### 4. アプリを開くIntentの画面遷移

通知のタップで画面を開く仕組み（`PendingNotificationRouteStore`）を、Intentからも使えるように広げる。

1. （リファクタリング）`NotificationRoute` → `PendingRoute`、`PendingNotificationRouteStore` → `PendingRouteStore`にリネームする
2. `PendingRoute`にケースを足す

   ```swift
   public enum PendingRoute: Equatable, Sendable {
       /// 家事の詳細画面（通知のタップ）
       case houseworkDetail(houseworkId: String)
       /// 家事の完了シート（App Intent）
       case houseworkComplete(houseworkTitle: String)
       /// がんばりの分析画面（App Intent）
       case contributionAnalytics
   }
   ```

3. `homete`で`AppDelegate.pendingRouteStore`を`AppDependencyManager`に登録し、開くIntent（`openAppWhenRun = true`）が`@MainActor`で`store(_:)`する
4. `AppTabView.onChangePendingNotificationRoute`でタブを切り替え、切り替え先（家事ボード・ダッシュボード）が読み込みを待って画面を開く。家事の解決は`takeHouseworkDetailItem`と同じく、読み込み中なら待ち、読み込み後に見つからなければ破棄する

### 5. がんばりのスニペット

- `ShowContributionSummaryIntent.perform`で今月の家事を`fetchItems`し、分析画面と同じ集計（`HouseworkContribution`・`AllUserPointSummary`）で値を作る
- 表示は`ContributionFeature`の`ContributionSnippetContent`（UIのみ、`#Preview`でVRTの対象）に渡し、`.result(dialog:view:)`で返す
- スニペットからアプリを開く導線は、iOS 17ではスニペットのタップ（OS標準の挙動）に任せる。足りなければ`OpenContributionAnalyticsIntent`を案内するダイアログにする

### 6. ドネーション

`HometeDomain`に`IntentDonationClient`を置き、liveValueは`HometeAppIntents`で`IntentDonationManager`（またはIntentの`donate()`）を呼ぶ。`HometeDomain`はApp Intentsフレームワークに依存させない。

```swift
public struct IntentDonationClient: DependencyClient {
    public let donateCompleteHousework: @Sendable (_ houseworkTitle: String) -> Void
    public let donateSendThanks: @Sendable () -> Void
    public let donateContributionSummary: @Sendable () -> Void
}
```

- 家事の完了・ありがとうは`HouseworkCommandUseCase`の成功後に、`step != .appIntent`かつ単発操作のときだけ呼ぶ
- 分析画面は`ContributionAnalyticsScreen`の表示時に呼ぶ

### 7. Analytics

- 家事の完了・ありがとうは既存の`housework`イベントを使い、`step`に`app_intent`を足す（`HouseworkAnalyticsStep.appIntent`）
- Intentの実行そのものを数える`app_intent`イベントを追加する。パラメータは`intent`（`complete_housework` / `open_housework_complete` / `send_thanks` / `show_contribution_summary` / `open_contribution_analytics`）と`is_success`
  - 家事の完了・ありがとうは`housework`イベントと二重に送るが、見たいものが違う（`housework`は操作の量、`app_intent`はアプリの外の入口の使われ方）
- 開くIntentで表示した画面の`screen_view`は既存どおり送られる

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ターゲット | `LocalPackage/Package.swift` | `HometeAppIntents`を追加 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/AppIntent/AppIntentSessionUseCase.swift` | ログイン中のアカウント・グループの解決 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/AppIntent/AppIntentFailure.swift` | Intentの失敗の種類 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkCommandUseCase.swift` | 完了・ありがとうの書き込み（Storeから切り出し） |
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/IntentDonationClient.swift` | ドネーションのプロトコルとpreviewValue |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | `HouseworkCommandUseCase`を呼ぶ形に変更・ドネーション |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/NotificationRoute/` | `PendingRoute`へのリネームとケース追加 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/AnalyticsLog/` | `HouseworkAnalyticsStep.appIntent`・`app_intent`イベント |
| 修正DI | `LocalPackage/Sources/HometeDomain/Dependencies/AppDependencies.swift` | `intentDonationClient`の追加 |
| 新規Intent | `LocalPackage/Sources/HometeAppIntents/` | 5つのIntent・2つのEntity・候補・ドネーションのliveValue |
| 新規View | `LocalPackage/Sources/Features/ContributionFeature/View/Snippet/ContributionSnippetContent.swift` | スニペットのUI |
| 修正View | `LocalPackage/Sources/AppRoot/AppTabView.swift` | 新しい`PendingRoute`でのタブ切り替え |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/HouseworkBoardScreen.swift` | 完了シートを開く |
| 修正View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/RegisteredContent.swift` | 分析画面へ遷移 |
| 修正View | `LocalPackage/Sources/Features/ContributionFeature/View/Analytics/ContributionAnalyticsScreen.swift` | 表示時のドネーション |
| 新規 | `homete/AppIntents/HometeAppShortcuts.swift` | `AppShortcutsProvider` |
| 新規 | `homete/Resouces/AppShortcuts.xcstrings` | フレーズの日英 |
| 修正 | `homete/Views/HometeApp.swift` | `AppDependencyManager`への登録 |
| ドキュメント | `doc/analytics_events.md`・`doc/multimodules_structure.md`・`CLAUDE.md` | イベント・モジュール・エントリーポイントの追記 |

## タスク

### Phase 1: 設計確定

- [x] 完了は「開かない」「開く」の両方を用意する
- [x] ありがとうは開かずに送り、コメントは任意
- [x] がんばりは「スニペット」「分析画面を開く」の両方を用意する
- [x] 入口はApp Shortcutsとドネーション（ウィジェット・コントロールセンターは対象外）
- [ ] Swift Packageに置いたIntentのメタデータが抽出され、ショートカットAppに出ることを確かめる（だめならメインターゲットに置く）
- [ ] バックグラウンドで起動したときに、Firebase Auth・App Check（App Attest）・Firestoreの読み書きが通ることを実機で確かめる
- [ ] `ThanksPromptSummary`の判定を`HometeDomain`へ移すか決める
- [x] Issueを起票する（#434）

### Phase 2: 実装

- [ ] （refactor）`HouseworkCommandUseCase`を切り出し、`HouseworkListStore`から呼ぶ
- [ ] （refactor）`NotificationRoute`・`PendingNotificationRouteStore`を`PendingRoute`・`PendingRouteStore`にリネーム
- [ ] `AppIntentSessionUseCase`・`AppIntentFailure`を追加
- [ ] `HometeAppIntents`ターゲットを追加し、2つのEntityと候補を実装
- [ ] `CompleteHouseworkIntent`・`SendThanksIntent`を実装
- [ ] `OpenHouseworkCompleteIntent`・`OpenContributionAnalyticsIntent`と、`PendingRoute`からの画面遷移を実装
- [ ] `ContributionSnippetContent`（Previewつき）と`ShowContributionSummaryIntent`を実装
- [ ] `IntentDonationClient`とドネーションの呼び出しを実装
- [ ] `HometeAppShortcuts`とフレーズ（日英）を追加
- [ ] Analytics（`app_intent`イベント・`step=app_intent`）を追加
- [ ] 文言の英訳を入れ、`make check-translations`を通す
- [ ] `doc/analytics_events.md`・`doc/multimodules_structure.md`・`CLAUDE.md`を更新

### Phase 3: 検証

- [ ] `swift build` でビルド通過
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] ユニットテスト実行（追加分含む）通過
  - `AppIntentSessionUseCase`: 未ログイン・未所属・アップデートが必要・正常
  - `HouseworkCommandUseCase`: 既存の`HouseworkListStore`のテストが通ったまま
  - 完了の候補と解決: 同じ名前が複数・すでに完了・見つからない
  - ありがとうの候補と解決: 0件・1件・複数、未完了に戻された、送信済み、コメントの有無で通知が変わる
  - ドネーション: 単発操作だけ・`step == .appIntent`では送らない
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] 実機でSiri・Spotlight・ショートカットAppから5つのIntentを動かす（アプリ終了時・ロック時を含む）

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 今回のスコープ外（今後の候補）

- インタラクティブウィジェット・コントロールセンターのコントロール（同じIntentを再利用できる）
- `RelevantIntentManager`でスマートスタックに出す（同居人の完了を受けたときに「ありがとう」を出すなど）
- Apple Intelligenceのアプリ内アクション連携

## 関連リンク

- 既存実装（参考）:
  - `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift`（`complete` / `sendThanks` / `completeBulk`）
  - `LocalPackage/Sources/HometeDomain/NotificationRoute/PendingNotificationRouteStore.swift`
  - `LocalPackage/Sources/Features/HouseworkFeature/Model/ThanksPromptSummary.swift`
  - `LocalPackage/Sources/Features/ContributionFeature/Model/ContributionStore.swift`
  - `homete/Views/HometeApp.swift`
