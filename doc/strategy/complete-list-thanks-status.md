# 完了リストの担当者・ありがとう状況の表示 実装方針

> 関連Issue: [#314 家事ボードの完了リストで担当者とありがとうができていないところをぱっと見でわかるようにしたい](https://github.com/stotic-dev/homete_iOS/issues/314)
> ブランチ: `feat/314-complete-list-metadata`
> 保存先の判断: [ADR-0025](../adr/0025-store-housework-thanks-in-housework-document.md)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

家事ボードの完了リストの各行に、**誰が終えたか**と、**自分がありがとうを送ったか**（自分が終えた家事なら**ありがとうを受け取ったか**）を表示する。どの家事にまだありがとうを伝えていないかを、一覧を見ただけで分かるようにする。

今の「ありがとう」はプッシュ通知を送るだけで、送ったという記録がどこにも残らない。そのため表示の前提として、ありがとうを家事ドキュメントに記録する。

## 要件

### 機能要件

#### 表示（家事ボードの完了リストのみ）

1. 完了リストの各行に、担当者（`executors`のユーザー名）を表示する。複数人で担当した家事は「たろうさん・はなこさん」のように「・」でつなぐ（グループを抜けた人は出さない）
2. ありがとうの状況は、見ている本人の目線で出し分ける

   | 家事の担当者 | 自分の送信状況 / 受信状況 | 表示 |
   |---|---|---|
   | 自分以外を含む | まだ送っていない | 未送信（`heart`） |
   | 自分以外を含む | 送った | 送信済み（赤ピンクの`heart.fill`） |
   | 自分だけ | 誰からも届いていない | 何も出さない |
   | 自分だけ | 1人以上から届いた | 受け取った（`heart.fill` + 「ありがとうが届きました」） |

   - 自分を含む複数人で担当した家事は、他の担当者へありがとうを送れる（[ADR-0023](../adr/0023-housework-multiple-executors-with-allocated-points.md)）ため、届いた状況より自分が送ったかどうかを出す

3. ホームの今日のサマリーと未完了一覧の行は、今と同じ表示のまま（担当者も、ありがとうの状況も出さない）
4. 家事詳細に、届いたありがとうを「誰から」とメッセージで送られた順に並べる。メッセージなしのありがとうは「ありがとう！」と出す（グループを抜けた人の分は出さない）

#### ありがとうの記録

5. ありがとうを送ると、家事ドキュメントに「誰が・どのコメントで・いつ送ったか」を記録する
6. 同じ人が同じ家事に送れるありがとうは1回まで。送った後は、コメントの編集だけできる
7. コメントは200文字まで。入力欄に文字数を表示し、超えたら文字数を警告色にして送れなくする（日本語の変換中の文字が消えないよう、入力そのものは切り詰めない）
8. 家事を未完了に戻したら、その家事のありがとうの記録は消す。完了にしたときも、前の完了に届いた記録は引き継がない（未完了に戻した直後に、表示が古いままの端末から書き込まれた分を残さないため）
   - 「もう一回やった」は別IDの家事として作られるので、最初から記録なしになる
   - ありがとうの画面を開いている間に未完了へ戻された家事には記録しない。判断はリスナーで受け取った手元の最新の状態で行い、サーバーの家事と突き合わせる確認まではしない

#### 導線

9. 完了リストの未送信のハートをタップすると、メッセージなしでありがとうを伝える（複数選択中はタップできない）
   - 送信済みの家事では、ありがとうのアクションを出さない
   - 行の長押しメニュー（クイックアクション）: 「ありがとう」を出さない
   - 複数選択の一括操作バー: 送信済みの家事は、未送信の家事と行えるアクションが違うため一緒に選べない（既存の`HouseworkSelection.isSelectable`の仕組みで自然にそうなる）。送信済みだけを選んだときは、ありがとうボタンが出ない
   - 家事詳細: 「ありがとうを伝える」の代わりに「送ったメッセージを編集」を出す
10. 「送ったメッセージを編集」をタップすると、送ったコメントを入れた状態で`HouseworkThanksView`を開く。コメントなしで送っていた場合は、ボタンを「メッセージを添える」にして空欄で開く
11. 送信済みの家事にコメントなしのありがとうが届いても（表示がリスナーに追いつく前の操作など）、記録を上書きしない

#### 通知

12. コメントなしのありがとう（ハートのタップ・一括操作）では、Push通知を送らない
    - 行のクイックアクション（1件）は、mainの変更（#308）でメッセージを入力するハーフモーダルを出すようになったため、詳細画面と同じくコメント付きで送る
    - 固定コメント「ありがとう！」（`HouseworkQuickAction.fixedComment`）と、一括のまとめ通知（`thanksBulkMessage`）は廃止する
13. コメント付きで送ったとき（詳細画面から送る）は、今と同じ`thanksMessage`のPush通知を送る
14. 編集したときは、**コメントが初めて付いたときだけ**Push通知を送る（コメントなしで送った後に書き足したとき）。書いてあるコメントを直しただけでは送らない

### 非機能要件 / 制約

- 保存先は家事ドキュメントのフィールドにする（サブコレクションにしない）。判断の経緯は[ADR-0025](../adr/0025-store-housework-thanks-in-housework-document.md)
- 既存の家事ドキュメントには`thanks`フィールドがないため、読むときに無ければ空として扱う（データの移行はしない）
- ありがとうの書き込みは、ドキュメント全体を上書きする`insertOrUpdate`ではなく、`thanks.<送った人のID>`のフィールドだけを更新する。2人が同時に送っても、互いの記録を消さないため
- Firestoreのセキュリティルールは変更しない（既存の`Houseworks`の`update`ルールで書き込める）
- プレゼンテーションロジックの置き場所は`.claude/rules/presentation-logic-placement.md`、文言は`.claude/rules/ux-writing.md`に従う
- Analyticsの意味が変わるため、`doc/analytics_events.md`を同じPRで更新する

## 設計方針

### 1. ドメインモデル: `HouseworkThanks`と`HouseworkItem.thanks`

新規 `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkThanks.swift`

```swift
/// 完了した家事に届いた「ありがとう」の記録
public struct HouseworkThanks: Equatable, Sendable, Hashable, Codable {

    /// コメントの最大文字数
    public static let commentMaxLength = 200

    /// 添えたコメント。一括操作から送った場合は`nil`
    public let comment: String?
    /// 最初に送った日時（コメントを編集しても変えない）
    public let sentAt: Date
}
```

`HouseworkItem`に送った人のIDをキーにした辞書を足す。

```swift
/// 届いたありがとう（キーは送った人のユーザID）
public let thanks: [String: HouseworkThanks]
```

- Firestoreのドキュメントは`thanks: { "<userId>": { comment, sentAt } }`の形になる
- 既存のドキュメントを読めるよう、`init(from:)`を自前で実装し`decodeIfPresent(...) ?? [:]`にする
- `updateIncomplete()`は`thanks: [:]`にする。`makeRedone`も`[:]`。`updateCompleted` / `updateNotTodo`は引き継ぐ（`updateCompleted`は未完了から呼ばれるので実質は空）
- 初期化子に`thanks: [String: HouseworkThanks] = [:]`を足し、既存の呼び出し元は変えずに済むようにする

### 2. Client / Service: フィールド単位の更新

`HometeInfrastructure/Firestore/FirestoreService.swift`に、指定フィールドだけを更新するメソッドを足す。

```swift
public func update(fields: [String: Any], predicate: (Firestore) -> DocumentReference) async throws {
    try await predicate(firestore).updateData(fields)
}
```

`HometeDomain/Dependencies/HouseworkClient.swift`にありがとうを書き込むクロージャを足し、live実装は`AppRoot/Dependency/Impl/ImplHouseworkClient.swift`に置く。

```swift
public let upsertThanks: @Sendable (
    _ houseworkId: String,
    _ senderId: String,
    _ thanks: HouseworkThanks,
    _ cohabitantId: String
) async throws -> Void
```

live実装は`Firestore.Encoder`で`HouseworkThanks`を辞書にしてから`["thanks.\(senderId)": encoded]`で`update(fields:)`を呼ぶ。

### 3. Store: `HouseworkListStore.sendThanks`

`HometeDomain/Cohabitant/Housework/HouseworkListStore.swift`

```swift
/// 完了した家事に「ありがとう」を記録し、コメントが初めて付いたときだけ相手に通知する
///
/// 送信済みの家事に対して呼ぶと、コメントの編集になる（最初に送った日時は変えない）。
public func sendThanks(
    target: HouseworkItem,
    sender: Account,
    comment: String?,
    now: Date,
    cohabitantId: String,
    step: HouseworkAnalyticsStep
) async throws
```

- 書き込み内容: `HouseworkThanks(comment: comment, sentAt: target.thanks[sender.id]?.sentAt ?? now)`
- 通知の判定: `comment != nil && target.thanks[sender.id]?.comment == nil` のときだけ`thanksMessage`を送る
  - 初めてコメント付きで送った場合も、コメントなしで送った後に書き足した場合も同じ条件で拾える
- 書き込み → 通知の順に待ち、失敗は呼び出し元に返す（今と同じく、画面側でエラーを出す）
- `notify`引数は不要になるので削除する

### 4. クイックアクション・一括操作

`Features/HouseworkFeature/Model/HouseworkQuickAction.swift`、`HouseworkListStore+QuickAction.swift`

- `fixedComment`を削除し、`perform(.sendThanks)`は`comment: nil`で呼ぶ
- `bulkNotification`から`.sendThanks`を外す。残る全ケースが`nil`になるなら関数ごと削除し、`performBulk`の呼び出しも消す
- `PushNotificationContent.thanksBulkMessage`を削除する
- `actions(for:ownUserId:)`は`item.canSendThanks(ownUserId:)`で出し分けている。`canSendThanks`に「未送信であること」を足すだけで、長押しメニュー・一括選択の両方から送信済みの家事のありがとうが消える

### 5. プレゼンテーション: 行に出す情報

`Features/HouseworkFeature/Model/HouseworkBoardItem.swift`に判定を足す。

```swift
/// 自分がすでにありがとうを送ったか
public func hasSentThanks(ownUserId: String) -> Bool

/// ありがとうを伝えられるかどうか（自分以外が終えた完了済みの家事で、まだ送っていない）
public func canSendThanks(ownUserId: String) -> Bool

/// 自分が送ったありがとう（編集画面の初期値に使う）
public func sentThanks(ownUserId: String) -> HouseworkThanks?
```

行に出すありがとうの状況は、新規の`HouseworkThanksStatus`（`Features/HouseworkFeature/Model/`）で表す。

```swift
enum HouseworkThanksStatus: Equatable {
    /// 自分以外が終えた家事に、まだ送っていない
    case notSent
    /// 自分以外が終えた家事に、送った
    case sent
    /// 自分が終えた家事に、ありがとうが届いた
    case received

    /// 完了済みでない、または自分が終えて誰からも届いていないときは`nil`
    static func make(item: HouseworkBoardItem, ownUserId: String) -> Self?
}
```

`HouseBoardListRow`には、完了リストのときだけ渡す任意のパラメータを足す。ほかの2画面は今のまま`nil`を渡す（引数の既定値`nil`）。

```swift
/// 完了リストでだけ出す、担当者とありがとうの状況
struct CompletionInfo: Equatable {
    let executorNames: [String]
    let thanksStatus: HouseworkThanksStatus?
}
```

- 担当者名は`HouseworkBoardListContent`で`\.cohabitantMembers`の`userName(_:)`から担当者ごとに引いて渡す（詳細画面と同じ取り方）
- 行は受け取った値を並べるだけにし、判断は持たせない
- `HouseworkThanksStatus`は状況だけを表し、アイコン・色・添える文言・VoiceOverの読み上げは`HouseBoardListRow`が決める（`.claude/rules/ui-attributes-in-view.md`）
- 見た目: 今のメタデータ（「完了」ラベル）の位置に担当者名を出し、行の右端にありがとうの状況のアイコンを出す。未送信は目立つよう輪郭のハート、送信済みは赤ピンク（`thanksHeart`）の塗りのハート、受け取り済みはアクセント色の塗りのハート
- 未送信のハートは、セルのタップ（詳細への遷移）とは別に反応するボタンにする。タップできるかは`HouseworkBoardListContent`が決めて`onTapThanks`で渡す

### 6. 詳細画面・ありがとう画面

- `HouseworkDetailItemListContent`: 「ありがとう」の項目に、`HouseworkThanksMessage.make(item:memberList:)`で組み立てた送った人とコメントを並べる。コメントなしで送られたありがとうは`comment`が`nil`で届き、View側で「ありがとう！」と出す

- `HouseworkDetailActionContent`: `hasSentThanks`なら「送ったメッセージを編集」ボタンを出し、同じ`HouseworkThanksView`を開く
- `HouseworkThanksView`
  - 初期値として送ったコメントを受け取る（`initialComment: String?`）。編集時はタイトル・ボタンの文言を編集用に切り替える
  - 入力欄の下に文字数を出し、200文字を超えたら警告色にして送れなくする（入力は切り詰めない。数えるのは前後の空白・改行を除いた文字数）
  - 送信ボタンはナビゲーションバーのハートアイコン（mainの変更に合わせる）。空欄のとき、上限を超えたとき、編集で内容を変えていないときは押せない

### 7. Analytics

- `send_thanks`は「Firestoreへの記録」の結果を表すように意味を変える（今は通知の送信結果）
- 編集を区別するため、`HouseworkAnalyticsAction`に`editThanks`（`edit_thanks`）を足す。起点は`detail`経由の`thanks`
- `doc/analytics_events.md`の該当行と注記を更新する

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkThanks.swift` | ありがとうの記録 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkItem.swift` | `thanks`の追加、デコード・エンコード、完了・未完了にするときに消す |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | `sendThanks`の記録・通知条件 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/PushNotificationContent.swift` | `thanksBulkMessage`の削除 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift` | `editThanks`の追加 |
| 修正Client | `LocalPackage/Sources/HometeDomain/Dependencies/HouseworkClient.swift` | `upsertThanks`の追加 |
| 修正live実装 | `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplHouseworkClient.swift` | フィールド単位の更新 |
| 修正Service | `LocalPackage/Sources/HometeInfrastructure/Firestore/FirestoreService.swift` | `update(fields:predicate:)`の追加 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkBoardItem.swift` | 送信済み判定 |
| 新規Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkThanksStatus.swift` | 行に出す状況 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkQuickAction.swift` | 固定コメント・一括通知の削除 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkListStore+QuickAction.swift` | コメントなしで送る |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/HouseBoardListRow.swift` | 担当者・ありがとうの状況の表示 |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/HouseworkBoardListContent.swift` | 完了リストで`CompletionInfo`を組み立てて渡す |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailActionContent.swift` | 編集ボタン |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkThanks/HouseworkThanksView.swift` | 初期値・文字数上限・編集モード |
| ドキュメント | `doc/analytics_events.md` | `send_thanks`の意味、`edit_thanks`の追加 |

## タスク

### Phase 1: 設計確定

- [x] 表示の目線は「自分が送ったか」。自分が終えた家事は「受け取った」を出す
- [x] 保存先は家事ドキュメントのフィールド（ADR-0025）
- [x] コメントは200文字まで
- [x] 未完了に戻したらありがとうの記録を消す
- [x] 1人1家事1回まで。送った後は編集のみ。送信済みではありがとうのアクションを出さない
- [x] コメントなしのありがとうではPush通知を送らない。編集時はコメントが初めて付いたときだけ送る
- [x] ホームのサマリー・未完了一覧は変えない

### Phase 2: 実装

- [x] `HouseworkThanks`の追加と`HouseworkItem.thanks`（デコード・未完了で消す）
- [x] `FirestoreService.update(fields:predicate:)`と`HouseworkClient.upsertThanks`（live / preview）
- [x] `HouseworkListStore.sendThanks`の記録・通知条件の変更
- [x] クイックアクション・一括操作から固定コメントとまとめ通知を削除し、送信済みを除外
- [x] `HouseworkThanksStatus`と`HouseBoardListRow`の表示、完了リストからの受け渡し
- [x] 詳細画面の「送ったメッセージを編集」と`HouseworkThanksView`の編集モード・文字数上限
- [x] Analytics（`edit_thanks`）と`doc/analytics_events.md`の更新
- [x] Previewの追加・修正（行の未送信 / 送信済み / 受け取った、ありがとう画面の編集）

### Phase 3: 検証

- [x] `swift build` でビルド通過
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過
- [x] ユニットテスト実行（追加分含む）通過
  - `HouseworkItem`: `thanks`のない既存データを読める / 未完了に戻すと消える / もう一回やったは空
  - `HouseworkBoardItem` / `HouseworkThanksStatus`: 表の4パターン
  - `HouseworkQuickAction.actions`: 送信済みでは`.sendThanks`が出ない
  - `HouseworkListStore.sendThanks`: 初回コメント付き → 通知あり / コメントなし → なし / なし→あり の編集 → あり / あり→あり の編集 → なし / 編集で`sentAt`が変わらない
  - 一括ありがとう: 通知を送らない
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] 実機/シミュレータで動作確認（完了リストの表示、送信 → 送信済みに変わる、編集）

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/314
- ADR: [ADR-0025 家事のありがとうを家事ドキュメントに記録する](../adr/0025-store-housework-thanks-in-housework-document.md)
- 既存実装（参考）:
  - `LocalPackage/Sources/Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailItemListContent.swift`（担当者名の引き方）
  - `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkItemMetaData.swift`（行のメタデータ）
  - `doc/strategy/remove-approval-state.md`（ありがとう機能を定義した方針）
