# 招待リンクの着地ページ強化とディファードディープリンク 実装方針

> 関連Issue: [#274 Lineで招待リンクからアプリがひらけない](https://github.com/stotic-dev/homete_iOS/issues/274)
> ブランチ: `fix/invitation-landing-page`
> 前提となる招待リンクの設計は [doc/strategy/cohabitant-invitation-link.md](cohabitant-invitation-link.md) / [ADR-0013](../adr/0013-cohabitant-invitation-universal-link.md) を参照。
> ディファードディープリンクの方式選定は [ADR-0018](../adr/0018-deferred-deep-link-with-clipboard.md) を参照。

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

招待リンク（`https://<host>/invite/<token>`）を LINE で共有すると LINE 内蔵ブラウザ（WebView）で開かれ、Universal Links が発火せずアプリに遷移できない。WebView は AASA の照合を行わないため、Universal Links だけに頼る現状の設計では SNS 経由の招待が成立しない。

着地ページ（Firebase Hosting の `/invite/index.html`）を「WebView で開かれても参加に辿り着ける」形に作り替え、あわせてアプリ未インストールのユーザーがインストール後も招待を引き継げるよう、クリップボードを使ったディファードディープリンクを自前で実装する。

## 要件

### 機能要件

#### 着地ページ（`firebase/hosting/public/invite/index.html`）

- Universal Links として開かれた場合は現状どおりアプリが直接起動する（AASA・rewrite は変更しない）
- WebView や Safari で Web ページとして着地した場合、次の 2 導線を表示する
  - **「アプリで開く」**（プライマリ）: カスタム URL スキーム `<scheme>://invite/<token>` へのリンク。**ユーザーのタップ起点**で開き、ページロード時の自動リダイレクトは行わない
  - **「初めての方はこちら」**（セカンダリ）: タップ時に招待 URL をクリップボードへコピーしてから App Store（`https://apps.apple.com/app/id6744935314`）へ遷移する
- 「インストール後はアプリを開くとリンクの確認を案内される／リンクをもう一度タップしても参加できる」旨を手順として明記する
- Smart App Banner（`apple-itunes-app`）を設置し、`app-argument` にそのページの URL を載せる（Safari で開かれた場合の補助導線）
- OGP（`og:title` / `og:description` / `og:image` / `og:url`）を設定する。画像はアプリアイコンから作った 1200x630 の `ogp.png` を Hosting に置く
- カスタム URL スキームは `location.hostname` で判定する（dev ホスト → `homeau-dev`、prod ホスト → `homeau`）
- 有効期限（24 時間）の注意書きは残す

#### 共有 URL（iOS 側）

- 共有する招待 URL に `openExternalBrowser=1` を付与する（`https://<host>/invite/<token>?openExternalBrowser=1`）。LINE はこのクエリがあるとリンクを外部ブラウザ（Safari）で開くため、Safari 経由で Universal Links／Smart App Banner／着地ページのいずれかに到達できる。他のアプリはこのクエリを無視する
- 招待トークンの解析（`CohabitantInvitationLink.token(from:)`）は、クエリの有無に関わらずパスからトークンを取り出す（現状の挙動を維持）

#### カスタム URL スキーム（iOS 側）

- `CFBundleURLSchemes` に招待用スキームを追加する。スキームは Build Setting `INVITE_URL_SCHEME` で構成ごとに切り替える（Debug / Stg: `homeau-dev`、Release: `homeau`）
- `<scheme>://invite/<token>` で起動した場合も Universal Links と同じ経路（`RootView.onOpenURL` → `PendingInvitationStore`）でトークンを受け取る

#### ディファードディープリンク（クリップボード補助、iOS 側）

- ログイン済みかつグループ未所属（ダッシュボードが `NotRegisteredContent` を表示している）状態で、アプリがフォアグラウンドになるたびに `UIPasteboard.general.detectPatterns(for: [.probableWebURL])` で **URL らしきものがクリップボードにあるかだけ**確認する（内容は読まない。iOS 16 以降、内容を読むとシステムのペースト通知が出るため）
- URL らしきものがある場合のみ、`NotRegisteredContent` に「招待リンクからアプリを開きましたか？」の案内と **「招待リンクを確認する」ボタン**を表示する（コピーは着地ページが自動で行うためユーザーに自覚がない。文言では「コピー」に触れず、招待リンク経由で来たかを問いかける）
- ボタンをタップしたときだけクリップボードを読み取り、招待リンクなら `PendingInvitationStore` にトークンを渡して参加確認画面（`CohabitantJoinView`）を表示する。招待リンクでなければ「招待リンクが見つかりませんでした」と表示し、同じクリップボード内容（`changeCount` が同じ）では再度案内しない
- ボタンを押さずに放置した場合は、フォアグラウンド復帰のたびに再確認する（クリップボードが変わっていれば案内を出し直す）

#### 参加確認画面（招待者名の表示）

- `CohabitantJoinView` を開いたら、参加ボタンを押す前に招待情報を取得し、**「〇〇さんのグループに参加しますか？」**と招待者名を表示する（招待者名が無い場合は「グループに参加しますか？」）
- 取得の時点で無効なリンク・期限切れが分かるため、参加ボタンを押す前に失敗表示（`CohabitantJoinFailureView`）へ倒す
- 取得中はローディングを表示する
- 取得後の参加処理・完了・参加済み・失敗の挙動は現状のまま

### 非機能要件 / 制約

- SNS ごとの個別対処（クエリでの出し分けなど）は行わない。LINE の `openExternalBrowser=1` は「付けるだけで他に影響がない」ため例外的に採用する
- 外部 SDK（AppsFlyer / Adjust / Branch）やフィンガープリントによる確率的マッチングは採用しない（Issue のスコープ外。[ADR-0018](../adr/0018-deferred-deep-link-with-clipboard.md)）
- Android 向けの `intent://` は対応しない（Android アプリが存在しないため）
- Firebase Dynamic Links は終了済みのため選択肢に含めない
- クリップボードの読み取りはユーザー操作起点に限定する（`detectPatterns` 以外で勝手に読まない）
- 既存の Universal Links の経路・AASA・entitlements は変更しない
- iOS 側の Client は既存の DI パターン（`DependencyClient` + `liveValue` / `previewValue`）に従う。`UIPasteboard` は `liveValue` の実装（`AppRoot/Dependency/Impl/`）に閉じ込め、Domain / Feature から直接触らない
- Functions は既存の `cohabitantInvitation.ts` / `InvitationManager.ts` のパターンに揃え、E2E テストを追加する
- 着地ページは dev / prod で同じ HTML を配信する（Hosting の `public` は共通）。環境差はホスト名からの判定で吸収する

## 設計方針

### 1. 着地ページ（Hosting）

`firebase/hosting/public/invite/index.html` を作り替える。

```html
<head>
  <!-- OGP -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="homeauのグループに招待されています">
  <meta property="og:description" content="同居人と家事を分け合うアプリ homeau。リンクからグループに参加できます。">
  <meta property="og:image" content="https://homete-ios-dev.web.app/invite/ogp.png">   <!-- 静的な絶対URL（本番ホスト） -->
  <meta name="twitter:card" content="summary">
  <!-- Smart App Banner: Safari はページ解析時に meta を読むため、head 内で document.write して app-argument を載せる -->
  <script>document.write('<meta name="apple-itunes-app" content="app-id=6744935314, app-argument=' + canonicalURL + '">');</script>
</head>
<body>
  <a class="button primary" id="openAppLink">アプリで開く</a>
  <a class="button secondary" id="appStoreLink">初めての方はこちら（App Store）</a>
  <ol>…インストール後の手順…</ol>
</body>
```

JS 側の責務:

| 処理 | 内容 |
|---|---|
| トークン取得 | `location.pathname` の `/invite/<token>` からトークンを取り出す。取れなければ両ボタンを無効化して「リンクが正しくありません」を表示 |
| スキーム判定 | `location.hostname === "homete-ios-dev-e3ef7.web.app"` なら `homeau-dev`、それ以外は `homeau` |
| アプリで開く | `href = "<scheme>://invite/<token>"`。クリックハンドラでの自動遷移・成否判定はしない |
| 初めての方はこちら | クリックで `navigator.clipboard.writeText(canonicalURL)`（失敗時は `execCommand("copy")` にフォールバック、それも失敗しても遷移は続行）→ `location.href = APP_STORE_URL` |
| Smart App Banner | `head` 内のインラインスクリプトで `document.write` し、`app-argument=<canonicalURL>` 付きの `apple-itunes-app` meta を出力する（後から属性を書き換えても Safari は拾わないため） |
| OGP 画像 URL | クローラーは JS を実行しないため静的値のみ。dev/prod で同じファイルを配信するので、どちらのリンクでも到達できる prod ホストの絶対 URL を指定する |

`canonicalURL` は `https://<host>/invite/<token>`（`openExternalBrowser` は付けない）。クリップボードから拾ったときにアプリが解析できればよいので余計なクエリは載せない。

OGP 画像 `firebase/hosting/public/invite/ogp.png` は `homete/Assets.xcassets/AppIcon.appiconset/1024.png` を `sips` で 1200x630（背景 `#fdf9f3`）に加工して生成する。

`firebase.json` の `headers` に `ogp.png` のキャッシュ設定（`Cache-Control: public, max-age=86400`）を追加する。

### 2. 共有 URL とカスタムスキームの解析（Domain）

`LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantInvitationLink.swift`:

```swift
public enum CohabitantInvitationLink {

    /// LINEに外部ブラウザで開かせるためのクエリ。他のアプリは無視する
    static let openExternalBrowserQueryItem = URLQueryItem(name: "openExternalBrowser", value: "1")

    /// 「アプリで開く」用のカスタムURLスキーム（Info.plistの`INVITE_URL_SCHEME`と一致させる）
    public static var customScheme: String {
        #if DEBUG
        "homeau-dev"
        #else
        "homeau"
        #endif
    }

    /// 共有用URL。`?openExternalBrowser=1` 付き
    public static func url(token: String) -> URL?

    /// Universal Link（クエリ付き含む）またはカスタムスキームURLからトークンと起動経路を取り出す
    public static func parse(_ url: URL) -> Parsed? {
        // https://<host>/invite/<token>[?...]  または  <customScheme>://invite/<token>
    }

    /// トークンだけが必要な呼び出し側向け（`parse(_:)?.token`）
    public static func token(from url: URL) -> String?
}
```

- `url(token:)` はクエリを付けた URL を返す。既存テスト（`CohabitantInvitationLinkTest`）の期待値を更新する
- `token(from:)` は `scheme == customScheme && host == "invite" && pathComponents == [token]` も受け付ける（カスタムスキームでは `invite` がホスト扱いになる）
- `host` の `#if DEBUG` 切り替えと同じ流儀で `customScheme` も切り替える。Stg（TestFlight）は DEBUG が定義され dev ホストを向くため、スキームも `homeau-dev` で整合する

### 3. カスタム URL スキームの登録（メインターゲット）

- `homete/Info.plist` の `CFBundleURLTypes` に `$(INVITE_URL_SCHEME)` のエントリを追加する（RevenueCat 用とは別 dict にする）
- `homete.xcodeproj/project.pbxproj` の homete ターゲットの Build Settings に `INVITE_URL_SCHEME` を追加する（Debug / Stg: `homeau-dev`、Release: `homeau`）。秘匿情報ではないため xcconfig（gitignore 済み）には置かない

### 4. Functions: 招待情報の取得

`firebase/functions/src/cohabitantInvitation.ts` に `fetchcohabitantinvitation`（v2 callable）を追加する。

```
入力: { token: string }
出力: { inviterName: string | null, cohabitantId: string | null, expiresAt: number }
```

1. 未認証なら `unauthenticated`、`token` が無ければ `invalid-argument`
2. `Invitation/{token}` を取得。無ければ `invitation-not-found`（→ `not-found`）
3. `expiresAt < now` なら `invitation-expired`（→ `deadline-exceeded`）
4. 発行者の `Account` を `createdBy` で引き、`userName` を `inviterName` として返す（Account が無ければ `null`）

`InvitationManager.ts` に `fetchInvitation(token, now)` を追加し、既存の `joinCohabitantByInvitation` と同じ検証（取得・期限）を共有する。エラーは既存の `InvitationError` / `toHttpsError` に乗せる。

E2E テスト（`test/e2e/cohabitantInvitation.test.ts`）に、正常取得 / 招待者名なし / 無効トークン / 期限切れ / 未認証のケースを追加する。

### 5. iOS: 招待情報の取得 Client と参加確認画面

`HometeDomain/Cohabitant/CohabitantInvitationSummary.swift`（新規）:

```swift
/// 参加前に表示する招待の概要
public struct CohabitantInvitationSummary: Equatable, Sendable {
    public let inviterName: String?
    public let expiresAt: Date
}
```

`HometeDomain/Dependencies/CohabitantInvitationClient.swift` に `fetch: @Sendable (_ token: String) async throws -> CohabitantInvitationSummary` を追加し、`AppRoot/Dependency/Impl/ImplCohabitantInvitationClient.swift` で `fetchcohabitantinvitation` を呼ぶ（エラー変換は既存の `convert` を流用）。

`CohabitantJoinState` の変更:

```swift
public enum CohabitantJoinState {
    /// 招待情報を取得中（画面を開いた直後）
    case loading
    /// 参加するかどうかの確認待ち
    case confirming(CohabitantInvitationSummary)
    case processing
    case completed
    case alreadyMember
    case failed(CohabitantJoinFailure)
}
```

`CohabitantJoinStore`:

- 初期状態を `.loading` にし、`load()` を追加。`fetch(token)` の成功で `.confirming(summary)`、失敗で `.failed(CohabitantJoinFailure(error))`
- `join()` は `.confirming` からのみ実行可能（それ以外は無視）
- 既存のテスト（`CohabitantJoinStoreTest`）を `load()` → `join()` の 2 段階に更新し、取得失敗（無効 / 期限切れ / 通信エラー）のケースを追加する

`CohabitantJoinView`:

- `.task` で `store.load()` を呼ぶ
- `.loading` → `Indicator` + 「招待を確認しています...」
- `.confirming(summary)` → `summary.inviterName` があれば「**〇〇さん**のグループに参加しますか？」、無ければ「グループに参加しますか？」。本文は現状の文言を維持
- 状態ごとの見た目は `SubViews/CohabitantJoinContent.swift`（`state` / `onTapJoin` / `onTapClose` を引数で受ける）に切り出し、Preview はこのコンポーネントで `confirming（名前あり／なし）` を撮る。`CohabitantJoinView` は表示直後に `.task` で取得を始めるため、画面自体を Preview すると取得完了前のスピナーが撮られてしまい（実際に確認画面の参照スナップショットがスピナーで上書きされた）、VRT の対象にしない
- スピナーを含む `loading` / `processing` の Preview は `.prefireIgnored()` で VRT から除外する（回転角が撮影ごとに変わりフレーキーになるため。`LoadingIndicator` / `CohabitantRegistrationProcessingView` と同じ扱い）

### 6. iOS: クリップボード補助

#### Client（Domain / Infrastructure）

`HometeDomain/Dependencies/PasteboardClient.swift`（新規）:

```swift
public struct PasteboardClient: Sendable {

    /// クリップボードにURLらしきものがあるかを、内容を読まずに調べる
    /// - Returns: 判定結果と、そのときのクリップボードの世代（同じ内容を二度案内しないために使う）
    public let detectProbableWebURL: @Sendable () async -> PasteboardDetection
    /// クリップボードの内容を読み取る（システムのペースト通知が出るため、ユーザー操作起点でのみ呼ぶ）
    /// - Returns: 読み取ったURLと、その時点の世代（処理済みの内容を正確に控えるため一緒に返す）
    public let readURL: @Sendable () async -> PasteboardContent
}

public struct PasteboardDetection: Equatable, Sendable {
    public let hasProbableWebURL: Bool
    public let changeCount: Int
}
```

- `previewValue` は「URL なし」を返す
- `liveValue` は既存の Client と同じく `AppRoot/Dependency/Impl/ImplPasteboardClient.swift` に `#if os(iOS)` で実装する。`detectPatterns(for: [\.probableWebURL])`（async 版が無いため `withCheckedContinuation` で包む）と `UIPasteboard.general.changeCount`、`readURL` は `UIPasteboard.general.url ?? URL(string: string)` を返す
- `AppDependencies` に `pasteboardClient` を追加する

#### Store（Domain）

`HometeDomain/Cohabitant/PasteboardInvitationStore.swift`（新規、`@MainActor @Observable`）:

```swift
public final class PasteboardInvitationStore {

    public enum State: Equatable {
        case idle                 // 案内を出さない
        case suggesting           // 「招待リンクを確認する」導線を出す
        case notFound             // 読み取ったが招待リンクではなかった
    }

    public private(set) var state: State = .idle

    /// フォアグラウンド復帰・表示時に呼ぶ。URLらしきものがあり、未処理の世代なら `.suggesting` にする
    public func checkIfNeeded() async
    /// 「招待リンクを確認する」タップ時に呼ぶ。招待リンクなら `PendingInvitationStore` にトークンを渡す
    public func readInvitation() async
}
```

- `checkIfNeeded()` は `detectProbableWebURL()` の結果が `hasProbableWebURL == true` かつ `changeCount != lastHandledChangeCount` のときだけ `.suggesting` にする。それ以外は `.idle`
- `readInvitation()` は `readURL()` → `CohabitantInvitationLink.token(from:)`。トークンが取れたら `pendingInvitationStore.store(token)` して `.idle`、取れなければ `.notFound`。どちらも読み取った内容の `changeCount` を `handledChangeCount` に控え、同じ内容では再案内しない
- Analytics: 読み取りで招待リンクが見つかった場合に `cohabitant_invitation(action: open, step: pasteboard)` を送る（`RootView` の `linkOpened` と区別するため `step` を付ける。後述）

#### View（Feature）

`Features/HomeFeature/HomeView/SubViews/NotRegisteredContent.swift` に案内を追加する:

- `@Environment(\.scenePhase)` を監視し、`.active` になったとき・`onAppear` 時に `store.checkIfNeeded()` を呼ぶ
- `state == .suggesting` のとき、「パートナーを登録する」ボタンの下に案内カード（「招待リンクからアプリを開きましたか？」＋「招待リンクを確認する」ボタン）を表示する
- `state == .notFound` のとき「招待リンクが見つかりませんでした」と、復帰導線として「招待リンクをもう一度開く」案内を表示する（インストール済みなら Universal Link / 「アプリで開く」で直接起動できるため）
- 案内は `HomeView/SubViews/PasteboardInvitationBanner.swift`（`state` と `onTapCheck` を引数で受ける）として切り出し、状態のバリエーションはこのコンポーネント自身の Preview で網羅する。`NotRegisteredContent` は `pasteboardInvitationState` / `onTapCheckPasteboard` を引数で受け取り、Environment から Store を引かない（Preview で状態を作り分けるため）
- Store は `HomeView` で生成し、`PendingInvitationStore`（Environment）と `pasteboardClient` / `analyticsClient` を渡す。`checkIfNeeded()` は `NotRegisteredContent` の `.task` と `scenePhase == .active` への変化で呼ぶ

#### 起動経路

```
クリップボードに招待URL
  ↓ ダッシュボード（未所属）表示 / フォアグラウンド復帰
PasteboardInvitationStore.checkIfNeeded()   … detectPatterns（内容は読まない）
  ↓ 「招待リンクを確認する」タップ
PasteboardInvitationStore.readInvitation()  … UIPasteboard 読み取り（ペースト通知が出る）
  ↓ CohabitantInvitationLink.token(from:)
PendingInvitationStore.store(token)
  ↓ 既存の経路
AppTabView が fullScreenCover で CohabitantJoinView を表示
```

### 7. Analytics

`doc/analytics_events.md` の `cohabitant_invitation` を更新する。

| `action` | `step` | `result` | 送信タイミング |
|---|---|---|---|
| `open` | `universal_link` | — | Universal Link（`https`）でアプリが起動した |
| `open` | `custom_scheme` | — | 「アプリで開く」（カスタムスキーム）でアプリが起動した |
| `open` | `pasteboard` | — | クリップボードから招待リンクを読み取れた |
| `pasteboard_check` | — | `suggested` / `not_found` | クリップボード補助の案内を表示した / 読み取ったが招待リンクでなかった |

- `step` の説明を「発行を開始した画面、または起動の経路」に広げる
- `CohabitantInvitationAnalyticsAction.linkOpened` に経路（`CohabitantInvitationOpenSource`）を持たせる。`CohabitantInvitationLink.parse(_:)` がトークンと経路（`https` → `.universalLink`、カスタムスキーム → `.customScheme`）を一緒に返すので、`RootView.onOpenURL` はその結果をそのまま渡す（URLの形式判定は内部の `Format` enum に閉じ、`.pasteboard` は URL からは導かれない）

### 8. ADR

`doc/adr/0018-deferred-deep-link-with-clipboard.md` を作成する。内容:

- 問題: WebView では Universal Links が発火しない。未インストールユーザーの招待引き継ぎ手段が無い
- 決定: 着地ページ＋カスタム URL スキーム＋クリップボード補助（ユーザー操作起点）の自前実装
- 却下: 外部 SDK（コスト・SDK 依存・計測目的が主で過剰）、フィンガープリント（Private Relay / CGNAT で誤マッチのリスク、同一 Wi-Fi の別世帯へ誤参加しうる）、ページロード時の自動リダイレクト（Safari のエラーダイアログ）、Firebase Dynamic Links（終了済み）

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 修正（Hosting） | `firebase/hosting/public/invite/index.html` | 着地ページの作り替え（アプリで開く / App Store / Smart App Banner / OGP） |
| 新規（Hosting） | `firebase/hosting/public/invite/ogp.png` | OGP 画像（アプリアイコンから生成） |
| 修正 | `firebase/firebase.json` | `ogp.png` のキャッシュヘッダ |
| 修正（Functions） | `firebase/functions/src/cohabitantInvitation.ts` | `fetchcohabitantinvitation` の追加 |
| 修正（Functions） | `firebase/functions/src/models/InvitationManager.ts` | `fetchInvitation` の追加 |
| 修正（テスト） | `firebase/functions/test/e2e/cohabitantInvitation.test.ts` | `fetchcohabitantinvitation` の E2E |
| 修正 | `homete/Info.plist` | `CFBundleURLSchemes` に `$(INVITE_URL_SCHEME)` |
| 修正 | `homete.xcodeproj/project.pbxproj` | `INVITE_URL_SCHEME` の Build Setting |
| 修正（Domain） | `HometeDomain/Cohabitant/CohabitantInvitationLink.swift` | `openExternalBrowser=1` の付与、カスタムスキームの解析、`source(of:)` |
| 新規（Domain） | `HometeDomain/Cohabitant/CohabitantInvitationSummary.swift` | 招待の概要（招待者名・期限） |
| 修正（Domain） | `HometeDomain/Cohabitant/CohabitantJoinState.swift` | `loading` 追加、`confirming` に概要を持たせる |
| 修正（Domain） | `HometeDomain/Cohabitant/CohabitantJoinStore.swift` | `load()` の追加 |
| 新規（Domain） | `HometeDomain/Cohabitant/PasteboardInvitationStore.swift` | クリップボード補助の状態管理 |
| 新規（Domain） | `HometeDomain/Dependencies/PasteboardClient.swift` | クリップボード Client（プロトコル + `previewValue`） |
| 修正（Domain） | `HometeDomain/Dependencies/CohabitantInvitationClient.swift` | `fetch` の追加 |
| 修正（Domain） | `HometeDomain/Dependencies/AppDependencies.swift` | `pasteboardClient` の追加 |
| 修正（Domain） | `HometeDomain/AnalyticsLog/CohabitantInvitationAnalyticsAction.swift` | `linkOpened(source:)` / `pasteboardChecked` |
| 新規（Impl） | `AppRoot/Dependency/Impl/ImplPasteboardClient.swift` | `UIPasteboard` を使った `liveValue` |
| 修正（Impl） | `AppRoot/Dependency/Impl/ImplCohabitantInvitationClient.swift` | `fetchcohabitantinvitation` の呼び出し |
| 修正（AppRoot） | `AppRoot/RootView.swift` | `linkOpened(source:)` の送信 |
| 修正（View） | `Features/HomeFeature/JoinCohabitantView/CohabitantJoinView.swift` | Store 生成と取得開始（画面層。Preview なし） |
| 新規（View） | `Features/HomeFeature/JoinCohabitantView/SubViews/CohabitantJoinContent.swift` | 状態ごとの見た目（ローディング・招待者名の表示）・Preview |
| 修正（View） | `Features/HomeFeature/HomeView/HomeView.swift` | `PasteboardInvitationStore` の生成 |
| 新規（View） | `Features/HomeFeature/HomeView/SubViews/PasteboardInvitationBanner.swift` | クリップボード補助の案内バナー・Preview |
| 修正（View） | `Features/HomeFeature/HomeView/SubViews/NotRegisteredContent.swift` | バナーの配置（状態は引数で受ける）・Preview |
| 修正（テスト） | `Tests/HometeDomainTests/Cohabitant/CohabitantInvitationLinkTest.swift` | クエリ付き URL・カスタムスキームの解析 |
| 修正（テスト） | `Tests/HometeDomainTests/Cohabitant/CohabitantJoinStoreTest.swift` | `load()` の状態遷移 |
| 新規（テスト） | `Tests/HometeDomainTests/Cohabitant/PasteboardInvitationStoreTest.swift` | 案内の出し分け・世代管理 |
| 修正（テスト） | `Tests/HometeDomainTests/AnalyticsEventTest.swift` | 追加パラメータ |
| 修正（Doc） | `doc/analytics_events.md` | `open` の `step` と `pasteboard_check` |
| 新規（Doc） | `doc/adr/0018-deferred-deep-link-with-clipboard.md` | 方式選定の ADR |
| 修正（Doc） | `doc/strategy/cohabitant-invitation-link.md` | 「deferred deep link は行わない」の記述に本ドキュメントへの参照を追記 |

## タスク

### Phase 1: 設計確定

- [x] カスタム URL スキーム → 構成ごとに分ける（Debug / Stg: `homeau-dev`、Release: `homeau`）。Build Setting `INVITE_URL_SCHEME` で切り替え
- [x] 招待者名の表示 → `fetchcohabitantinvitation` を追加し、参加確認画面で取得・表示する
- [x] クリップボード補助のタイミング → グループ未所属時のフォアグラウンド復帰ごとに `detectPatterns` で確認。読み取りはタップ起点
- [x] OGP 画像 → アプリアイコンから 1200x630 を生成して Hosting に置く
- [x] LINE 対応 → 共有 URL に常に `openExternalBrowser=1` を付与
- [x] Android `intent://` → 対応しない（Android アプリが無い）

### Phase 2: 実装

- [x] ADR-0018 の作成
- [x] Hosting: 着地ページの作り替え（アプリで開く / 初めての方はこちら / Smart App Banner / OGP）
- [x] Hosting: `ogp.png` の生成と `firebase.json` のヘッダ追加
- [x] Functions: `fetchInvitation` / `fetchcohabitantinvitation` の追加 + E2E テスト
- [x] メインターゲット: `INVITE_URL_SCHEME` の Build Setting と `Info.plist` の `CFBundleURLSchemes`
- [x] Domain: `CohabitantInvitationLink` の `openExternalBrowser=1` 付与・カスタムスキーム解析・`source(of:)` + テスト更新
- [x] Domain: `CohabitantInvitationSummary` / `CohabitantInvitationClient.fetch` / `ImplCohabitantInvitationClient`
- [x] Domain: `CohabitantJoinState.loading` / `CohabitantJoinStore.load()` + テスト更新
- [x] View: `CohabitantJoinView` のローディング・招待者名表示 + `CohabitantJoinContent` の Preview
- [x] Domain: `PasteboardClient` / `PasteboardDetection` / `AppDependencies` 登録
- [x] Impl: `ImplPasteboardClient`（`UIPasteboard`）
- [x] Domain: `PasteboardInvitationStore` + テスト
- [x] View: `PasteboardInvitationBanner` / `NotRegisteredContent` のクリップボード補助 UI + `HomeView` での Store 生成 + Preview
- [x] Analytics: `linkOpened(source:)` / `pasteboardChecked` + `doc/analytics_events.md` 更新
- [x] `doc/strategy/cohabitant-invitation-link.md` に本ドキュメントへの参照を追記

### Phase 3: 検証

- [x] `swift build` でビルド通過
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過（`make check-previews` も通過）
- [x] ユニットテスト実行（追加分含む）通過（5ターゲット / 372件）
- [x] Functions の lint / E2E テスト通過（`cohabitantInvitation` 21件）
- [ ] スナップショットテスト（Prefire 経由で自動生成）通過 / 必要なら参照画像を更新（Xcode Cloud の `VRT` に委ねる）
- [ ] 実機で動作確認（Hosting / Functions を stg にデプロイ後）
  - LINE で共有したリンク → LINE 内ブラウザで着地ページが出る → 「アプリで開く」でアプリが起動し参加確認画面に招待者名が出る
  - LINE で共有したリンク（`openExternalBrowser=1`）→ Safari で開かれ、インストール済みなら Universal Links / Smart App Banner でアプリに遷移する
  - 未インストール → 「初めての方はこちら」で App Store へ → インストール・登録後のダッシュボードで「招待リンクを確認する」が出て参加できる
  - 無関係な URL をコピーした状態 → 案内は出るが「招待リンクが見つかりませんでした」になり、以後同じ内容では案内が出ない
  - 期限切れ・無効トークンは参加ボタンを押す前に失敗表示になる

### Phase 4: PR

- [x] PR作成（`pr-create` スキル使用）: [#275](https://github.com/stotic-dev/homete_iOS/pull/275)
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ
- [ ] マージ後: Hosting / Functions を prod へ `workflow_dispatch` でデプロイ（`environment=prod`）

## 残課題（今回のスコープ外）

- App Clip による未インストール時の即時参加（Issue に「将来検討」として記載）
- Smart App Banner の App Store ID は本番アプリ固定のため、stg の着地ページからも本番アプリが案内される（stg で Smart App Banner を検証したい場合は TestFlight ビルドでは動かない点に注意）

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/274
- PR: https://github.com/stotic-dev/homete_iOS/pull/275
- 既存実装（参考）:
  - `firebase/hosting/public/invite/index.html`
  - `firebase/functions/src/cohabitantInvitation.ts` / `firebase/functions/src/models/InvitationManager.ts`
  - `LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantInvitationLink.swift`
  - `LocalPackage/Sources/HometeDomain/Cohabitant/CohabitantJoinStore.swift`
  - `LocalPackage/Sources/Features/HomeFeature/JoinCohabitantView/CohabitantJoinView.swift`
  - `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/NotRegisteredContent.swift`
  - `LocalPackage/Sources/AppRoot/RootView.swift`
