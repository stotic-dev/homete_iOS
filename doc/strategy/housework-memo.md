# 家事メモ 実装方針

> 関連Issue: [#353 Feature: 家事にメモを追加できるようにする](https://github.com/stotic-dev/homete_iOS/issues/353)
> ブランチ: `feat/housework-memo`
> 関連Issue: [#330 Firebase Remote Config による強制アップデート](https://github.com/stotic-dev/homete_iOS/issues/330)
> ADR: [ADR-0033 家事メモの文字数上限はクライアントで判定する](../adr/0033-housework-memo-limit-on-client.md)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

家事に任意項目のメモ（自由記述のテキスト＋チェックリスト）を持たせる。「買い物」の家事に買う物をチェックリストで書いておき、買ったものからチェックを付ける、といった補足情報を家事そのものに残せるようにし、チャットなどに散らばっていた情報を家事を見るだけで分かるようにする。

## 要件

### 機能要件

Issueの決定事項（2026-10-01）に、方針整理で決めた事項（2026-10-03）を加えたもの。

- 家事を追加する画面（`ManualHouseworkForm`）でメモを入力できる。保留リスト（`PendingEntry` / `RegisterHouseworkDraft`）にもメモを保持する。
- 家事詳細画面（`HouseworkDetailView`）でメモを表示し、あとから入力・編集できる。
  - チェックリストのチェックは、タップした時点で保存する。
  - テキストと項目の追加・削除・名前の変更は、編集シートで行い「保存」で保存する。
- 編集できるのは未完了の家事だけ。完了済み・「やらない」の家事は閲覧のみ（チェックも変えられない）。
- 同居グループのメンバーなら誰でも編集できる。メモの追加・更新では同居人に通知しない。
- 家事ボードの行（`HouseBoardListRow`）に「メモあり」のアイコンを出す。本文は詳細画面で見る。
- 「もう一度やる」（`makeRedone`）で作る家事は元の家事のメモを引き継ぐ。チェック状態もそのまま引き継ぐ。
- 家事テンプレート（毎週・毎月）にメモを持たせ、テンプレートから作られる家事に引き継ぐ。
- いつもの家事（`FrequentHouseworkItem`）にメモを持たせ、そこから追加した家事に引き継ぐ。
- 文字数上限: テキストとチェックリストの項目名の**合計**で数える。
  - 無料プラン: 200文字
  - プレミアムプラン: 5,000文字（実質上限なし。1MiB制限を守るための安全上限）
  - チェックリストの項目数: プランに関係なく100項目まで
- 無料プランで上限を超えると保存ボタンを無効にし、「プレミアムプランなら5,000文字まで書けます」の文言とペイウォールへの導線を出す。
- 保持期限（`expiredAt`）を過ぎたら家事と一緒にメモも消える（既存のTTLのまま）。

### 非機能要件 / 制約

- **上限の判定はクライアントで行う**（ADR-0033）。プランは自分の購読状態（`SubscriptionStore.isPremium`）で判定する。判定するのは「メモを編集して保存するとき、上限を超えていて、かつ編集前より文字数が増えている場合」だけ。テンプレート・いつもの家事からのコピーや完了などの状態変更では判定しない。
  - これにより、プレミアムの同居人が書いた長いメモのテンプレートから無料の同居人が家事を作っても失敗しない。ダウングレード後も、チェックを付ける・文字を減らす編集はできる。
- **Firestoreルールはプランに依存しない検査だけ**を置く（安全上限と、旧アプリによる消失の拒否）。
- **旧アプリでの上書きによる消失は許容しない**。ルールで「既存ドキュメントに`memo`があるなら、更新後も`memo`が残っていること」を必須にする。旧アプリはメモ付きの家事を操作するとエラーになる。#330には依存させない。
- Codableは後方互換にする（`memo`の無い既存ドキュメントは「メモなし」として読む）。
- `HouseworkItem`の状態変更メソッドはすべてメモを引き継ぎ、テストで担保する。

## 設計方針

### 1. ドメインモデル

新規: `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkMemo.swift`

```swift
public struct HouseworkMemo: Codable, Sendable, Equatable, Hashable {

    public let text: String
    public let checklist: [HouseworkMemoChecklistItem]

    public static let empty = HouseworkMemo(text: "", checklist: [])

    /// 文字数上限の判定に使う文字数。テキストとチェックリストの項目名の合計
    public var characterCount: Int {
        text.count + checklist.reduce(0) { $0 + $1.title.count }
    }

    public var isEmpty: Bool { text.isEmpty && checklist.isEmpty }

    /// チェックを切り替えたメモを返す
    public func toggled(_ itemId: HouseworkMemoChecklistItem.ID) -> Self
}

public struct HouseworkMemoChecklistItem: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let isChecked: Bool
}
```

`HouseworkItem` / `HouseworkTemplateItem` / `FrequentHouseworkItem` に `memo: HouseworkMemo?` を足す。

- `nil`: メモを一度も書いていない（ドキュメントに`memo`フィールドが無い）
- `.empty`: 書いたメモを消した
- 表示上の「メモあり」は `memo.map { !$0.isEmpty } ?? false`（`hasMemo`として生やす）

`nil`と`.empty`を分けるのは、旧アプリ対策のルール（後述）のため。メモを消したときに`memo`フィールドごと消すと「`memo`が残っていること」に反して拒否される。かといって常に`memo`を書くと、メモを一度も使っていない家事まで旧アプリから操作できなくなる。そのため「書いたことがある家事だけ`memo`を持ち、以後は空でも消さない」にする。エンコードは`encodeIfPresent`。

### 2. 文字数上限

新規: `HometeDomain/Cohabitant/Housework/HouseworkMemoLimitPolicy.swift`（`FrequentHouseworkLimitPolicy`と同じ形）

```swift
public enum HouseworkMemoLimitPolicy: Sendable, Equatable {
    case free
    case premium

    public init(isPremium: Bool)

    /// 文字数の上限（無料200 / プレミアム5,000）
    public var maxCharacterCount: Int
    /// チェックリストの項目数の上限（共通100）
    public static let maxChecklistItemCount = 100

    /// 編集前のメモから編集後のメモへの保存を許すか
    /// 上限を超えていても、編集前より文字数・項目数が増えていなければ許す
    public func canSave(_ memo: HouseworkMemo, original: HouseworkMemo?) -> Bool
}
```

### 3. HouseworkItem の状態変更

`updateCompleted` / `makeRedone` / `updateIncomplete` / `updateNotTodo` / `updateCreatedAt` のすべてで`memo`を引き継ぐ。メモの更新メソッドを追加する。

```swift
/// メモを更新する。未完了の家事だけ編集できる
public var canEditMemo: Bool { state == .incomplete }

public func updateMemo(_ memo: HouseworkMemo) -> Self  // 状態は変えない。呼び出し側でcanEditMemoを確認
```

テンプレート（`HouseworkTemplateDay.applyTemplate` / 毎月の生成）といつもの家事からの生成で`memo`をコピーする。`HouseworkTemplateMonthlyItem`のカスタムCodableにも`memo`を足す。

### 4. 保存処理（Store / Client）

`HouseworkListStore.updateMemo(target:memo:cohabitantId:isRegistered:)` を追加する。

- 登録済みの家事: `HouseworkClient`に`updateMemo(itemId:memo:cohabitantId:)`を足し、`FirestoreService`の`updateData([fieldPath: ...])`で`memo`フィールドだけを書く。完了など他の操作と同時に起きても、互いの変更を巻き戻さないため。
- 未登録の家事（テンプレートから表示しているだけの家事）: 他の操作と同じく`insertOrUpdate`でドキュメントごと作る（`createdAt`付き）。
- 同居人には通知しない。
- チェックの切り替えも同じメソッドで保存する。保存に失敗したらエラーを表示し、画面の状態は購読しているドキュメントの値に戻す。

テンプレート・いつもの家事は、既存の保存処理がドキュメント全体を書くのでClientの変更は不要。テンプレートの編集ロック・競合検知は`HouseworkTemplateDraft`の`Equatable`で判定しているので、`HouseworkTemplateItem`に`memo`を足せば自動で対象に入る。

### 5. View

| 画面 | 変更 |
|---|---|
| 共通コンポーネント | `HometeUI`にメモの編集シート `HouseworkMemoEditSheet`（テキストエディタ＋チェックリストの追加・削除・並べ替え、残り文字数、上限超過時の文言とペイウォールへのボタン）と、表示用の `HouseworkMemoContent`（テキスト＋チェック可能なリスト、閲覧専用モードあり）を置く。家事・テンプレート・いつもの家事の3機能から使うため |
| 家事追加 | `ManualHouseworkForm`に「メモ」行を足し、タップで編集シート。`PendingEntry` / `RegisterHouseworkDraft`にメモを持たせる。いつもの家事から追加した家事はメモをコピー |
| 家事詳細 | `HouseworkDetailItemListContent`の下にメモのセクション。未完了なら「編集」ボタンとチェック操作、完了済み・「やらない」なら閲覧のみ。メモが無い未完了の家事には「メモを追加」ボタン |
| 家事ボードの行 | `HouseBoardListRow`のタイトル横に「メモあり」アイコン（SF Symbol `note.text`）とアクセシビリティラベル |
| テンプレート編集 | `HouseworkTemplateItemEditModal`にメモ行 |
| いつもの家事の編集 | いつもの家事の追加・編集画面にメモ行 |

完了時のコメント入力（`HouseworkCommentInputContent`）のテキスト入力UIを参考にする。ペイウォールの出し方は`FrequentHouseworkManagementScreen`の`isShowPaywall`に揃える。

### 6. Firestoreルール

`Houseworks` / `HouseworkTemplates/*/MonthlyItems` / `FrequentHouseworks` の`create, update`に次を足す。

```
// メモはプランに関係なく一律の安全上限だけを検査する。プランごとの上限はクライアントで判定する（ADR-0033）
function isValidMemo(data) {
  return !('memo' in data)
    || (
      data.memo is map
      && data.memo.text is string
      && data.memo.text.size() <= 20000
      && data.memo.checklist is list
      && data.memo.checklist.size() <= 100
    );
}

// 旧バージョンのアプリは`memo`を知らずにドキュメント全体を上書きするため、メモが消える更新を拒否する
function keepsMemo() {
  return !('memo' in resource.data) || 'memo' in request.resource.data;
}
```

- `text`の安全上限はクライアントの5,000文字より大きく取る。Swiftの`count`（書記素クラスタ）とルールの`size()`では絵文字などの数え方が違うため。
- チェックリストの項目名の長さはルールでは検査しない（配列を走査できない）。1MiB制限で頭打ちになる。
- 毎週のテンプレート（`Days`）には置かない（家事を配列で持つため検査できない）。旧アプリが保存し直すとその曜日のメモがすべて消える残存リスクは、#330で最低バージョンを引き上げて塞ぐ（ADR-0033）。
- `firebase/functions/test/rules/firestore.rules.test.ts`にテストを足す（安全上限の境界、`memo`の削除拒否、`memo`の無いドキュメントは従来どおり更新できること）。

### 7. Analytics

`HouseworkAnalyticsAction`に`editMemo(step:isSuccess:)`を足す。チェックの切り替えは送らない（頻度が高く、メモの利用状況を見るにはテキスト・項目の保存で足りるため）。`doc/analytics_events.md`を更新する。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkMemo.swift` | メモの型 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkMemoLimitPolicy.swift` | 文字数・項目数の上限 |
| 修正ドメイン | `.../Housework/HouseworkItem.swift` | `memo`、引き継ぎ、`updateMemo`、Codable |
| 修正ドメイン | `.../HouseworkTemplate/HouseworkTemplateItem.swift` / `HouseworkTemplateMonthlyItem.swift` / `HouseworkTemplateDay.swift` | `memo`と生成時のコピー |
| 修正ドメイン | `.../FrequentHousework/FrequentHouseworkItem.swift` / `FrequentHouseworkInput.swift` | `memo` |
| 修正Store | `.../Housework/HouseworkListStore.swift` | `updateMemo` |
| 修正Client | `HometeDomain/Dependencies/HouseworkClient.swift` / `HometeInfrastructure`の実装 | `updateMemo` |
| 修正Analytics | `HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift` | `editMemo` |
| 新規View | `LocalPackage/Sources/HometeUI/Components/HouseworkMemo/` | 編集シート・表示コンポーネント |
| 修正View | `Features/HouseworkFeature/RegisterHouseworkView/SubViews/ManualHouseworkForm.swift`、`Model/PendingEntry.swift`、`Model/RegisterHouseworkDraft.swift` | 追加時の入力 |
| 修正View | `Features/HouseworkFeature/HouseworkDetailView/` | 表示・編集 |
| 修正View | `Features/HouseworkFeature/HouseworkBoardView/SubViews/HouseBoardListRow.swift` | 「メモあり」 |
| 修正View | `Features/HouseworkTemplateFeature/EditModal/HouseworkTemplateItemEditModal.swift` | テンプレートのメモ |
| 修正View | `Features/FrequentHouseworkFeature/EditModal/` | いつもの家事のメモ |
| 修正ルール | `firebase/firestore.rules` | 安全上限・消失の拒否 |
| 修正テスト | `firebase/functions/test/rules/firestore.rules.test.ts` | ルールのテスト |
| 修正ドキュメント | `doc/analytics_events.md` | `editMemo` |

## タスク

### Phase 1: 設計確定

- [x] 文字数の数え方 → テキストと項目名の合計
- [x] プランごとの上限の判定場所 → クライアント。ルールは安全上限だけ（ADR-0033）
- [x] 旧アプリ対策 → ルールで`memo`の消失を拒否する。#330には依存させない
- [x] 毎週のテンプレート（`Days`）→ ルールでは検査しない（残存リスクは#330で塞ぐ）
- [x] プレミアムの上限 → 5,000文字、項目数100（ルールの安全上限はテキスト20,000文字・項目数100）

### Phase 2: 実装

- [ ] Domain: `HouseworkMemo` / `HouseworkMemoLimitPolicy` とテスト
- [ ] Domain: `HouseworkItem`に`memo`（Codable後方互換、全状態変更での引き継ぎ、`canEditMemo` / `updateMemo`）とテスト
- [ ] Domain: テンプレート（毎週・毎月）といつもの家事に`memo`、生成時のコピーとテスト
- [ ] Client / Store: `HouseworkClient.updateMemo`、`HouseworkListStore.updateMemo`とテスト
- [ ] Analytics: `editMemo`と`doc/analytics_events.md`
- [ ] View: `HometeUI`のメモ編集シート・表示コンポーネント
- [ ] View: 家事追加画面・保留リスト
- [ ] View: 家事詳細画面
- [ ] View: 家事ボードの行の「メモあり」
- [ ] View: テンプレート編集・いつもの家事の編集
- [ ] Firestoreルールとルールのテスト
- [ ] 追加・変更した画面のPreview

### Phase 3: 検証

- [ ] `swift build` でビルド通過
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] ユニットテスト実行（追加分含む）通過
- [ ] `npm run test:rules` 通過
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] 実機/シミュレータで動作確認

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ
- [ ] リリース前: #330で最低バージョンを引き上げるまでの間、毎週のテンプレートのメモが旧アプリで消えうることをリリース判断に含める

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/353
- 既存実装（参考）:
  - `LocalPackage/Sources/HometeDomain/Cohabitant/FrequentHousework/FrequentHouseworkLimitPolicy.swift`（プランごとの上限）
  - `LocalPackage/Sources/Features/HouseworkFeature/Components/HouseworkCommentInputContent.swift`（テキスト入力UI）
  - `LocalPackage/Sources/Features/FrequentHouseworkFeature/Management/FrequentHouseworkManagementScreen.swift`（ペイウォールの出し方）
  - `doc/adr/0023-housework-multiple-executors-with-allocated-points.md`（旧アプリの上書きと後方互換デコード）
