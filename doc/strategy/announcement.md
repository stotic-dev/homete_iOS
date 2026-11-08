# 運営からのお知らせ 実装方針

> 関連Issue: [#533 [backend] API変更への対応: feat: 運営からのお知らせのAPIと予約したPush通知の送信](https://github.com/stotic-dev/homete_iOS/issues/533)
> ブランチ: `feat/533-announcement`
> API仕様: [homete_backend docs/api.md「お知らせ（ユーザー向け）」](https://github.com/stotic-dev/homete_backend/blob/3165fec0bc74714891f16597e3c98ae2f84e1814/docs/api.md)（[homete_backend#23](https://github.com/stotic-dev/homete_backend/pull/23)）

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

運営が管理画面から配信するお知らせを、アプリで読めるようにする。ダッシュボードのベルから一覧・詳細を開け、未読の数をバッジで出す。
大事なお知らせは起動時にシートで出し、通知ありで公開されたものはPush通知で届ける。お知らせの通知だけを止める設定も用意する。

## 要件

### 機能要件

1. **ダッシュボードのベル**
   - ダッシュボードのナビゲーションバーに、設定ボタンと並べてベルのボタンを置く（グループ登録済み・未登録のどちらの状態でも出す）
   - `unreadCount`が1以上ならベルにバッジ（件数）を出す
   - タップでお知らせ一覧をシートで開く
2. **お知らせ一覧**
   - `listannouncements`の`announcements`を`publishedAt`の新しい順に並べる（最大50件。ページングは無い）
   - 行にはタイトル・公開日・未読のドットを出す
   - 一覧を開いて取得できたら、先頭（最新）のお知らせを`markannouncementsread(scope: "list")`で既読にする。未読の数は0、モーダルも出さない状態にする
   - 行の未読のドットは、開いたときに取得した`isUnread`のまま出す（開いた瞬間に消えると、どれが新しいか分からなくなるため）。詳細を開いたもの、次に取り直したときに既読になっているものは消す
   - 0件のときは、お知らせが無いことを伝える空状態を出す
   - 取得に失敗したら、再読み込みのボタン付きのエラー表示を出す
   - 引っ張って更新できる
3. **お知らせ詳細**
   - 一覧の行をタップするとpush遷移で開く
   - タイトル・公開日・本文（プレーンテキスト。HTML・Markdownとして解釈しない）を出す
   - `linkUrl`があれば「詳しく見る」ボタンを出し、外部ブラウザ（`openURL`）で開く
4. **起動時のモーダル**
   - `modalAnnouncementId`が返ったら、そのお知らせをシートで出す（タイトル・公開日・スクロールできる本文・`linkUrl`があれば「詳しく見る」・「閉じる」）
   - 出すお知らせは、起動後（`AppTabView`を出してから）初めて取得できたときの1回だけ決める。フォアグラウンドへの復帰や通知の受信で取り直しても、新しくシートは出さない（ダッシュボードの中で家事の登録など別のシートを開いている最中に、シートを重ねて出そうとして止まるのを避けるため）
   - シートを閉じたら（「閉じる」・×・下スワイプのいずれでも）`markannouncementsread(scope: "modal")`で既読にする。一覧の未読は残る
   - ダッシュボードの上に別のシート・フルスクリーンカバー（パートナー登録・Apple連携・設定・招待の共有・お知らせ一覧）やチュートリアルを出している間は出さず、閉じてから出す
5. **取得のタイミング**
   - ログイン後のメイン画面（`AppTabView`）を出したとき・フォアグラウンドに戻ったとき・お知らせのPush通知をフォアグラウンドで受け取ったときに`listannouncements`を呼び直す
6. **Push通知**
   - 起動時にFCMトピック`announcements`を購読する（端末単位。ログイン状態に関わらない）。お知らせの通知を止めている場合は購読をやめる
   - フォアグラウンドで受け取ったときは、他の通知と同じくバナーを出し、お知らせを取り直す
   - タップされたら（`data.type == "announcement"`）お知らせ一覧を開く。通知の`announcementId`の詳細は開かない（取り下げ・バージョン対象外で一覧に無いことがあるため。API仕様の「その場合は一覧を開く」に合わせ、常に一覧を開く）
7. **お知らせの通知の設定**
   - 設定 → 通知設定に「お知らせ」のトグルを足す（既定はオン）
   - オフにしたらトピックの購読をやめ、オンにしたら購読し直す
   - 端末ごとの設定として`UserDefaults`に保存する（トピックの購読が端末単位のため）

### 非機能要件 / 制約

- お知らせのAPIは匿名ユーザーも呼べる。ログイン後（`loggedIn`）のメイン画面でだけ使い、ログイン前の説明画面・登録画面・Apple連携の画面では呼ばない
- メンテナンス中・強制アップデート中は`RootView`が画面ごと差し替えるため、お知らせも出ない（追加の対応は要らない）
- `appVersion`は`CFBundleShortVersionString`をそのまま送る（問い合わせの`appVersion`はビルド番号付きなので流用しない）
- お知らせのエラーは`details.announcementErrorCode`で判別する（問い合わせと同じく、関数の未デプロイ時の`not-found`と区別するため）。既読の失敗（`announcement-not-found`・通信エラー）は画面に出さず、次の取得に任せる
- 配信済みのアプリには影響しない（新しいAPIを呼ぶだけで、既存のAPIは変わっていない）
- 通知はNotification Service Extensionを通らない（`mutable-content`が付かない）ため、NSEの変更は要らない

## 設計方針

### 1. ドメインモデル（`HometeModel`）

UIが使う値型なので`HometeModel`に置く。

```swift
// LocalPackage/Sources/HometeModel/Announcement/Announcement.swift
public struct Announcement: Equatable, Sendable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let body: String
    public let linkUrl: URL?
    public let publishedAt: Date
    public let updatedAt: Date
    public let isUnread: Bool
}
```

### 2. Client（`HometeDomain/Dependencies/`）

```swift
// AnnouncementClient.swift
public struct AnnouncementClient: Sendable {
    /// 配信中のお知らせを取得する。取得だけでは既読にならない
    public let list: @Sendable () async throws -> AnnouncementList
    /// 表示したお知らせまでを既読にする
    public let markRead: @Sendable (_ announcementId: String, _ scope: AnnouncementReadScope) async throws -> Void
}

// AnnouncementTopicClient.swift（お知らせのPush通知の購読）
public struct AnnouncementTopicClient: Sendable {
    public let loadIsEnabled: @Sendable () async -> Bool   // 未設定はtrue
    public let saveIsEnabled: @Sendable (Bool) async -> Void
    public let subscribe: @Sendable () async -> Void
    public let unsubscribe: @Sendable () async -> Void
}
```

- `AnnouncementList`: `announcements` / `unreadCount` / `modalAnnouncementId`
- `AnnouncementReadScope`: `list` / `modal`（`HometeDomain/Announcement/`）
- `AnnouncementError`: `invalidArgument` / `notFound`（`InquiryError`と同じ形で`serverCodeKey = "announcementErrorCode"`）
- `liveValue`
  - `AnnouncementClient`: `InfraPackage/Sources/AppRoot/Dependency/Impl/ImplAnnouncementClient.swift`。`FunctionsService.call("listannouncements" / "markannouncementsread")`を呼び、`ImplInquiryClient`と同じくepochミリ秒の変換・`HttpsError`の変換を行う。`linkUrl`はhttpsでなければ`nil`にする
  - `AnnouncementTopicClient`: 購読は`HometeInfrastructure/Messaging/`に`MessagingTopicService`（`Messaging.messaging().subscribe(toTopic:)` / `unsubscribe(fromTopic:)`）を足し、`AppRoot/Dependency/Impl/ImplAnnouncementTopicClient.swift`でUserDefaultsの設定と合わせて実装する
- `AppDependencies`に2つを足す

### 3. Store（`HometeDomain/Announcement/AnnouncementStore.swift`）

ベルのバッジ・起動時のモーダル・一覧で同じ状態を使うため、`AppTabView`が1つ持ち、Environmentで配る。

```swift
@MainActor @Observable
public final class AnnouncementStore {
    public private(set) var state = AnnouncementState()

    /// 取り直す。取得中にもう一度呼ばれたら、進行中の取得を待つ。失敗しても取得済みの内容は残す
    public func refresh() async
    /// この端末で既読にした位置を踏まえて、お知らせが未読か
    public func isUnread(_ announcement: Announcement) -> Bool
    /// 一覧を開いたとき。先頭のお知らせを既読にし、未読の数とモーダルを消す（行の`isUnread`はそのまま）
    public func markListRead() async
    /// モーダルを閉じたとき。表示したお知らせを既読にし、モーダルを消す
    public func markModalRead(_ announcement: Announcement) async
}

public struct AnnouncementState: Equatable, Sendable {
    public var announcements: [Announcement] = []
    public var unreadCount = 0
    /// 起動時に出すお知らせ。`announcements`から引く
    public var modalAnnouncement: Announcement?
    public var hasLoaded = false
    public var isRefreshing = false
    public var loadFailure: DomainError?
}
```

- 起動時のお知らせは、起動後に初めて取得できたときだけ`modalAnnouncement`に入れる（`hasDecidedModalAnnouncement`）。閉じた後や一覧を開いた後に取り直しても出し直さない
- 一覧を既読にした位置（`publishedAt`）を手元にも持ち、既読にする前に始めた取得が後から返っても、未読の数（`unreadCount`）と各お知らせの未読（`isUnread(_:)`）が戻らないようにする。既読にできなかったら位置を戻す

### 4. 起動時の購読（`AnnouncementTopicUseCase`）

- 起動時に`AnnouncementTopicClient.loadIsEnabled()`を見て`subscribe`/`unsubscribe`する。`HometeApp`の`AppDelegate`で`MessagingConfigurator.configure()`の後に呼ぶ（ログイン状態に関わらないため、`RootView`より手前）
- 設定画面のトグルも同じUseCaseの`update(isEnabled:)`を通し、保存と購読の切り替えを1か所にまとめる

### 5. 通知の受信・タップ

- `HometeDomain/Announcement/AnnouncementNotificationData.swift`: `userInfo`の`type == "announcement"`を判別する（`InquiryReplyNotificationData`と同じ形）
- `PendingRoute`に`.announcementList`を足し、`init?(userInfo:)`で判別する
- フォアグラウンドでの受信: `AppDelegate.userNotificationCenter(_:willPresent:)`で`AnnouncementNotificationData`なら`NotificationCenter`へ`.didReceiveAnnouncementNotification`を流し、`AppTabView`が`announcementStore.refresh()`する
- タップ: `AppTabView.onChangePendingRoute()`で`.announcementList`ならダッシュボードのタブへ切り替え、`HomeView`がモーダルを出していなければお知らせ一覧のシートを開く（`openSettingForPendingRouteIfNeeded`と同じ待ち方）

### 6. 画面（`HomeFeature/Announcement/`）

問い合わせが設定画面の中にあるのと同じく、導線を持つ`HomeFeature`の中に置く（新しいFeatureモジュールにすると`Package.swift`・`.prefire.yml`・`hometeVRT.xcodeproj`のリンク設定まで増えるため）。

| Screen（ロジック） | View（UIのみ・`#Preview`） | 内容 |
|---|---|---|
| `AnnouncementListScreen` | `AnnouncementListView` | `NavigationStack`と`AnnouncementRoute`を持つ。一覧・空状態・エラー。開いて取得できたら`markListRead` |
| `AnnouncementDetailScreen` | `AnnouncementDetailView` | 本文と「詳しく見る」 |
| `AnnouncementModalScreen` | `AnnouncementModalView` | 起動時のシート。閉じたら`markModalRead` |
| — | `AnnouncementListRow` | 行（タイトル・公開日・未読ドット） |

- ベル: `homeNavigationBar`に`onTapAnnouncement`と`unreadAnnouncementCount`を足し、`HometeUI`の`NavigationBarButton`にバッジの表示を足す。ベルのアイコンはダッシュボードだけで使うので`.symbol("bell", …)`で渡す（チュートリアルのダッシュボードも同じバーを使うため、チュートリアル中はバッジ0で出す）
- `HomeView`に`isShowAnnouncementList`と、起動時のシートで出しているお知らせ`presentedAnnouncementModal`を持たせる。出せる条件（`announcementModalCandidate`）は、ダッシュボードの上に別のシート・登録後のチュートリアル・招待リンクの参加画面が無く、通知から開く画面も残っていないこと。条件がそろったときに`presentedAnnouncementModal`へ入れ、シートを閉じたら（スワイプを含む）表示したお知らせで`markModalRead`する
- 一覧を開いている間は、お知らせが変わるたびに`markListRead`を呼ぶ（既読にした位置より新しいものが無ければ`AnnouncementStore`が何もしない）。未読のドットは、既読にする前に`isUnread(_:)`で見た未読を`AnnouncementListScreen`が覚えて、詳細を開くか一覧を閉じるまで出し続ける
- `AppScreen`に`announcementList` / `announcementDetail` / `announcementModal`を足し、各Screenで`.trackScreenView`する。`doc/analytics_events.md`の画面一覧も更新する

### 7. 通知設定のトグル（`SettingFeature/SettingNotification/`）

- 通知が許可されているときの`DailyCompletionReminderSettingView`の下に、お知らせのセクションとトグルを足す（View名を改めると参照スナップショットの改名まで広がるため、名前はそのままにする）
- 通知が許可されていないときは、今まで通り権限の案内だけを出す（購読していても通知は出ないため）

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規モデル | `LocalPackage/Sources/HometeModel/Announcement/Announcement.swift` | お知らせ（+`Announcement+Preview.swift`） |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Announcement/` | `AnnouncementList`・`AnnouncementReadScope`・`AnnouncementError`・`AnnouncementNotificationData`・`AnnouncementStore` |
| 新規UseCase | `LocalPackage/Sources/HometeDomain/UseCase/AnnouncementTopicUseCase.swift` | 通知の設定の保存とトピックの購読をそろえる |
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/AnnouncementClient.swift`・`AnnouncementTopicClient.swift` | プロトコルと`previewValue` |
| 修正 | `LocalPackage/Sources/HometeDomain/Dependencies/AppDependencies.swift`・`InfraPackage/Sources/AppRoot/Dependency/AppDependencies+liveValue.swift` | Client・UseCaseの追加 |
| 修正 | `LocalPackage/Sources/HometeDomain/PendingRoute/PendingRoute.swift`・`PendingRouteStore.swift` | `.announcementList`の追加と取り出し |
| 修正 | `LocalPackage/Sources/HometeDomain/NotificationCenter/NotificationCustomName.swift` | `.didReceiveAnnouncementNotification` |
| 修正 | `LocalPackage/Sources/HometeDomain/AnalyticsLog/AppScreen.swift` | 画面3つ |
| 新規Infra | `InfraPackage/Sources/HometeInfrastructure/Messaging/MessagingTopicService.swift` | トピックの購読・解除 |
| 新規Impl | `InfraPackage/Sources/AppRoot/Dependency/Impl/ImplAnnouncementClient.swift`・`ImplAnnouncementTopicClient.swift` | `liveValue` |
| 修正 | `InfraPackage/Sources/AppRoot/AppTabView.swift`・`RootView.swift` | `AnnouncementStore`の保持・注入・PendingRoute |
| 新規 | `InfraPackage/Sources/AppRoot/AnnouncementRefreshModifier.swift` | お知らせを取り直すタイミング |
| 修正 | `homete/Views/HometeApp.swift` | 起動時の購読、フォアグラウンド受信の通知 |
| 新規View | `LocalPackage/Sources/Features/HomeFeature/Announcement/` | 一覧・詳細・モーダル・行・`AnnouncementRoute` |
| 修正View | `LocalPackage/Sources/Features/HomeFeature/HomeView/HomeView.swift`・`SubViews/HomeNavigationBar.swift` | ベル・シート・モーダル |
| 修正UI | `LocalPackage/Sources/HometeUI/Components/Navigation/NavigationBarButton.swift` | ベルのラベルとバッジ |
| 修正View | `LocalPackage/Sources/Features/SettingFeature/SettingNotification/`・`DailyCompletionReminder/` | お知らせの通知のトグル |
| 文言 | `HomeFeature`・`SettingFeature`・`HometeUI`の`Localizable.xcstrings` | 日本語と英訳 |
| ドキュメント | `doc/analytics_events.md` | 画面一覧 |
| テスト | `LocalPackage/Tests/HometeDomainTests/Announcement/`・`PendingRoute/` | Store・UseCase・通知データ・エラー・PendingRoute |

## タスク

### Phase 1: 設計確定

- [x] 一覧への導線はダッシュボードのベル（未読バッジ付き）
- [x] 起動時のモーダルはシート（タイトル・公開日・本文・詳しく見る・閉じる）
- [x] 一覧 → 詳細画面のpush遷移
- [x] お知らせの通知のオンオフを通知設定に足す
- [x] Push通知のタップは常に一覧を開く
- [x] 画面は`HomeFeature`の中に置く

### Phase 2: 実装

コミットは対応ごとに分ける（ドメイン・Client → Infra → 画面 → 通知 → 設定 → ドキュメント）。

- [x] `Announcement`・`AnnouncementList`・`AnnouncementReadScope`・`AnnouncementError`とテスト
- [x] `AnnouncementClient`・`AnnouncementTopicClient`と`AppDependencies`への追加
- [x] `ImplAnnouncementClient`・`MessagingTopicService`・`ImplAnnouncementTopicClient`
- [x] `AnnouncementStore`とテスト
- [x] `AnnouncementTopicUseCase`とテスト、起動時の購読
- [x] 一覧・詳細・行のView/Screen、`AnnouncementRoute`、Preview
- [x] モーダルのView/Screen、Preview
- [x] ベルとバッジ（`NavigationBarButton`・`homeNavigationBar`・`HomeView`）
- [x] `AppTabView`での`AnnouncementStore`の保持と取得のタイミング
- [x] `AnnouncementNotificationData`・`PendingRoute.announcementList`とテスト、フォアグラウンド受信・タップの処理
- [x] 通知設定のトグル
- [x] `AppScreen`の追加と`doc/analytics_events.md`の更新
- [x] 文言の英訳（`make check-translations`）

### Phase 3: 検証

- [x] `make build-affected` でビルド通過（InfraPackageも）
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過
- [x] `make test-affected` でユニットテスト通過
- [x] `make check-previews`・`make snapshot-affected`
- [ ] stgで疎通確認（一覧・既読・モーダル・Push通知の受信とタップ・通知のオフ）

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/533
- 既存実装（参考）:
  - `LocalPackage/Sources/HometeDomain/Inquiry/InquiryListStore.swift`（一覧と未読の数を1つのStoreで持つ形）
  - `InfraPackage/Sources/AppRoot/Dependency/Impl/ImplInquiryClient.swift`（Callableの呼び出しとエラーの変換）
  - `LocalPackage/Sources/HometeDomain/Inquiry/InquiryReplyNotificationData.swift`（サーバーが送る通知の判別）
  - `LocalPackage/Sources/Features/HomeFeature/HomeView/HomeView.swift`（`openSettingForPendingRouteIfNeeded`のモーダル待ち）
  - `InfraPackage/Sources/AppRoot/Dependency/Impl/ImplNotificationGuideStateClient.swift`（UserDefaultsに保存するClient）
