# 初回インストール時のオンボーディング改善 実装方針

> 関連Issue: [#461 匿名認証とApple連携の基盤](https://github.com/stotic-dev/homete_iOS/issues/461)、[#462 ログイン前の説明画面](https://github.com/stotic-dev/homete_iOS/issues/462)、[#463 パートナー登録のステップとやることリスト](https://github.com/stotic-dev/homete_iOS/issues/463)
> ブランチ: `feat/461-anonymous-auth-link-apple`
> 匿名認証の採用経緯: [ADR-0054](../adr/0054-start-with-anonymous-auth-and-link-apple-later.md)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

今は起動するといきなりSign in with Appleを求められ、オンボーディングもパートナー登録まで案内しない。
ログインで離脱する人と、パートナー登録までたどり着けずに離脱する人が多いと考えている。

これを次のように変える。

- ログイン前にアプリの説明を見せる
- 匿名認証で始めて、ニックネームとパートナー登録まで済ませてから、Appleアカウントと連携してもらう（ここまで進めたことを手放したくない、という気持ちで離脱を抑える）
- オンボーディングでパートナー登録を飛ばした人には、未参加ホームに「やることリスト」を出し、パートナー登録とApple連携を終えると家事機能が使えると伝える

## 要件

### 全体のフロー

```
起動
 └ 説明画面（3枚）
     ├ 「すでにアカウントをお持ちの方」→ 今のAppleログイン（LoginView）
     └ 「はじめる」→ 裏で匿名サインイン
         → ニックネーム登録
         → パートナー登録
             ├ 招待リンクを送る → 共有を完了 ─┐
             ├ 隣にいる（P2P）→ 登録が完了 ─┤
             ├ 招待された → 参加が完了 ──────┤
             │                                 └→ Apple連携（必須）
             └ あとで ─────────────────────────→（Apple連携を飛ばす）
         → 通知許可 → プラン紹介 → ホーム
```

### 説明画面

- 3枚をページングで見せる。内容は「家事を記録する」「パートナーと共有する」「ありがとうを送り合う」。各ページにほめっとを出す
- どのページにも「はじめる」と「すでにアカウントをお持ちの方」を置く（最後まで読まなくても進める）
- 「すでにアカウントをお持ちの方」は今の`LoginView`を出す。Appleでログインした結果アカウントが無ければ、今と同じく`preLoggedIn`からニックネーム登録へ進む（この人は匿名を経ないため、Apple連携のステップは出ない）
- 招待リンクを開いてから起動した人（`PendingInvitationStore`にトークンがある人）には、1枚目の上に「〇〇さんから招待が届いています」を出す
  - 招待者名はログイン前に取る必要があるため、`fetchcohabitantinvitation`を未認証でも呼べるようにする（後述）
  - 取得に失敗した・無効な招待のときは、招待の表示を出さずに通常の説明画面にする

### オンボーディングのステップ

並びは「ニックネーム → パートナー登録 → Apple連携 → 通知許可 → プラン紹介」。

#### パートナー登録

「誰と使いますか？」として4つの選択肢を出す。

| 選択肢 | その後 |
|---|---|
| 招待リンクを送る | 招待を発行して共有シートを出す。**共有を完了したら**（`ShareSheet`の`onComplete(true)`）Apple連携へ。キャンセルしたら選択肢の画面に戻る |
| 隣にいる | `CohabitantRegistrationView`を出す。登録が完了したらApple連携へ。閉じたら選択肢の画面に戻る |
| 招待された | クリップボードの招待リンクを確認する（`PasteboardInvitationStore`を流用）。見つかれば参加確認へ、見つからなければ「届いた招待リンクをもう一度開いてください」と案内する。参加が完了したらApple連携へ |
| あとで | Apple連携を飛ばして通知許可へ |

- 招待リンクから来た人（`PendingInvitationStore`にトークンがある人）は、選択肢を出さずに参加確認（`CohabitantJoinContent`）を出す。参加を断ったら選択肢の画面に戻す
- オンボーディングの途中でリンクを開いた場合も、パートナー登録のステップにいれば参加確認に切り替える
- 招待を送った人は、相手の参加を待たずにApple連携へ進む（相手の参加はADR-0017のとおり後から届く）

#### Apple連携

- 「Appleアカウントで保存」の画面。**スキップできない**
- 説明は「パートナーと共有した家事を、機種変更しても引き継げるようにします」の方向で、結果ベースで書く
- 匿名でないユーザー（説明画面から`LoginView`でログインした人）にはこのステップを出さない
- 連携に成功したら次のステップへ。キャンセルしたらこの画面に留まる
- 既存のアカウントと衝突した場合は後述

#### 通知許可・プラン紹介

今の`OnboardingNotificationPermissionGuideView` / `PremiumIntroductionView`をそのまま使う。

- プラン紹介で「プランを見る」を押した人が匿名なら、Paywallの前にApple連携を求める（購入の前に連携が必要なため。後述）

### 未参加ホームのやることリスト

グループ未参加のホーム（今の`NotRegisteredContent`）を「家事を始める前に」のやることリストに変える。

```
家事を始める前に
完了すると、家事の記録・共有ができるようになります

○ パートナーを登録する        [登録する]
○ Appleアカウントで保存する    [保存する]   ← 匿名のときだけ

（クリップボードの招待リンクの案内は今のまま下に出す）
```

- 並べるのは**未完了の項目だけ**。Appleでログイン済みの人にはパートナー登録の1項目だけを出す
- 「パートナーを登録する」は今の「パートナーを登録する」ボタンと同じく、パートナー登録のモーダルを出す
- 招待リンクを送った後、その招待が有効期限内なら「パートナーを登録する」の行を「参加を待っています」に変え、「もう一度送る」で共有シートを出し直す
  - 判定は、端末に保存した最後の招待（トークンと有効期限）で行う。機種変更では引き継がない
  - 相手が参加すると`Account.cohabitantId`が入り、ホームがグループ参加済みに切り替わるので、リストは自然に消える
- 「Appleアカウントで保存する」はオンボーディングと同じApple連携を行う
- 匿名のままパートナー登録を終えたときは、オンボーディングと同じタイミングでApple連携を求める（招待は共有を完了した直後、P2P・参加は完了した直後）

### 匿名ユーザーの扱い

匿名のユーザーは、Apple連携を終えるまで**グループに参加した状態でアプリを使えない**。

| 場所 | 匿名のときの挙動 |
|---|---|
| 起動時 | アカウントがありグループ未参加なら、未参加ホーム（やることリスト）へ。**グループに参加済みなら、Apple連携の画面を全画面で出す**（連携の画面で離脱した後に、相手の参加でグループに入っていた場合など） |
| 設定 → ログアウト | 出さない。代わりに「Appleアカウントで保存」を出す（匿名のログアウトはアカウントを捨てるのと同じため） |
| 設定 → 退会 | Appleの再認証・トークン失効を飛ばして、アカウントを削除する |
| 設定 → 招待リンクの発行 | 共有を完了したらApple連携を求める（未参加ホームと同じ） |
| Paywall（プラン紹介・設定・広告など全ての起点） | 表示する前にApple連携を求める。連携しなかったらPaywallを出さない |

### 既存のアカウントとの衝突

すでにAppleアカウントでhometeを使ったことがある人が「はじめる」から進むと、Apple連携が「このApple IDは別のアカウントで使用中」で失敗する。

- 「このAppleアカウントは、すでにhometeで使われています。そのアカウントでログインしますか？」と確認する
  - 「ログインする」: 匿名のアカウントを削除してから、そのAppleアカウントでログインする。匿名で登録したニックネーム・グループは引き継がない（確認の文言で伝える）
  - 「キャンセル」: 連携の画面に戻る
- 匿名のアカウントは削除するので、`deleteuserdata`がAccountとグループの後片付けを行う

### 放置された匿名アカウントの削除

- 最後に使われてから30日たった匿名アカウント（Apple未連携）を、定期実行のFunctionで削除する
  - 匿名のアカウントは使い続けてもサインインし直さないため、最終サインイン日時ではなくIDトークンの最終更新日時（`lastRefreshTime`）で判定する
- Account・グループの後片付けは、既存の`deleteuserdata`（Authの削除トリガー）に任せる

### 非機能要件 / 制約

- Firebaseコンソールで匿名認証のプロバイダを有効にする（stg / prod）
- App Checkは匿名ユーザーでも同じく効く（認証方法とは独立）
- Firestoreルール・既存のcallableは`request.auth.uid`しか見ていないため、匿名でもそのまま通る。ルールの変更は不要
- RevenueCatの`appUserID`はuidのまま。Apple連携ではuidが変わらないので、購入の紐付けはそのまま
- 既存ユーザー（Appleでログイン済み）の挙動は、未参加ホームの見た目が変わる以外は変えない
- テスト
  - `LaunchStateStore`の分岐（匿名・グループ参加済みでApple連携が必須になる）をユニットテストで固める
  - オンボーディングのステップの組み立て（匿名かどうか、招待があるか、パートナー登録で何を選んだか）をロジックとして切り出し、ユニットテストする
  - Apple連携の衝突時の流れ（匿名アカウントの削除 → ログイン）を`AccountAuthStore`のテストで確かめる
  - Functions: 未認証での`fetchcohabitantinvitation`、匿名アカウントの削除をE2Eテストに足す
- 文言は`ux-writing.md`に沿って敬体・結果ベースで書き、英訳も同じ変更で入れる

## 設計方針

### 1. 認証（HometeDomain / HometeInfrastructure）

`AccountAuthResult`に匿名かどうかを持たせる。

```swift
public struct AccountAuthResult: Equatable, Sendable {

    public let id: String
    /// 匿名認証のまま（Appleアカウントと未連携）かどうか
    public let isAnonymous: Bool

}
```

`AccountAuthClient`に匿名サインインとApple連携を足す。

```swift
public let signInAnonymously: @Sendable () async throws -> AccountAuthResult
/// 匿名のアカウントにAppleの認証情報を紐づける。uidは変わらない
/// - Throws: すでに別のアカウントで使われているAppleアカウントなら`AccountLinkError.credentialAlreadyInUse`
public let linkWithApple: @Sendable (_ tokenId: String, _ nonce: String) async throws -> AccountAuthResult
```

- `linkWithApple`の実装は`Auth.auth().currentUser?.link(with:)`。衝突時はFirebaseのエラーの`userInfo`に入る認証情報（`AuthErrorUserInfoUpdatedCredentialKey`）を`credentialAlreadyInUse`に載せて返し、そのままログインに使う（Appleの認証をもう一度求めない）
- `AccountAuthStore`に`startAnonymously()`・`linkWithApple(_:)`・`switchToExistingAccount(_:)`（匿名アカウントの削除 → 渡された認証情報でログイン）を足す
- `deleteAccount()`は匿名なら再認証・トークン失効を飛ばす
- 連携しても`Auth`のリスナーはuidの変化として通知しないことがあるため、連携の成功後は`currentAuth`を`isAnonymous: false`で更新し直す

### 2. 起動状態（`LaunchState` / `LaunchStateStore`）

```swift
public enum LaunchState: Equatable {

    case launching
    case preLoggedIn(auth: AccountAuthResult)
    case loggedIn(context: LoginContext)
    /// 匿名のままグループに参加している。Apple連携を終えるまで先に進ませない
    case accountLinkRequired(context: LoginContext)
    case notLoggedIn

}
```

- `LoginContext`に`isAnonymous`を持たせる
- `LaunchStateStore.applyLoggedIn`で、匿名かつグループ参加済みなら`.accountLinkRequired`にする。アカウントの変化（相手の参加で`cohabitantId`が入る）でも同じ判定が走るので、未参加ホームにいる間に相手が参加した場合も連携の画面に切り替わる
- `RootView`は`.notLoggedIn`で`LoginView`の代わりに説明画面を出し、`.accountLinkRequired`でApple連携の画面を全画面で出す

### 3. オンボーディング（AuthFeature）

```swift
enum OnboardingStep: Hashable, CaseIterable {

    case registration
    case partnerRegistration
    case accountLink
    case notificationPermission
    case premiumIntroduction

}
```

- `accountLink`は「匿名」かつ「パートナー登録で招待の共有・P2P登録・参加のどれかを終えた」ときだけ並びに入れる。パートナー登録の結果を受けて`steps`を組み立て直す
- ステップの並びを決める処理は、Viewから切り出してユニットテストできる形にする（今の`loadSteps`の通知の判定もここに寄せる）
- パートナー登録の選択肢画面から`CohabitantRegistrationView`（CohabitantRegistrationFeature）と参加確認（HomeFeatureの`CohabitantJoinContent`）を出すため、AuthFeatureからはRouteResolver経由で解決する（Feature同士を直接依存させない）
- 参加確認をHomeFeatureの外から使うことになるので、`CohabitantJoinView`の置き場所（`CohabitantRegistrationFeature`へ移すか）を実装時に判断する

### 4. 共通のApple連携の画面

オンボーディング・全画面（`.accountLinkRequired`）・やることリスト・設定・Paywallの前の5か所で使うため、1つの画面にまとめる。

- 中身: ほめっと、説明、Sign in with Appleボタン（`SignInUpWithAppleButton`を流用）
- 衝突時の確認アラートもこの画面が持つ
- オンボーディングと全画面ではスキップの導線を出さない。やることリスト・設定・Paywallの前ではシートで出し、閉じられる

### 5. 未参加ホームのやることリスト（HomeFeature）

- `NotRegisteredContent`をやることリストに作り替える。表示する項目は「匿名かどうか」「有効な招待を送っているか」から決める
- 最後に送った招待は`CohabitantInvitation`（トークン・有効期限）を`UserDefaults`に保存するClientを足して持つ。発行するのはオンボーディング・同居人登録画面・設定の3か所なので、保存は発行するUseCase（またはClient）側でまとめて行う
- ログアウト・退会で保存した招待を消す

### 6. Functions

- `fetchcohabitantinvitation`: `request.auth`を必須でなくする。未認証ならログにuidを出さないだけで、返す内容は同じ
  - App Checkは強制適用済みで、トークンは推測できない値のため、未認証で招待者名を返しても新たに漏れる情報は無い
- 新規: 匿名アカウントの掃除（定期実行の`cleanupanonymousaccounts`）。`listUsers`で`providerData`が空（匿名）かつ最後に使われた日時（`lastRefreshTime`）が30日より前のユーザーを1件ずつ削除する（`deleteUsers`では削除トリガーが呼ばれない）
- 新規: 匿名アカウントの削除（callableの`deleteanonymousaccount`）。匿名のアカウントは再認証できず、時間がたつと端末から削除できないため、退会と既存のアカウントへの切り替えはこれで削除する

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Authentification/AccountAuthResult.swift` | `isAnonymous`を足す |
| 修正Client | `LocalPackage/Sources/HometeDomain/Dependencies/AccountAuthClient.swift` | `signInAnonymously` / `linkWithApple`を足す |
| 修正Store | `LocalPackage/Sources/HometeDomain/Authentification/AccountAuthStore.swift` | 匿名で始める・連携・既存アカウントへの切り替え・匿名の退会 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/AppLaunch/LaunchState.swift` / `LaunchStateStore.swift` | `.accountLinkRequired`と判定 |
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/`（招待の保存） | 最後に送った招待の保存・読み出し |
| 修正Infra | `InfraPackage/Sources/HometeInfrastructure/`（AccountAuthClientのliveValue） | 匿名サインイン・`link(with:)`・衝突時の認証情報の取り出し |
| 新規View | `LocalPackage/Sources/Features/AuthFeature/Welcome/` | 説明画面 |
| 新規View | `LocalPackage/Sources/Features/AuthFeature/Onboarding/` | パートナー登録の選択肢・Apple連携 |
| 修正View | `LocalPackage/Sources/Features/AuthFeature/Onboarding/OnboardingFlowView.swift` / `OnboardingStep.swift` | ステップの追加・並べ替え |
| 修正View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/NotRegisteredContent.swift` | やることリスト |
| 修正View | `LocalPackage/Sources/Features/SettingFeature/SettingView.swift` | 匿名のときのログアウト・退会・招待 |
| 修正View | Paywallを出している各起点 | 匿名ならApple連携を先に出す |
| 修正Root | `InfraPackage/Sources/AppRoot/RootView.swift` | 説明画面・全画面のApple連携 |
| 修正Functions | `firebase/functions/src/cohabitantInvitation.ts` | 未認証での招待の取得 |
| 新規Functions | `firebase/functions/src/`（匿名アカウントの掃除） | 定期実行で削除 |
| 修正ドキュメント | `doc/analytics_events.md` | 下記のイベント |

### Analytics

`doc/analytics_events.md`を更新する。イベントは機能単位で、パラメータで区別する（ADR-0009）。

- 画面: 説明画面、パートナー登録の選択肢、Apple連携
- `onboarding`の`action`に、パートナー登録の選択（`invite` / `nearby` / `invited` / `later`）を足す
- Apple連携: 起点（`onboarding` / `required` / `todo` / `setting` / `paywall`）と結果（`success` / `cancel` / `conflict_switched` / `failure`）
- `login`に匿名サインインを区別するパラメータを足す
- ユーザープロパティに匿名かどうか（`is_anonymous`）を足し、ファネル（説明画面 → ニックネーム → パートナー登録 → Apple連携 → グループ参加）を匿名・Appleで分けて見られるようにする

## Issueの分け方

依存の順に3つに分けて起票し、上から順にPRを出す。

1. **匿名認証とApple連携の基盤**: 認証・`LaunchState`・共通のApple連携の画面・設定・Paywallの前の連携・衝突時の切り替え・匿名アカウントの掃除・ADR
2. **説明画面**: 説明画面・「すでにアカウントをお持ちの方」・招待者名の表示（`fetchcohabitantinvitation`の未認証対応を含む）
3. **オンボーディングのパートナー登録とやることリスト**: パートナー登録のステップ・ステップの並べ替え・未参加ホームのやることリスト・最後に送った招待の保存

1をマージしただけでは匿名で始める入口が無いため、ユーザーから見た挙動は変わらない。2をマージした時点で匿名で始められるようになるので、2と3は同じリリースに入れる。

## タスク

### Phase 1: 設計確定

- [x] ログイン前にパートナー登録まで済ませるため、匿名認証で始めてApple連携する
- [x] Apple連携はパートナー登録で行動した直後に必須。招待した側は共有を完了した直後
- [x] パートナー登録で「あとで」を選んだ人は匿名のまま未参加ホームへ入れる
- [x] ステップの並びは「ニックネーム → パートナー登録 → Apple連携 → 通知許可 → プラン紹介」
- [x] 未参加ホームのやることリストは未完了の項目だけ（パートナー登録・Apple連携）
- [x] 参加待ちの判定は端末に保存した最後の招待で行う
- [x] 放置された匿名アカウントは最終サインインから30日で削除する
- [x] 説明画面は3枚。招待リンクから来た人には招待者名を出す
- [x] ADR-0054の承認
- [x] Issueの起票（#461 / #462 / #463）

### Phase 2: 実装

**#461: 匿名認証とApple連携の基盤**

- [ ] Firebaseコンソールで匿名認証を有効にする（stg / prod）
- [x] `AccountAuthResult.isAnonymous`、`AccountAuthClient.signInAnonymously` / `linkWithApple`（liveValueを含む）
- [x] `AccountAuthStore`: 匿名で始める・連携・既存アカウントへの切り替え・匿名の退会
- [x] `LaunchState.accountLinkRequired`と`LaunchStateStore`の判定、`LoginContext.isAnonymous`
- [x] 共通のApple連携の画面（衝突時の確認を含む）
- [x] `RootView`: `.accountLinkRequired`で連携の画面を全画面で出す
- [x] 設定: 匿名のときのログアウトの置き換え・退会・招待発行後の連携
- [x] Paywallの各起点: 匿名なら先にApple連携
- [x] Functions: 匿名アカウントの掃除（定期実行）
- [x] Analytics: Apple連携のイベント、`is_anonymous`

**#462: 説明画面**

- [ ] 説明画面（3枚・「はじめる」・「すでにアカウントをお持ちの方」）
- [ ] `RootView`: `.notLoggedIn`で説明画面を出す
- [ ] 招待者名の表示、`fetchcohabitantinvitation`の未認証対応
- [ ] Analytics: 説明画面の画面イベント、匿名サインインの`login`

**#463: パートナー登録のステップとやることリスト**

- [ ] `OnboardingStep`の追加・並べ替えと、並びを決めるロジックの切り出し
- [ ] パートナー登録の選択肢画面（招待・P2P・招待された・あとで）、招待リンクから来た人の参加確認
- [ ] 最後に送った招待の保存（オンボーディング・同居人登録画面・設定の発行で保存、ログアウト・退会で削除）
- [ ] 未参加ホームのやることリスト（参加待ち・もう一度送る）
- [ ] Analytics: パートナー登録の選択、画面イベント
- [ ] Previewの追加・修正

### Phase 3: 検証

- [ ] `swift-code-verification`スキルに沿ってビルド・SwiftLint・ユニットテスト
- [ ] `make build-infra-package`
- [ ] Functionsのlint・E2Eテスト
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] シミュレータで確認（新規インストール → 招待を送る / P2P / あとで → やることリスト → 連携、既存のApple IDでの衝突）

### Phase 4: PR

- [ ] PR作成（`pr-create`スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- 既存実装（参考）:
  - `InfraPackage/Sources/AppRoot/RootView.swift`
  - `LocalPackage/Sources/HometeDomain/AppLaunch/LaunchStateStore.swift`
  - `LocalPackage/Sources/HometeDomain/Authentification/AccountAuthStore.swift`
  - `LocalPackage/Sources/Features/AuthFeature/Onboarding/OnboardingFlowView.swift`
  - `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/NotRegisteredContent.swift`
  - `LocalPackage/Sources/HometeUI/Components/Share/ShareSheet.swift`
  - `firebase/functions/src/cohabitantInvitation.ts`
  - `firebase/functions/src/deleteUserData.ts`
- 関連ADR: [ADR-0017](../adr/0017-create-cohabitant-on-invitation-join.md)、[ADR-0018](../adr/0018-deferred-deep-link-with-clipboard.md)
