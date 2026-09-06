# Analytics（GA4）イベント設計

> イベント名を行動ごとに増やさない方針を採用した背景は [ADR-0009](adr/0009-analytics-event-parameter-design.md) を参照。

Firebase Analytics（GA4）へ送信するイベントの一覧と、送信タイミング・パラメータの定義。
**イベントを追加・変更する場合は、実装と合わせて必ずこのドキュメントを更新すること。**

## 実装の場所

| 役割 | ファイル |
|---|---|
| イベントの定義（name / parameters の組み立て） | `LocalPackage/Sources/HometeDomain/AnalyticsLog/AnalyticsEvent.swift` |
| 機能単位のパラメータ設計 | `LocalPackage/Sources/HometeDomain/AnalyticsLog/<機能名>AnalyticsAction.swift` |
| 送信インターフェース | `AnalyticsClient`（`liveValue`は`HometeInfrastructure`） |
| 画面表示の送信 | `AppScreen`、`View.trackScreenView(_:)`（`HometeUI`） |

送信は必ず `AnalyticsEvent` のstaticファクトリ経由で行う。Viewやストアが `AnalyticsEvent(name:parameters:)` を直接呼ぶと、
このドキュメントとの対応が追えなくなるため禁止。

## 命名ポリシー

1. **イベント名は「機能・文脈」の単位で作る。** ユーザーの個別の行動ごとに名前を増やさない
   （GA4はプロパティごとに定義できるイベント名の数に上限があり、使い切ると新しい計測ができなくなる）
2. **どの行動かはパラメータで区別する。** 画面を `step`、操作を `action`、結果を `result` で表す
3. **イベント名は`snake_case`**。パラメータ値も`snake_case`
4. **`result` は真偽値の文字列にしない。** GAのレポート上でそのまま意味が読める語（`granted` / `denied` など）にする
5. パラメータのキーは機能をまたいで使い回す。GA4のカスタムディメンションにも登録数の上限があるため、
   `isGranted` / `isPremium` のように行動ごとのキーを増やさない

## ユーザープロパティ

「プレミアム会員かどうか」のようにユーザーに紐づき、かつ複数のイベントを横断して分析したい軸は、
イベントパラメータではなくユーザープロパティとして送る。各イベントのパラメータに持たせると送信箇所ごとに
付け忘れが起きる上、GA4のカスタムディメンションの登録数を無駄に消費するため。

| 実装 |
|---|
| `AnalyticsUserProperty`（`HometeDomain/AnalyticsLog/`）、`AnalyticsClient.setUserProperty` |

| プロパティ名 | 値 | 説明 | 設定タイミング |
|---|---|---|---|
| `is_premium` | `true` / `false` | プレミアム会員かどうか | `SubscriptionStore`のエンタイトルメント状態が変化したとき（ログイン後の取得・購読更新・復元・ログアウト） |
| `has_cohabitant` | `true` / `false` | 同居人グループに参加済みかどうか | `LoginContext`が確定したとき（`RootView`でログイン状態が決まるたび） |
| `cohabitant_member_count` | 数値の文字列 | 同居人グループのメンバー数（自分を含む） | `CohabitantStore`がグループのスナップショットを受信し、メンバー一覧を更新したとき |

**分析での使い方:** `is_premium`でセグメントして`housework` / `housework_template`の利用頻度を比較すると、
プレミアム機能が実際にどれだけ使われているかが分かる。`has_cohabitant`が`false`のユーザーは家事管理自体が
成立していないため、他の指標から除外して見る必要がある。

## イベント一覧

### `screen_view`

画面の表示。GA4の予約イベント名・予約パラメータのため、イベント名の登録上限を消費せず、標準レポート（「画面とビュー」）にそのまま載る。

| 項目 | 内容 |
|---|---|
| 送信タイミング | 対象画面が表示された（`onAppear`）とき。前面に別画面を出して戻ってきた場合も再度送信される |
| 実装 | `AppScreen`、`HometeUI`の`View.trackScreenView(_:)`を各画面のルートViewに付与 |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `screen_name` | ○ | 下表の`screen_name` | 表示された画面 |

Firebase Analyticsの自動収集`screen_view`は`UIViewController`単位で動作するため、SwiftUIのみで構成している本アプリでは画面遷移が記録されない。そのため自動収集に頼らず、全画面から手動で送信する。

| `screen_name` | 実装View |
|---|---|
| `launch` | `LaunchScreenView` |
| `login` | `LoginView` |
| `registration_account` | `RegistrationAccountView` |
| `onboarding_premium_introduction` | `PremiumIntroductionView` |
| `onboarding_notification_permission` | `OnboardingNotificationPermissionGuideView` |
| `paywall` | `PaywallScreen`（`RouteResolverInjection`で付与） |
| `dashboard` | `RegisteredContent` |
| `dashboard_not_registered` | `NotRegisteredContent` |
| `cohabitant_registration` | `CohabitantRegistrationView` |
| `cohabitant_join` | `CohabitantJoinView` |
| `cohabitant_completion` | `CohabitantCompletionView` |
| `incomplete_housework_list` | `IncompleteHouseworkListView` |
| `contribution_analytics` | `ContributionAnalyticsView` |
| `housework_board` | `HouseworkBoardView` |
| `housework_detail` | `HouseworkDetailView` |
| `housework_register` | `RegisterHouseworkView` |
| `housework_approval` | `HouseworkApprovalView` |
| `housework_template` | `HouseworkTemplateView` |
| `housework_template_detail` | `HouseworkTemplateItemDetailView` |
| `housework_template_edit` | `HouseworkTemplateItemEditModal` |
| `setting` | `SettingView` |
| `subscription_management` | `SubscriptionManagementView` |
| `setting_notification_permission` | `SettingNotificationPermissionGuideView` |
| `license_list` | `LicenseListView` |
| `license_detail` | `LicenseDetailView` |

`#if DEBUG`でのみ存在するデバッグ画面（`DebugMenuView` / `DebugOnboardingScreen`）は対象外。
`CohabitantRegistrationView`の内部状態（スキャン中 / 端末一覧 / 処理中）は画面として分けず、`cohabitant_invitation`など機能ごとのイベントの`action`で区別する。

**分析での使い方:** 画面ごとの表示回数と、画面間の遷移で離脱率が分かる。とくに`dashboard_not_registered`は
同居人グループ未登録のまま離脱しているユーザーの規模を示すため、`cohabitant_registration`への到達率と合わせて見る。

### `login`

| 項目 | 内容 |
|---|---|
| 送信タイミング | Sign in with Apple による認証処理が完了したとき（成功・失敗とも） |
| 実装 | `AccountAuthStore` |

| パラメータ | 値 | 説明 |
|---|---|---|
| `result` | `success` / `failure` | 認証に成功したかどうか |

### `logout`

| 項目 | 内容 |
|---|---|
| 送信タイミング | ユーザーがログアウトを実行したとき |
| 実装 | `AccountAuthStore` |
| パラメータ | なし |

### `delete_account`

| 項目 | 内容 |
|---|---|
| 送信タイミング | ユーザーがアカウント削除を実行したとき |
| 実装 | `AccountAuthStore` |
| パラメータ | なし |

### `onboarding`

アカウント登録直後のオンボーディングの特典説明における行動。

| 項目 | 内容 |
|---|---|
| 実装 | `OnboardingAnalyticsAction`、`PremiumIntroductionView` |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `step` | ○ | `premium_introduction` | どの画面での行動か（現状は特典説明画面のみ） |
| `action` | ○ | `shown` / `paywall_shown` / `paywall_closed` / `skipped` | 何が起きたか |
| `result` | — | `purchased` / `not_purchased` | 結果を伴う行動のみ付与 |

送信されるパターンと、その送信タイミング:

| `step` | `action` | `result` | 送信タイミング |
|---|---|---|---|
| `premium_introduction` | `shown` | — | 特典説明画面が表示された |
| `premium_introduction` | `paywall_shown` | — | 特典説明画面で「プランを見る」をタップしてPaywallを開いた |
| `premium_introduction` | `paywall_closed` | `purchased` / `not_purchased` | Paywallを閉じた（閉じた時点でプレミアムが有効なら`purchased`） |
| `premium_introduction` | `skipped` | — | 「あとで決める」でPaywallを開かずに次へ進んだ |

**分析での使い方:** `premium_introduction / shown` を分母に `paywall_shown` → `paywall_closed(purchased)` を追うと、
オンボーディング経由の課金ファネルになる。

> 通知権限の案内（オンボーディング・設定画面の両方）は`notification_permission`イベントに分離した。
> 以前はこのイベントの`step: notification_permission`として計測していた。

### `housework`

家事の登録・完了報告・承認・却下・差し戻し・削除における行動。すべて`HouseworkListStore`に送信箇所を集約する。

| 項目 | 内容 |
|---|---|
| 実装 | `HouseworkAnalyticsAction`、`HouseworkListStore` |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `action` | ○ | `register` / `request_review` / `approve` / `reject` / `return_incomplete` / `delete` | 何が起きたか |
| `step` | — | `dashboard` / `board` / `detail` / `approval` | 起点画面 |
| `result` | — | `success` / `failure` | 行動の結果 |

送信されるパターンと、その送信タイミング:

| `action` | `step` | 送信タイミング |
|---|---|---|
| `register` | `dashboard` / `board` | 「家事を追加」から新規の家事を登録した（起点はダッシュボード・家事ボードのどちらもありうる） |
| `request_review` | `dashboard` / `board` / `detail` | 家事の確認依頼を行った（ダッシュボード・家事ボードのクイックアクション、または家事詳細の「確認してもらう」） |
| `approve` | `approval`（固定） | 家事の承認画面で「完了にする」をタップした |
| `reject` | `approval`（固定） | 家事の承認画面で「再確認してもらう」をタップした |
| `return_incomplete` | `dashboard` / `board` / `detail` | 家事を未完了に戻した |
| `delete` | `dashboard` / `board` / `detail` | 家事を「やらない」にした |

いずれも`result`に`success` / `failure`が付与される（Firestoreへの書き込み結果）。

**分析での使い方:** `register`の起点画面比率でダッシュボードと家事ボードのどちらが主な追加導線かが分かる。
`request_review` → `approve` / `reject`の比率は、承認フローがスムーズに回っているかの指標になる。

### `housework_template`

家事テンプレート（プレミアム機能）の作成・編集・削除における行動。

| 項目 | 内容 |
|---|---|
| 実装 | `HouseworkTemplateAnalyticsAction`、`HouseworkTemplateListStore` |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `action` | ○ | `apply` / `create` / `edit` / `delete` | 何が起きたか |
| `result` | ○ | `success` / `failure` | 行動の結果 |

送信されるパターンと、その送信タイミング:

| `action` | 送信タイミング |
|---|---|
| `apply` | テンプレートを初めて作成した（テンプレート機能自体の利用開始） |
| `create` | 「保存」時に、編集画面のドラフトと保存前の内容を比較して新規追加されたテンプレート家事があった（家事1件につき1イベント） |
| `edit` | 「保存」時に、内容（タイトル・ポイント・登録曜日）が変更されたテンプレート家事があった（家事1件につき1イベント） |
| `delete` | 「保存」時に、削除されたテンプレート家事があった（家事1件につき1イベント） |

`create` / `edit` / `delete`はテンプレート編集画面のローカルなドラフト操作ではなく、「保存」ボタンで実際にFirestoreへ
書き込むタイミングでまとめて送信する（ドラフト編集自体はネットワーク操作を伴わないため）。

**分析での使い方:** `apply`を分母にテンプレート機能の利用開始率、`create` / `edit` / `delete`の件数比率で
テンプレートがどの程度使い込まれているか（作りっぱなしか、継続的に編集されているか）が分かる。

### `cohabitant_registration`

同居人グループを新規作成するフローそのものの進捗（近接通信 / 招待リンクの両方法を横断）。
既存の`cohabitant_invitation`は招待リンクの発行・参加を担当するため、こちらはグループ作成フロー全体の
進捗（離脱ポイントの特定）を担当する。

| 項目 | 内容 |
|---|---|
| 実装 | `CohabitantRegistrationAnalyticsAction`、`CohabitantRegistrationView` / `CohabitantRegistrationScanningStateView` / `CohabitantRegistrationProcessingLeader` / `CohabitantJoinStore` |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `method` | ○ | `p2p` / `link` | 近接通信 / 招待リンクのどちらの方法か |
| `action` | ○ | `started` / `peer_found` / `completed` | フローの進捗 |
| `result` | — | `success` / `failure` | `completed`のみ付与 |

送信されるパターンと、その送信タイミング:

| `method` | `action` | `result` | 送信タイミング |
|---|---|---|---|
| `p2p` | `started` | — | 同居人登録画面（`CohabitantRegistrationView`）が表示された |
| `p2p` | `peer_found` | — | 近接通信で相手を発見した |
| `p2p` | `completed` | `success` / `failure` | グループの作成が完了した／登録処理中にエラーが発生した |
| `link` | `started` | — | 招待リンクの参加画面で「参加する」をタップした |
| `link` | `completed` | `success` / `failure` | グループへの参加が完了した／失敗した |

**分析での使い方:** `p2p / started` → `peer_found` → `completed(success)`の各段階の減衰を見ると、
近接通信によるグループ作成のどこで離脱しているかが分かる。グループが作れないとアプリが使えないため、
最大の離脱ポイントを特定する目的で追加した。

### `notification_permission`

プッシュ通知の権限リクエストにおける行動。オンボーディング・設定画面の両方の導線を同じイベントで計測する。

| 項目 | 内容 |
|---|---|
| 実装 | `NotificationPermissionAnalyticsAction`、`OnboardingNotificationPermissionGuideView` / `SettingNotificationPermissionGuideView` |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `step` | ○ | `onboarding` / `setting` | どの画面からの案内か |
| `action` | ○ | `permission_requested` / `skipped` | 何が起きたか |
| `result` | — | `granted` / `denied` | 権限の可否を伴う場合のみ付与 |

送信されるパターンと、その送信タイミング:

| `step` | `action` | `result` | 送信タイミング |
|---|---|---|---|
| `onboarding` | `permission_requested` | `granted` / `denied` | オンボーディングで「通知を受け取る」をタップして権限をリクエストした |
| `onboarding` | `skipped` | — | オンボーディングで「あとで設定する」をタップした |
| `setting` | `permission_requested` | `granted` / `denied` | 設定画面で未決定の状態から「通知を受け取る」をタップして権限をリクエストした |
| `setting` | `permission_requested` | — | 設定画面で、権限の可否がすでに決まっており設定Appへ遷移した（可否の結果を伴わない） |
| `setting` | `skipped` | — | 設定画面で「あとで設定する」をタップした |

**分析での使い方:** `step`で分けて`permission_requested(granted)`の比率を比べると、オンボーディングと設定画面の
どちらの案内がオプトイン率が高いかが分かる。

### `cohabitant_invitation`

招待リンク（Universal Link）による同居人グループの招待・参加における行動。

| 項目 | 内容 |
|---|---|
| 実装 | `CohabitantInvitationAnalyticsAction`、`CohabitantRegistrationScanningStateView` / `SettingView` / `RootView` / `CohabitantJoinStore` |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `action` | ○ | `issue` / `open` / `join` | 招待リンクの発行 / 起動 / 参加のどれか |
| `step` | — | `cohabitant_registration` / `setting` | 発行を開始した画面。画面を起点とする`issue`のみ付与 |
| `result` | — | `success` / `failure` / `invalid_link` / `expired` / `already_joined` | 結果を伴う行動のみ付与 |

送信されるパターンと、その送信タイミング:

| `action` | `step` | `result` | 送信タイミング |
|---|---|---|---|
| `issue` | `cohabitant_registration` | `success` / `failure` | 同居人登録画面の「リンクで招待」をタップし、招待トークンの発行が完了した |
| `issue` | `setting` | `success` / `failure` | 設定画面の「メンバー招待」をタップし、招待トークンの発行が完了した |
| `open` | — | — | 招待リンクからアプリが起動した（ログイン前も含む） |
| `join` | — | `success` | 招待リンクからグループへの参加が完了した |
| `join` | — | `invalid_link` / `expired` / `already_joined` / `failure` | 参加に失敗した（無効なリンク / 期限切れ / 別グループに参加済み / それ以外） |

**分析での使い方:** `issue(success)` を分母に `open` → `join(success)` を追うと招待リンクの成立率になる。
`step` で分けると、同居人登録画面と設定画面のどちらが招待の起点として機能しているかが分かる。
`join` の失敗内訳を見ると、有効期限（24時間）が短すぎないか、別グループ参加済みのユーザーがどの程度リンクを踏んでいるかが分かる。

### `advertisement`

広告に関する行動。現状は無料プランに表示している「広告を非表示にする」リンクのタップのみを計測する
（広告そのものの表示・クリックはAdMob側の計測に任せる。アプリ内の課金導線への反応はAdMobでは取得できないため
この位置で計測する）。

| 項目 | 内容 |
|---|---|
| 実装 | `AdvertisementAnalyticsStep`、`RegisteredContent` / `HouseworkTemplateScreen` / `ContributionAnalyticsScreen` |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `action` | ○ | `remove_ads_link_tapped` | 「広告を非表示にする」リンクのタップ（現状はこの1種類のみ） |
| `step` | ○ | `dashboard` / `board` / `template` | 広告の掲載面 |

送信されるパターンと、その送信タイミング:

| `step` | 送信タイミング |
|---|---|
| `dashboard` | ダッシュボード上部の広告バナー下のリンクをタップした |
| `board` | 家事分析画面下部の広告バナー下のリンクをタップした |
| `template` | 家事テンプレート画面下部の広告バナー下のリンクをタップした |

いずれもタップ後にPaywallを開く。`ContributionAnalyticsView`には保存期間の上限に達した際の
別のアップグレード導線（`StoragePeriodLimitView`）もあるが、そちらは広告面ではないため別のコールバック
（`onUpgradeTapped`）として扱い、このイベントには含めない。

**分析での使い方:** `step`ごとのタップ数を比較すると、どの掲載面の広告が最もPaywallへの導線として機能しているかが分かる。
`paywall_shown`（画面表示）や課金完了と合わせて見ると、掲載面ごとの課金転換率が分かる。

### `subscription`

契約中プランの管理（購入の復元・OSのサブスクリプション管理画面の起動）における行動。

| 項目 | 内容 |
|---|---|
| 実装 | `SubscriptionAnalyticsAction`、`SubscriptionStore` |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `action` | ○ | `restore` / `manage_opened` | 購入の復元 / サブスクリプション管理画面の起動のどちらか |
| `result` | ○ | `success` / `failure` | 行動の結果 |

送信されるパターンと、その送信タイミング:

| `action` | `result` | 送信タイミング |
|---|---|---|
| `restore` | `success` / `failure` | サブスクリプション管理画面の「購入を復元」をタップし、復元処理が完了した／エラーが発生した（有効なエンタイトルメントが見つからなかった場合も、API呼び出し自体は成功のため`success`） |
| `manage_opened` | `success` / `failure` | サブスクリプション管理画面の「解約する」/「サブスクリプションを管理」をタップし、OSの管理画面を起動できた／起動に失敗した |

**分析での使い方:** `restore`の失敗率が高い場合、購入の復元まわりのサポート問い合わせが増える兆候として検知できる。
`manage_opened`の起動失敗は、解約したいユーザーがOSの管理画面に辿り着けていないことを示すため、優先度高く見る。

## イベントを追加するときの手順

1. 既存イベントの**パラメータで表現できないか**をまず検討する。同じ文脈の行動なら既存イベントに`action`の値を足す
2. 新しい文脈であれば `AnalyticsEvent` にstaticファクトリを追加する。行動が複数あるなら
   `<機能名>AnalyticsAction` enumを作り、パラメータ生成をそちらに寄せる
3. `LocalPackage/Tests/HometeDomainTests/AnalyticsEventTest.swift` にケースを追加する
4. **このドキュメントの「イベント一覧」に追記する**

画面を追加した場合は、`AppScreen`にケースを足して対象のViewに`trackScreenView(_:)`を付け、上記`screen_view`の画面一覧にも追記する。
