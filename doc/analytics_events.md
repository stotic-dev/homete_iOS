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

## イベント一覧

### `login`

| 項目 | 内容 |
|---|---|
| 送信タイミング | Sign in with Apple による認証処理が完了したとき（成功・失敗とも） |
| 実装 | `AccountAuthStore` |

| パラメータ | 値 | 説明 |
|---|---|---|
| `isSuccess` | `true` / `false` | 認証に成功したかどうか |

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

アカウント登録直後のオンボーディング（特典説明 → 通知権限）における行動。

| 項目 | 内容 |
|---|---|
| 実装 | `OnboardingAnalyticsAction`、`PremiumIntroductionView` / `NotificationPermissionGuideView` |

| パラメータ | 必須 | 値 | 説明 |
|---|---|---|---|
| `step` | ○ | `premium_introduction` / `notification_permission` | どの画面での行動か |
| `action` | ○ | `shown` / `paywall_shown` / `paywall_closed` / `skipped` / `permission_requested` | 何が起きたか |
| `result` | — | `purchased` / `not_purchased` / `granted` / `denied` | 結果を伴う行動のみ付与 |

送信されるパターンと、その送信タイミング:

| `step` | `action` | `result` | 送信タイミング |
|---|---|---|---|
| `premium_introduction` | `shown` | — | 特典説明画面が表示された |
| `premium_introduction` | `paywall_shown` | — | 特典説明画面で「プランを見る」をタップしてPaywallを開いた |
| `premium_introduction` | `paywall_closed` | `purchased` / `not_purchased` | Paywallを閉じた（閉じた時点でプレミアムが有効なら`purchased`） |
| `premium_introduction` | `skipped` | — | 「あとで決める」でPaywallを開かずに次へ進んだ |
| `notification_permission` | `permission_requested` | `granted` / `denied` | 「通知を受け取る」をタップして権限をリクエストした |
| `notification_permission` | `skipped` | — | 「あとで設定する」で権限をリクエストせずに進んだ |

**分析での使い方:** `premium_introduction / shown` を分母に `paywall_shown` → `paywall_closed(purchased)` を追うと、
オンボーディング経由の課金ファネルになる。`notification_permission` は `permission_requested(granted)` と
`skipped` / `permission_requested(denied)` の比率が通知のオプトイン率になる。

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

## イベントを追加するときの手順

1. 既存イベントの**パラメータで表現できないか**をまず検討する。同じ文脈の行動なら既存イベントに`action`の値を足す
2. 新しい文脈であれば `AnalyticsEvent` にstaticファクトリを追加する。行動が複数あるなら
   `<機能名>AnalyticsAction` enumを作り、パラメータ生成をそちらに寄せる
3. `LocalPackage/Tests/HometeDomainTests/AnalyticsEventTest.swift` にケースを追加する
4. **このドキュメントの「イベント一覧」に追記する**
