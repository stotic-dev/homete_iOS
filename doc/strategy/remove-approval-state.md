# 承認ステータスの廃止 実装方針

> 関連Issue: [#292 承認のステータスはいらない](https://github.com/stotic-dev/homete_iOS/issues/292)
> ブランチ: `feat/remove-approval-state`

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] Firestoreデータのマイグレーション実行（stg / prod）
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

家事のステータスから「承認待ち（`pendingApproval`）」を廃止する。家事を終えたら相手の承認を待たずにそのまま「完了」になり、事実と違えば既存の「未完了に戻す」操作で取り消す。

承認フローは「片方が完了報告 → もう片方が確認」という2段階を全ての家事に強制しており、同居人同士の日常の家事管理としては重い。一方で「相手の家事に感謝を伝える」体験は残す価値があるため、ステータス遷移からは切り離し、**完了済みの家事に後から「ありがとう」を送れる機能**として再定義する。

## 要件

### 機能要件

#### ステータス

1. 家事のステータスは `incomplete` / `completed` / `notTodo` の3つにする（`pendingApproval` を削除）
2. 未完了の家事に対する「完了にする」操作で、その場で `completed` になる
   - 実行者（`executorId`）と実行日時（`executedAt`）は完了操作をした本人・操作時刻を記録する
   - 貢献度ポイントは従来どおり `completed` の家事を `executorId` ごとに集計するため、完了と同時に加算される
3. 完了した家事は「未完了に戻す」で `incomplete` に戻せる（既存の `returnToIncomplete` をそのまま使う）
4. 「承認依頼」「承認」「再確認依頼（差し戻し）」の操作は廃止する

#### 「ありがとう」を伝える

5. **自分以外が完了した家事**に対して「ありがとう」を送れる
   - 送信回数は制限しない（何度でも送れる）
   - 自分が完了した家事には導線を出さない
6. 導線は2箇所に置く
   - **家事詳細画面**: 完了済みの家事に「ありがとうを伝える」ボタン。タップで感謝メッセージ入力画面（現 `HouseworkApprovalView` を転用）を開き、自由文を添えて送る
   - **家事ボードのクイックアクション**: 完了タブのセル長押しメニュー・一括操作バーに「ありがとう」を並べ、定型文（`ありがとう！`）でワンタップ送信する
7. 「ありがとう」は家事のステータスを変えない。相手へのプッシュ通知のみを送る

#### 通知

8. 家事を完了にしたとき、同居人へ「完了を知らせる通知」を送る
9. 一括操作時は件数をまとめた通知を1件だけ送る（既存の方針を踏襲）
10. 「再確認してください」系の通知は廃止する

#### 画面

11. 家事ボードのセグメントは「未完了 / 完了」の2タブにする
12. セルのメタデータラベルから「要確認」「相手の確認待ち」を削除する

#### 既存データ

13. Firestoreに保存済みの `pendingApproval` の家事は、**使い捨てのNodeスクリプトで `completed` に書き換える**（stg → prod の順に実行）

### 非機能要件 / 制約

- 既存のDIパターン（`AppDependencies` 経由でClientを注入）を維持する
- プレゼンテーションロジックの置き場所は [.claude/rules/presentation-logic-placement.md](../../.claude/rules/presentation-logic-placement.md) に従う（末端コンポーネントは判断を持たない）
- ユーザー向け文言は [.claude/rules/ux-writing.md](../../.claude/rules/ux-writing.md) に従う
- VRTの参照スナップショットは Xcode Cloud で更新する。削除した `#Preview` に対応する古いPNGは `git rm` で落とす
- Analyticsイベントの変更は [doc/analytics_events.md](../analytics_events.md) に同じPRで反映する

## 設計方針

### 1. `HouseworkState` から `pendingApproval` を削除する

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkState.swift`

```swift
public enum HouseworkState: CaseIterable, Identifiable, Codable, Sendable {

    /// 未完了
    case incomplete
    /// 完了
    case completed
    /// やらない
    case notTodo

    public var id: Self { self }

}
```

**デコードの保険について**: `Firestore.Encoder` はenumをケース名の文字列で保存するため、`pendingApproval` のドキュメントが1件でも残っていると家事リスト全体のデコードが失敗する。マイグレーション（後述）で消しきるのが正だが、アプリのリリースとマイグレーション実行の間にズレが出ても壊れないよう、**未知の値を `.completed` にフォールバックする `init(from:)` を入れる**ことを提案する。

```swift
public init(from decoder: any Decoder) throws {
    let rawValue = try decoder.singleValueContainer().decode(String.self)
    // 廃止した`pendingApproval`など未知の値は完了として扱う（Issue #292）
    self = Self.allCases.first { "\($0)" == rawValue } ?? .completed
}
```

不要と判断する場合はこの節を削り、素のCodable準拠のままにする。

### 2. `HouseworkItem` の更新メソッドを整理する

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkItem.swift`

| 現在 | 変更後 |
|---|---|
| `updatePendingApproval(at:changer:)` | `updateCompleted(at:executor:)` — `state = .completed` / `executorId` / `executedAt` を設定 |
| `updateApproved(at:reviewer:comment:)` | 削除 |
| `updateRejected(at:reviewer:comment:)` | 削除 |
| `updateIncomplete()` | 変更なし |
| `updateNotTodo()` | 変更なし |

**プロパティの整理**: `reviewerId` / `approvedAt` / `reviewerComment` は承認フロー専用のフィールドで、アプリ内で表示している箇所はなく（プッシュ通知の本文に載せるだけ）、「ありがとう」は何度でも送れる仕様のため記録する必要もない。**3つとも削除する**。

`Firestore.Encoder` での書き込みは `merge: false` の全上書きのため、更新のたびに古いフィールドは自然に消える。デコード側は未知のフィールドを無視するので、移行期のドキュメントが残っていても問題ない。

> 将来「ありがとうをもらった回数」などを見せたくなった場合は、その時点で専用のフィールド（例: `thanksCount`）を設計する。意味の変わったフィールドを流用しない。

### 3. `HouseworkListStore` の操作を再編する

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift`

| 現在 | 変更後 |
|---|---|
| `requestReview(target:now:executor:cohabitantId:isRegistered:step:notify:)` | `complete(target:now:executor:cohabitantId:isRegistered:step:notify:)`<br>未登録のテンプレート家事はドキュメント新規作成、登録済みは更新（現行の分岐をそのまま踏襲）。通知は `completedMessage` |
| `approved(...)` | `sendThanks(target:sender:comment:cohabitantId:step:notify:)`<br>**Firestoreは更新せず**、プッシュ通知の送信とAnalyticsのログのみ |
| `rejected(...)` | 削除 |
| `returnToIncomplete(...)` | 変更なし |
| `remove(...)` | 変更なし |

`sendThanks` はデータを書き換えないが、通知送信とAnalyticsを一箇所に集約するため Store のメソッドとして持たせる（Viewから `CohabitantPushNotificationClient` を直接触らせない）。

### 4. プッシュ通知の内容を差し替える

`LocalPackage/Sources/HometeDomain/PushNotificationContent.swift`

| 現在 | 変更後 | 文言（案） |
|---|---|---|
| `requestReviewMessage(houseworkTitle:)` | `completedMessage(executorName:houseworkTitle:)` | title: `<名前>さんが家事を完了しました` / message: `「<家事名>」が完了しました` |
| `requestReviewBulkMessage(count:)` | `completedBulkMessage(executorName:count:)` | title: `<名前>さんが家事を完了しました` / message: `<N>件の家事が完了しました` |
| `approvedMessage(reviwerName:houseworkTitle:comment:)` | `thanksMessage(senderName:houseworkTitle:comment:)` | title: `<名前>さんから「<家事名>」にありがとうが届きました` / message: コメント |
| `approvedBulkMessage(reviwerName:count:)` | `thanksBulkMessage(senderName:count:)` | title: `<名前>さんからありがとうが届きました` / message: `<N>件の家事にありがとうが届きました` |
| `rejectedMessage(...)` / `rejectedBulkMessage(count:)` | 削除 | — |

`reviwerName` の綴り誤りは、この機会に `senderName` へ直す。

### 5. クイックアクションを組み替える

`LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkQuickAction.swift`

```swift
enum HouseworkQuickAction: Identifiable, Equatable, CaseIterable {

    /// 完了にする（未完了 → 完了）
    case complete
    /// やらない（未完了 → やらない）
    case remove
    /// ありがとう（完了済みの、自分以外が実施した家事へ送る）
    case sendThanks
    /// 未完了に戻す（完了 → 未完了）
    case returnToIncomplete

}
```

| ケース | ラベル | SF Symbol | 定型コメント |
|---|---|---|---|
| `complete` | 完了にする | `checkmark.circle.fill` | — |
| `remove` | やらない | `trash`（`.destructive`） | — |
| `sendThanks` | ありがとう | `hands.clap.fill` | `ありがとう！` |
| `returnToIncomplete` | 未完了に戻す | `arrow.uturn.backward` | — |

表示するアクションの決定:

```swift
static func actions(for item: HouseworkBoardItem, ownUserId: String) -> [Self] {
    switch item.state {
    case .incomplete:
        [.complete, .remove]

    case .completed:
        // 自分が完了した家事に自分でありがとうを送れてしまわないようにする
        item.executorId == ownUserId ? [.returnToIncomplete] : [.sendThanks, .returnToIncomplete]

    case .notTodo:
        []
    }
}
```

`HouseworkBoardItem.canReview(ownUserId:)` は承認可否の判定なので、「ありがとうを送れるか」を表す `canSendThanks(ownUserId:)` に置き換える（`executorId != ownUserId && state == .completed`）。

まとめ通知（`bulkNotification`）は `complete` と `sendThanks` のみが対象。`remove` / `returnToIncomplete` は従来どおり通知しない。

### 6. 家事ボードを2タブにする

`LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/HouseworkBoardSegmentedControl.swift`

```swift
static var pageableCases: [HouseworkState] {
    [.incomplete, .completed]
}
```

空表示の理由（`HouseworkBoardEmptyReason`）は承認前提のケースを畳んで次の3つにする。

| ケース | 条件 | 表示 |
|---|---|---|
| `noHouseworkRegistered` | 家事が1件も登録されていない | 現行どおり（家事登録の導線） |
| `allCompleted` | 未完了タブ: 全て完了・やらないに移行済み | 「今日の家事は全部終わっています」 |
| `hasIncompleteHousework` | 完了タブ: 完了した家事がまだない | 「未完了を見る」で未完了タブへ切り替え |

削除するケース: `allCompletedOrPending` / `noPendingApproval(hasIncomplete:)` / `canReviewPendingApproval` / `allPendingApprovalByOthers`

### 7. セルのメタデータを整理する

`LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkItemMetaData.swift`

`needsOwnReview` / `waitingForOtherReview` を削除し、`completed` / `notTodo` の2ケースにする。`incomplete` は従来どおり `nil`（補う情報がない）。

### 8. 感謝メッセージ画面（現 `HouseworkApprovalView`）を転用する

`HouseworkApproval/` → `HouseworkThanks/` にディレクトリごとリネームし、`HouseworkThanksView` とする。

| 箇所 | 現在 | 変更後 |
|---|---|---|
| ナビゲーションタイトル | 家事の確認 | ありがとうを伝える |
| 見出し | `<名前>さんから「<家事名>」の完了報告が届きました` | `<名前>さんが「<家事名>」を完了しました` |
| 入力欄プレースホルダ | 感謝を伝えましょう！ | 変更なし |
| ボタン | 「完了にする」「再確認してもらう」の2つ | 「ありがとうを伝える」1つ |
| 送信処理 | `houseworkListStore.approved(...)` | `houseworkListStore.sendThanks(...)` |

`AppScreen.houseworkApproval`（`housework_approval`）は `houseworkThanks`（`housework_thanks`）にリネームする。

### 9. 家事詳細のアクションを組み替える

`LocalPackage/Sources/Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailActionContent.swift`

| 家事の状態 | 表示するボタン |
|---|---|
| `incomplete` | 「完了にする」 |
| `completed`（自分以外が実施） | 「ありがとうを伝える」（`HouseworkThanksView` をfullScreenCover）+「未完了に戻す」 |
| `completed`（自分が実施） | 「未完了に戻す」 |
| `notTodo` | なし |

### 10. 当日サマリーの集計から承認待ちを外す

`LocalPackage/Sources/Features/HouseworkFeature/Model/TodayHouseworkSummary.swift`

- 未完了の抽出を `$0.state == .incomplete` のみにする
- 表示順の比較関数からステータス比較を落とし、ポイント降順 → ID順にする
- ドキュメントコメントの「`incomplete` + `pendingApproval`」の記述も直す

### 11. Analyticsイベントを更新する

`LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift`

| 現在 | 変更後 | `step` |
|---|---|---|
| `requestReview(step:isSuccess:)` | `complete(step:isSuccess:)` → `action: "complete"` | `dashboard` / `board` / `detail` |
| `approve(isSuccess:)` | `sendThanks(step:isSuccess:)` → `action: "send_thanks"` | `board` / `detail` / `thanks` |
| `reject(isSuccess:)` | 削除 | — |

`HouseworkAnalyticsStep.approval`（`approval`）は `thanks` にリネームする。「ありがとう」はボードのクイックアクションからも送れるため、`approve` のように固定値にせず `step` を受け取る形にする。

[doc/analytics_events.md](../analytics_events.md) の以下を同じPRで更新する。

- `screen_view` の画面一覧: `housework_approval` → `housework_thanks`
- `housework` イベントの `action` 一覧と説明（`request_review` / `approve` / `reject` を削除し、`complete` / `send_thanks` を追加）
- 「`request_review` → `approve` / `reject` の比率が承認フローの指標になる」という分析観点の記述を削除する

### 12. Firestoreデータのマイグレーション

使い捨てのNodeスクリプトを `firebase/functions/scripts/migratePendingApproval.ts` に置き、手元から `stg` → `prod` の順で実行する。

- 対象パス: `Cohabitant/{cohabitantId}/Houseworks/{houseworkId}`（`FirestoreExtensionForReferencePath.swift` 参照）
- `collectionGroup("Houseworks").where("state", "==", "pendingApproval")` で抽出し、`state` を `"completed"` に更新する
- 併せて `reviewerId` / `approvedAt` / `reviewerComment` を `FieldValue.delete()` で落とす（不要フィールドの掃除。任意）
- 500件ずつ `WriteBatch` でコミットする
- `--dry-run` で件数のみ出力できるようにし、まず件数を確認してから本実行する
- `--project` の指定間違いを防ぐため、プロジェクトIDを必須の引数にして起動時にログへ出す（`homete-ios-dev` が本番、`-e3ef7` 付きがSTG）

実行順序は **「マイグレーション実行 → アプリのリリース」**。旧バージョンのアプリは `completed` のデータを問題なく読めるため、先に流しても実害はない。

スクリプトは実行後もリポジトリに残し、ファイル冒頭に「Issue #292 対応の一度きりのスクリプト。実行済み」と明記する。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 修正 | `HometeDomain/Cohabitant/Housework/HouseworkState.swift` | `pendingApproval` 削除 / デコードのフォールバック |
| 修正 | `HometeDomain/Cohabitant/Housework/HouseworkItem.swift` | 更新メソッドとreviewer系フィールドの整理 |
| 修正 | `HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | `complete` / `sendThanks` への再編 |
| 修正 | `HometeDomain/PushNotificationContent.swift` | 完了通知・ありがとう通知への差し替え |
| 修正 | `HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift` | `complete` / `send_thanks` |
| 修正 | `HometeDomain/AnalyticsLog/AppScreen.swift` | `housework_thanks` |
| 修正 | `HometeDomain/Utilities/DebugHelper/HouseworkItemHelper.swift` | プレビュー用ヘルパーの引数追従 |
| 修正 | `Features/HouseworkFeature/Model/HouseworkQuickAction.swift` | アクションの再定義 |
| 修正 | `Features/HouseworkFeature/Model/HouseworkListStore+QuickAction.swift` | 実行の振り分け |
| 修正 | `Features/HouseworkFeature/Model/HouseworkBoardItem.swift` | `canReview` → `canSendThanks` |
| 修正 | `Features/HouseworkFeature/Model/HouseworkSelection.swift` | 承認前提のコメント・判定の追従 |
| 修正 | `Features/HouseworkFeature/Model/HouseworkBoardEmptyReason.swift` | 空表示の理由を3ケースに |
| 修正 | `Features/HouseworkFeature/Model/HouseworkItemMetaData.swift` | 確認待ちラベルの削除 |
| 修正 | `Features/HouseworkFeature/Model/TodayHouseworkSummary.swift` | 未完了判定・並び順 |
| 修正 | `Features/HouseworkFeature/HouseworkBoardView/SubViews/*` | 2タブ化・空表示・クイックアクション・一括操作バー |
| 修正 | `Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailActionContent.swift` | ボタン構成 |
| リネーム | `Features/HouseworkFeature/HouseworkApproval/` → `HouseworkThanks/` | 感謝メッセージ画面へ転用 |
| 修正 | `Features/HouseworkFeature/IncompleteHouseworkListView/IncompleteHouseworkListView.swift` | Previewの追従 |
| 修正 | `Features/HomeFeature/.../TodayHouseworkSummaryComponent.swift` | Previewの追従 |
| 新規 | `firebase/functions/scripts/migratePendingApproval.ts` | 既存データの書き換え |
| 修正 | `doc/analytics_events.md` | イベント定義の追従 |
| 修正 | `doc/strategy/today-housework-summary.md` / `housework_template.md` | 承認前提の記述の追従 |

## タスク

### Phase 1: 設計確定

- [x] 承認ステータスを廃止し、完了 → 取り消しの運用にする
- [x] 「ありがとう」は完了済みの他人の家事へ何度でも送れる（詳細画面 + ボードのクイックアクション）
- [x] 完了時に同居人へプッシュ通知を送る
- [x] 家事ボードは「未完了 / 完了」の2タブ
- [x] 既存データは使い捨てのNodeスクリプトで `completed` に書き換える
- [x] `HouseworkState` のデコードにフォールバックを入れる（未知のケースは完了として扱う）
- [x] `reviewerId` / `approvedAt` / `reviewerComment` を削除する
- [x] 通知・ボタンの文言を確定する

### Phase 2: 実装

コミットは対応単位で分ける（[.claude/rules/git-commit.md](../../.claude/rules/git-commit.md)）。

- [x] ドメイン層: `HouseworkState` / `HouseworkItem` / `HouseworkListStore` の再編（通知・Analytics定義を含む）
- [x] クイックアクションと家事ボード（2タブ化・空表示・メタデータ）の対応
- [x] 家事詳細・感謝メッセージ画面の対応
- [x] 当日サマリー・未完了リストの対応
- [x] ユニットテストの追従・追加
- [x] マイグレーションスクリプトの追加
- [x] ドキュメント更新（`doc/analytics_events.md` ほか）
- [x] 削除した `#Preview` に対応する参照スナップショットの `git rm`

### Phase 3: 検証

- [x] `make build-local-package` でビルド通過
- [x] SwiftLint 通過（`swift-code-verification` スキル）
- [x] `make test-packages` 通過（5ターゲット / 423テスト）
- [x] `make check-previews` 通過
- [ ] シミュレータで簡易E2E確認（完了 → ありがとう送信 → 未完了に戻す）
- [ ] VRTの参照スナップショット更新をXcode Cloudで確認

### Phase 4: リリース

- [ ] PR作成（`pr-create` スキル）・Danger / CI通過・レビュー対応・マージ
- [ ] マイグレーションスクリプトを `stg` でdry-run → 本実行
- [ ] STGビルドで動作確認
- [ ] マイグレーションスクリプトを `prod` でdry-run → 本実行
- [ ] App Storeへリリース

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/292
- 既存実装（参考）:
  - `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkQuickAction.swift`
  - `LocalPackage/Sources/Features/HouseworkFeature/HouseworkApproval/HouseworkApprovalView.swift`
  - `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift`
  - `firebase/functions/src/syncHouseworkRetention.ts`（admin SDKでの家事ドキュメント操作）
- 関連ドキュメント:
  - [doc/analytics_events.md](../analytics_events.md)
  - [doc/strategy/today-housework-summary.md](today-housework-summary.md)
  - [ADR-0009 Analyticsイベントのパラメータ設計](../adr/0009-analytics-event-parameter-design.md)
