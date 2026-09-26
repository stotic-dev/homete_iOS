# 家事完了時の担当者選択 実装方針

> 関連Issue: [#291 家事の完了をリクエストする時に担当者を選択できるようにする](https://github.com/stotic-dev/homete_iOS/issues/291)
> ブランチ: `claude/issue-291-review-tnrw5a`
> データモデルの選定経緯: [ADR-0022](../adr/0022-housework-multiple-executors-with-allocated-points.md)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

家事を「完了にする」ときに、担当者（実行者）を選べるようにする。自分以外や複数人も選べる。家事をしてもアプリで完了にしない人の分を、他の人が代わりに記録できるようにするのと、2人以上で手分けした家事のポイントを割合で分けられるようにするのが目的。

あわせて、完了とありがとうの入力画面をハーフモーダルにそろえる。完了時のコメント入力は、一度入れたが不要と判断して外した。

Issue起票時点では承認フローがあったため「承認依頼」と書かれているが、[#292](remove-approval-state.md)で承認は廃止済み。本対応では「完了にする」操作に担当者の選択を追加する。

## 要件

### 機能要件

#### 担当者の選択

1. 「完了にする」をタップすると、**完了用のハーフモーダル**（担当者の設定だけ）を出す
   - 表示元は、家事詳細の「完了にする」と、**クイックアクション（長押しメニュー）の「完了にする」（1件）**
   - 同居人グループのメンバーを複数選べる。初期状態では自分だけ選んでおく
   - 自分を外して、他の人だけを担当者にしてもよい
   - 選択が0人のときは「完了にする」を押せない
   - コメント欄は置かない
2. **複数選択の一括完了は今までどおり**、自分だけを担当者（配分100%）にして即完了にする
3. 完了済みの家事の担当者を後から変える機能は、今回は入れない（未完了に戻して、完了にし直せば変えられる）

#### ポイントの配分

4. 担当者が2人以上のときは、家事のポイントを担当者で分ける
5. デフォルトは均等割り。担当者のチェックを変えるたびに均等割りをやり直す
   - 割り切れない分は、メンバー一覧の並び順（自分が先頭）で前の人から1%ずつ足す（例：3人なら 34 / 33 / 33%）
6. オプションで割合を調整できる
   - 「配分を調整する」は閉じた状態を初期表示にする。担当者が1人のときは出さない
   - 単位は%。ピッカーで1%刻み（1〜99%）に選ぶ
   - 2人のときは、片方を変えるともう片方が自動で `100 - x` になる
   - 3人以上のときは他の人の%を自動では変えない。合計が100%になるまで「完了にする」を押せず、「合計 90 / 100%」のように表示する
7. 保存時に%をポイントへ換算する（最大剰余方式）
   - 全員分を切り捨ててから、余ったポイントを小数部分が大きい人から順に1ptずつ配る
   - 小数部分が同じ人がいる場合は、メンバー一覧の並び順が早い人を優先する
   - 全員のポイントの合計は、常に家事のポイントと一致する
8. **0ptの担当者は許さない**
   - 換算して誰かが0ptになる配分では「完了にする」を押せず、「全員が1pt以上になるように配分してください」と表示する
   - 家事のポイントより多い人数は選べない（1ptの家事は1人まで、2ptなら2人まで）。上限に達したら残りのメンバーのチェックを無効にする
   - 家事のポイントの入力範囲は1〜100ptなので、0ptの家事は通常は存在しない。旧データなどで0ptの家事があった場合は完了用ハーフモーダルから完了にできない（一括完了からは完了にできる）

#### 表示

9. 家事詳細の「実施者」欄は「担当者」に名前を変え、担当者全員を並べて表示する。担当者が2人以上なら、名前と%・ポイントを表示する（例：`自分 60%（6pt）`）
10. 貢献度（`ContributionFeature`）と今日のサマリー（`TodayHouseworkSummary`）は、担当者ごとに配分されたポイントで集計する。達成件数は担当者1人につき1件と数える
11. 「ありがとう」は、担当者に自分以外が1人でも含まれていれば送れる

#### ありがとうの画面

12. 家事詳細の「ありがとうを伝える」と、クイックアクションの「ありがとう」（1件）は、今のフルスクリーン表示（`HouseworkThanksView`）をやめて、**完了用と同じ見た目のハーフモーダル**に変える
    - 中身はコメント欄だけ。送信はナビゲーションバー右側のハートのアイコンボタンで行う。家事の内容（`HouseworkItemPropertyListContent`）や「◯◯さんが〜終えてくれました」のセクションは出さない
    - コメントは今までどおり必須
    - 担当者の設定は出さない
13. 複数選択の一括操作の「ありがとう」は今までどおり、定型文でワンタップ送信する（家事ごとにメッセージを書く手間をかけさせないため）

#### ハーフモーダル共通

14. 高さは中身に合わせる（`.medium` だと中身に対して余白が大きすぎたため）。配分の調整を開いたりメッセージが複数行になったりして中身が増えると、シートも伸びる。画面に収まらないときは最大の高さになり、中身をスクロールできる

#### 通知

15. 担当者が自分だけのときは、今までどおりの完了通知（「◯◯さんが家事を終えました」）を送る
16. 担当者に自分以外が含まれるときは、代わりに記録したことが分かる文言にする
    - タイトル：`◯◯さんが家事の完了を記録しました`
    - 本文：`「洗濯」（担当：Bさん・Cさん）`
    - 通知の送り先（自分以外の同居人全員）は変えない
17. 完了時にコメントを入力したときは、本文の末尾に改行してコメントを付ける
18. **コメントを入力した完了は、毎回通知を送る**（ADR-0021の「1日1回」の対象外にする）
    - ふりかえり通知の予約用データ（`HouseworkCompletedNotificationData`）は、今までどおり「今日の家事で、その日まだ送っていない」ときだけ付ける
    - コメントなしの完了は、今までどおり1日1回だけ送る
    - コメントは「ありがとう」と同じく、ユーザーが明示的に送ったメッセージなので、送る回数を絞る対象から外す
    - 注：完了のハーフモーダルからコメント欄を外したため、17・18の処理は今どの画面からも使われていない

### 非機能要件 / 制約

- **旧バージョンのアプリと共存させる**。マイグレーションは行わない
  - 書き込むときは `executorId` に1人目の担当者も入れる。旧アプリは `executorId` しか読まないため、複数人で担当した家事は1人目に満額が付いて見えるが、表示が少しずれるだけで壊れはしないので許容する
  - `executors` が無い古いドキュメントは、`executorId` の人に100%（満額）を配分したものとして読む
  - `insertOrUpdate` は `setData(merge: false)` で全体を上書きする。旧アプリが書き込むと `executors` は消えるが、新アプリは `executorId` から補って読むので矛盾しない
- Firestoreルール・Cloud Functionsは変更しない（Houseworksのフィールドを検証しておらず、`executorId` も参照していないため）
- ポイントの配分計算はドメイン層の純粋な関数にして、ユニットテストで固定する

## 設計方針

### 1. ドメインモデル：`HouseworkExecutor` を追加する

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkExecutor.swift`（新規）

```swift
public struct HouseworkExecutor: Codable, Sendable, Hashable {
    public let userId: String
    /// 画面に出す割合。担当者全員の合計が100
    public let percentage: Int
    /// 集計に使うポイント。担当者全員の合計が家事のポイントと一致し、1以上
    public let point: Int
}
```

`HouseworkItem`（修正）

```swift
/// 担当者。完了していない家事では空
public let executors: [HouseworkExecutor]
/// 旧バージョンのアプリ向けに残す。1人目の担当者を書く
public let executorId: String?
```

- デコードは `init(from:)` を自前で実装する。`executors` が無ければ、`executorId` から `[.init(userId: executorId, percentage: 100, point: point)]` を組み立てる
- エンコードでは `executorId` に `executors.first?.userId` を書く
- `updateCompleted(at:executor:)` は `updateCompleted(at:executors:)` に置き換える。`updateIncomplete()` では `executors` を空にする

### 2. 配分ロジック：`HouseworkExecutorAllocation`

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkExecutorAllocation.swift`（新規）

```swift
public struct HouseworkExecutorAllocation: Equatable, Sendable {
    /// メンバー一覧の並び順で並べた担当者のIDと割合
    public private(set) var entries: [(userId: String, percentage: Int)]
    public let totalPoint: Int

    /// 均等割り。割り切れない分は先頭から1%ずつ足す
    public static func even(userIds: [String], totalPoint: Int) -> Self
    /// 2人のときはもう片方を 100 - x にする。3人以上では他の人を変えない
    public mutating func updatePercentage(_ percentage: Int, for userId: String)
    /// 最大剰余方式でポイントへ換算する
    public var points: [String: Int] { get }
    public var validationError: HouseworkExecutorAllocationError? { get }  // .empty / .percentageNotHundred(sum) / .zeroPoint
    public func makeExecutors() -> [HouseworkExecutor]?  // 不正ならnil
    /// 選べる人数の上限（= totalPoint）
    public static func maxExecutorCount(totalPoint: Int) -> Int
}
```

- 担当者の並び順は `CohabitantMemberList.value` の順に合わせる（自分が先頭）。均等割りの端数と、最大剰余方式で小数部分が同じだったときの優先順は、どちらもこの順で決める

### 3. Store：`HouseworkListStore.complete`

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift`

```swift
public func complete(
    target: HouseworkItem,
    now: Date,
    operator: Account,               // 操作した人（通知の送り主）
    executors: [HouseworkExecutor],  // 担当者
    comment: String?,                // 完了通知に添えるコメント（任意）
    cohabitantId: String,
    isRegistered: Bool,
    step: HouseworkAnalyticsStep,
    notify: Bool = true
) async throws
```

- 引数に `comment: String?` を追加する。空文字は `nil` として扱う
- 通知は `executors` が「自分だけ」かどうかで `completedMessage` と `proxyCompletedMessage`（新規）を使い分ける。担当者名の解決には `CohabitantMemberList` が要るため、担当者名の配列を引数で受け取る
- 一括完了（`performBulk`）は、自分に100%を配分した1件の `executors` を渡し、コメントなしで呼ぶ

### 3-1. 完了通知の送り方（`DailyCompletionReminderUseCase`）

`LocalPackage/Sources/HometeDomain/UseCase/DailyCompletionReminderUseCase.swift`

コメントの有無で送る条件を分ける。

| | 今日の家事で、その日まだ送っていない | それ以外 |
|---|---|---|
| コメントなし | 予約用データ付きで送る（今までどおり） | 送らない（今までどおり） |
| コメントあり | 予約用データ付きで送る | **予約用データなしで送る**（新規） |

- `notifyCompletedIfNeeded` に「必ず送るかどうか」の引数を足すか、予約用データを `Optional` にして送る関数を分ける。どちらにするかは実装時に決める
- 予約用データを付けたときだけ「その日送った」を記録する。コメントのために予約用データなしで送ったときは記録しない

### 4. UI：完了用ハーフモーダル

`LocalPackage/Sources/Features/HouseworkFeature/HouseworkComplete/HouseworkCompleteSheet.swift`（新規）

```
(×)          完了にする            (✓)
担当者
 ☑ 自分        34%  4pt
 ☑ Bさん       33%  3pt
 ☑ Cさん       33%  3pt
─────────────
 ▾ 配分を調整する
     自分  [ 34% ▾ ]
     Bさん [ 33% ▾ ]
     Cさん [ 33% ▾ ]
     合計 100 / 100%
 （エラー表示）
```

- 家事詳細の「完了にする」（`HouseworkDetailActionContent`）と、クイックアクションの「完了にする」（`HouseworkQuickActionMenuContent`）から `.sheet` で表示する。確定したら `houseworkListStore.complete` を呼んでシートを閉じる
- クイックアクションは `.contextMenu` の中身なので、そこから直接シートは出せない。メニューで「完了にする」を選んだら、対象の家事を親View（家事ボード・ダッシュボード）の `@State` に渡して `.sheet(item:)` で表示する。そのため `HouseworkQuickActionMenuContent` に、完了を選んだことを親に伝えるクロージャを追加する
- %のピッカーは、既存の `PointWheelPickerField` と同じホイール形式で、`1...99` の範囲にする。共通化できそうなら `HometeUI` に `PercentageWheelPickerField` として切り出す
- 状態は `HouseworkExecutorAllocation` を `@State` で持つ。判定は全部ドメイン側で行い、Viewは結果を表示するだけにする（`presentation-logic-placement` ルール）
- `NavigationStack` で包み、タイトル「完了にする」をナビゲーションバーに出す。leadingにキャンセル（`NavigationBarButton(label: .close)`）、trailingに完了のアイコンボタン（`NavigationBarPrimaryActionButton(systemImage: "checkmark")`）を置く。配分にエラーがあるときは完了ボタンを押せない
- 高さは `HometeUI` の `ContentFittingSheetScrollView` で中身に合わせる。`ScrollView` の代わりに使うと、中身の高さにナビゲーションバーと下端のセーフエリアを足した `.height` のデテントを設定する。キーボードの分のセーフエリアは足さない（キーボードを出すたびにシートが伸びてしまうため）

### 4-1. UI：ありがとう用ハーフモーダル

`LocalPackage/Sources/Features/HouseworkFeature/HouseworkThanks/HouseworkThanksView.swift`（修正）

```
        ありがとうを伝える           (♥)
メッセージ
 [ 感謝を伝えましょう！              ]
```

- `HouseworkDetailActionContent` からの表示を `.fullScreenCoverOnIOS` から `.sheet` に変える
- 家事ボードのクイックアクションで「ありがとう」を選んだときも、完了と同じく `HouseworkQuickActionMenuContent` のクロージャ（`onSelectThanks`）で親に伝え、`.sheet(item:)` で表示する。ダッシュボードは未完了の家事だけを並べるので、ありがとうは選ばれない
- 高さは完了用と同じく `ContentFittingSheetScrollView` で中身に合わせる
- 中身はコメント欄だけにする。家事の内容と「◯◯さんが〜終えてくれました」のセクションを削除する。閉じるボタンは置かない（ドラッグで閉じられるため）
- 送信ボタンはナビゲーションバーのtrailingにハートのアイコン（`NavigationBarPrimaryActionButton(systemImage: "heart.fill")`）で置く。タイトル「ありがとうを伝える」はナビゲーションバーに出し、コメント欄の見出しは「メッセージ」にする
- コメント欄は `HouseworkCommentInputContent` を使う
- スクリーン計測（`.trackScreenView(.houseworkThanks)`）はそのまま残す

### 5. 集計・表示の置き換え

| 対象 | 変更前 | 変更後 |
|---|---|---|
| `HouseworkContribution.make` | `executorId` ごとにグループ化し、`point` を合計 | `executors` を展開し、担当者ごとの `point` を合計。件数は1人1件 |
| `TodayHouseworkSummary.memberContributions` | 同上 | 同上 |
| `HouseworkBoardItem.canSendThanks` | `executorId != ownUserId` | `executors` に自分以外が含まれる |
| `HouseworkDetailItemListContent` | 実施者1人の名前 | 担当者全員。2人以上なら%とポイントも |

### 6. Analytics

`housework` イベントの `complete` に `executor_type` パラメータを追加する。`doc/analytics_events.md` も更新する。

| 値 | 意味 |
|---|---|
| `self` | 自分だけが担当者 |
| `others` | 自分以外だけが担当者（代わりに記録した） |
| `shared` | 自分を含む複数人が担当者 |

完了操作のうち代わりに記録した割合・手分けした割合を見て、この機能が使われているかを判断する指標にする。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkExecutor.swift` | 担当者と配分済みの割合・ポイント |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkExecutorAllocation.swift` | 均等割り・%の調整・ポイントへの換算・検証 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkItem.swift` | `executors` の追加、旧データとの互換デコード |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | `complete` に担当者を渡す |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/PushNotificationContent.swift` | 代わりに記録したときの通知文言 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift` | `executor_type` の追加 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkBoardItem.swift` | `canSendThanks` の判定 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/TodayHouseworkSummary.swift` | 担当者ごとの集計 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkListStore+QuickAction.swift` | 自分だけに100%で完了 |
| 修正Model | `LocalPackage/Sources/Features/ContributionFeature/Model/HouseworkContribution.swift` | 担当者ごとの集計 |
| 修正UseCase | `LocalPackage/Sources/HometeDomain/UseCase/DailyCompletionReminderUseCase.swift` | コメントありの完了は毎回送る |
| 新規View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkComplete/HouseworkCompleteSheet.swift` | 完了用ハーフモーダル（担当者の設定） |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/HouseworkQuickActionMenuContent.swift` | 「完了にする」「ありがとう」（1件）を親に伝えてハーフモーダルを出す |
| 修正View | 家事ボード・ダッシュボードのクイックアクション呼び出し元 | 完了用・ありがとう用（家事ボードのみ）のハーフモーダルを `.sheet(item:)` で表示 |
| 新規View（任意） | `LocalPackage/Sources/HometeUI/Components/Picker/PercentageWheelPickerField.swift` | %のホイールピッカー |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailActionContent.swift` | 完了用・ありがとう用のハーフモーダルを `.sheet` で表示 |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailItemListContent.swift` | 担当者全員の表示 |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkThanks/HouseworkThanksView.swift` | コメント欄だけのハーフモーダルにする |
| 新規View | `LocalPackage/Sources/HometeUI/Components/Sheet/ContentFittingSheetScrollView.swift` | 中身の高さに合わせてシートの高さを決める |
| ドキュメント | `doc/analytics_events.md` | `executor_type` の追加 |

## タスク

### Phase 1: 設計確定

- [x] 承認廃止後の「完了にする」に担当者の選択を追加する
- [x] 配分はデフォルトで均等割り、オプションで%を調整できる（1%刻みのピッカー）
- [x] 均等割りの端数はメンバー一覧の並び順で前の人に付ける
- [x] 自分を含めず、他人だけを担当者にできる
- [x] 0ptの担当者は許さない（確定させない／人数の上限を家事のポイントにする）
- [x] 3人以上のときは他の人の%を自動で変えず、合計100%になるまで確定させない
- [x] 担当者を後から変える機能は入れない
- [x] 「完了にする」（家事詳細・クイックアクション1件）は、担当者の設定のハーフモーダルを出す
- [x] 一括完了は、コメントなし・自分だけに100%で即完了のまま
- [x] ありがとう（家事詳細・クイックアクション1件）はコメント欄だけのハーフモーダルにする。一括操作のありがとうは定型文のまま
- [x] 完了・ありがとうのハーフモーダルの高さを中身に合わせる
- [x] コメントありの完了は、1日1回の条件に関係なく毎回通知を送る
- [x] データモデルは割合とポイントの両方を担当者ごとに保存する（ADR-0022）

### Phase 2: 実装

- [x] `HouseworkExecutor` と `HouseworkItem.executors`（旧データとの互換デコード・`executorId` との二重書き込み）＋テスト
- [x] `HouseworkExecutorAllocation`（均等割り・%の調整・最大剰余方式・検証）＋テスト
- [x] `HouseworkListStore.complete` の引数変更（担当者・コメント）と、代わりに記録したときの通知文言＋テスト
- [x] `DailyCompletionReminderUseCase`：コメントありの完了は毎回送る＋テスト
- [x] 一括完了の呼び出しを追従させる
- [x] 貢献度・今日のサマリーの集計を担当者ごとに変える＋テスト
- [x] `canSendThanks` の判定変更＋テスト
- [x] 完了用ハーフモーダル（`HouseworkCompleteSheet`）とPreview
- [x] 家事詳細・クイックアクション（1件）から完了用ハーフモーダルを表示
- [x] ありがとう画面をコメント欄だけのハーフモーダルにする＋Preview
- [x] 家事詳細の担当者表示とPreview
- [x] Analyticsの `executor_type` 追加と `doc/analytics_events.md` の更新

### Phase 3: 検証

- [ ] `swift build` でビルド通過
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] ユニットテスト実行（追加分含む）通過
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] 実機/シミュレータで動作確認（詳細から自分だけ・クイックアクションから他人だけ・3人で配分調整の3パターン）

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/291
- ADR: [ADR-0022](../adr/0022-housework-multiple-executors-with-allocated-points.md)
- 既存実装（参考）:
  - `doc/strategy/remove-approval-state.md`
  - `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkState.swift`（未知の値を安全に読むカスタムデコードの前例）
  - `LocalPackage/Sources/HometeUI/Components/Picker/PointWheelPickerField.swift`
