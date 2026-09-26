# いつもの家事 実装方針

> 関連Issue: [#283 よくやる家事を登録して今後簡単に登録できるようにする](https://github.com/stotic-dev/homete_iOS/issues/283)
> ブランチ: `claude/issue-283-ux-review-ilai9i`
>
> 「いつもの家事」を独立featureとし、呼び出し時にコピーする方式を採用した経緯は [ADR-0020](../adr/0020-frequent-housework-as-independent-copy-source.md) を参照。

## ステータス

- [x] 要件確定
- [x] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

よくやる家事を「いつもの家事」として同居人グループで共有して登録しておき、単発の家事登録とテンプレートの家事追加の両方から呼び出せるようにする。
あわせて、家事登録シートを「いつもの家事 | 新しく入力」の2タブにし、複数の家事をまとめて登録できるようにする。

毎回の入力の手間を減らし、同じ家事のポイントを同居人の間で揃えることが目的。

---

## 要件

### 用語

| 用語 | 意味 |
|---|---|
| いつもの家事 | 名前・ポイント・カテゴリを持つ、家事の「コピー元」。同居人グループで共有する。コード上の名前は `FrequentHousework` |
| 選ぶ部品 | いつもの家事をカテゴリで絞り込んでチップで並べる部品。登録シートとテンプレートの追加モーダルに埋め込む |
| 登録予定リスト | 登録シートで、まとめて登録する前にためておく家事の一覧 |

### 機能要件

#### いつもの家事（データ）

- 持つ情報は **名前・ポイント・カテゴリ（任意）**
- 同居人グループで共有する（Firestore）
- グループ内で**同じ名前は登録できない**（前後の空白を除いて比較）
- 呼び出したときは中身を**コピー**する。いつもの家事自体は管理画面で編集しない限り変わらない。呼び出し先で名前やポイントを変えても、いつもの家事には反映しない

#### カテゴリ

- プリセット: **掃除・洗濯・料理・買い物・ゴミ**（この順で固定。名前の変更・削除はできない）
- ユーザーはカスタムカテゴリを追加できる（グループで共有。件数の制限なし）
  - 名前の変更・削除・並べ替えができる
  - 名前は空にできず、プリセット・「その他」・既存のカスタムカテゴリと重複できない
- 「**その他**」はデータとしては持たない、表示するときだけの区分
  - カテゴリ未設定の家事、または削除済みのカテゴリを指している家事を「その他」として表示する
  - そのため、カテゴリを削除しても家事側は書き換えない
  - 絞り込み・セクションでは常に一番最後に出す
- カテゴリの表示順: プリセット（固定順）→ カスタム（並べ替え順）→ その他

#### 無料プランの上限

- 無料プランで登録できるいつもの家事は、**グループ全体で10件まで**
- 上限の判定には、**操作している本人のプラン**を使う（プレミアムはアカウント単位で、グループ単位の概念がないため）
- 上限に達した状態で追加しようとしたら、案内のアラートを出してPaywallへ誘導する
  - 対象の操作: 管理画面の追加、「いつもの家事に保存する」、テンプレートからの取り込み
- プレミアムから無料に戻って上限を超えている場合、**表示順で11件目以降は使えなくする**
  - 選ぶ部品ではグレーアウトして選べないようにする
  - 管理画面では編集・削除・並べ替えはできる（残したい10件を並べ替えで選べるようにする）
  - 表示順は「カテゴリの表示順 → カテゴリ内の並び順」
- カスタムカテゴリの追加は制限しない

#### 家事登録シート（単発登録）

対象: `HouseworkBoardView` と `TodayHouseworkSummaryComponent` から開く `RegisterHouseworkView`。

```
┌ [キャンセル]      家事を追加              ┐
│  [ いつもの家事 | 新しく入力 ]              │ ← タップでもスワイプでも切り替え
│                                            │
│ (いつもの家事タブ)                   [管理] │
│ [すべて][掃除][洗濯][料理][買い物][ゴミ]… → │ ← 横スクロール（タブのスワイプより優先）
│ [布団干し 20pt ✓][換気扇 30pt ✓][風呂 10pt] │ ← タップで選択／解除（複数可）
│                                            │
│ (新しく入力タブ)                            │
│ 家事の名前 [                    ]           │
│ ポイント [10]   カテゴリ [その他（未設定）]  │ ← カテゴリは保存チェック時のみ意味を持つ
│ □ いつもの家事に保存する                     │
│ [続けて入力する]                            │
│ 入力履歴  洗濯 / 掃除 / …                   │
├────────────────────────────────┤
│ 登録予定 3件  布団干し・換気扇・ゴミ出し   ⌃ │ ← 両タブ共通。タップで一覧を開き取り消せる
│                          [3件登録する]      │
└────────────────────────────────┘
```

- **タブ**
  - 「いつもの家事」「新しく入力」の2タブ。上部の切り替えのタップでも、左右スワイプでも切り替えられる
  - カテゴリの横スクロール領域では横スクロールを優先し、それ以外の領域でのスワイプはタブの切り替えにする
  - 最初に開くタブ: いつもの家事が1件以上あれば「いつもの家事」、0件なら「新しく入力」
- **いつもの家事タブ**
  - 選ぶ部品を表示する。チップのタップで選択／解除（複数選択可）
  - 選んだ家事は登録予定リストに入る
  - 0件のときは「いつもの家事を登録しませんか？」と管理画面を開くボタンだけを表示する
  - 「管理」ボタンで管理画面を開く
- **新しく入力タブ**
  - 家事の名前・ポイント・カテゴリ・「いつもの家事に保存する」チェック
  - カテゴリの選択肢は、チェックがオンのときだけ操作できる（家事自体はカテゴリを持たないため）
  - 「**続けて入力する**」: 入力内容を登録予定リストに入れ、フォームを初期値（名前は空、ポイント10、カテゴリ未設定、チェックはオフ）に戻す。名前が空のときは押せない
  - 入力履歴は今までどおり。タップすると名前欄に入る
  - 「いつもの家事に保存する」は、次の場合は操作できないようにし、理由を添える
    - 同じ名前のいつもの家事がすでにある →「同じ名前のいつもの家事があります」
    - 上限に達している → タップすると上限の案内アラート（Paywall誘導）
- **登録予定リスト**
  - シートの下部に常に表示する。件数と家事名の要約を出し、タップで一覧を開いて1件ずつ取り消せる
  - 件数には「選択中のいつもの家事」「続けて入力で追加した家事」「新しく入力タブで入力中の家事（名前が空でなければ）」を含める
  - 登録予定リストの中では**ポイントを変更できない**（取り消しだけ）
- **N件登録する**
  - 登録予定リストの家事をまとめて登録する。0件のときは押せない
  - **同じ名前の家事の重複登録は許容する**（同じ家事を1日に2回やることがあるため）。既存の重複チェックとアラートは削除する
  - 同居人へのプッシュ通知は**1通にまとめる**（1件なら家事名、複数なら「布団干し ほか2件」）
  - 「いつもの家事に保存する」がオンの家事は、家事の登録に成功したあとでいつもの家事にも保存する
  - 家事の登録に失敗したら、シートは閉じずに共通エラーを表示する（登録予定リストは保持する）
  - いつもの家事への保存だけ失敗した場合は、シートを閉じたうえでエラーアラートで伝える（家事は登録済みのため）
- **キャンセル**
  - ナビゲーションバーの左に「キャンセル」を置く
  - 登録予定が0件かつ新しく入力タブの名前が空ならそのまま閉じる。そうでなければ「入力した内容を破棄しますか？」の確認を出す
  - 入力がある間は下スワイプでは閉じられないようにする（`interactiveDismissDisabled`）

#### テンプレートの家事追加モーダル

対象: `HouseworkTemplateItemEditModal`。

- **新規追加のとき**は「いつもの家事 | 新しく入力」の2タブにする（切り替え方と最初に開くタブの決め方は登録シートと同じ）
  - いつもの家事タブでは**1件だけ**選べる。選ぶと「新しく入力」タブに移り、名前・ポイントが入った状態になる → 曜日を選んで決定
  - 新しく入力タブには「いつもの家事に保存する」チェックを置く（仕様は登録シートと同じ）。モーダルの「決定」のタイミングでいつもの家事に保存する
    - テンプレート自体の保存（編集画面の「保存」）より前に確定する点に注意。テンプレートの編集をキャンセルしても、いつもの家事は保存されたまま
- **既存項目を編集するとき**はタブを出さず、今までどおりフォームだけにする
- 閉じるボタン: 入力が初期状態から変わっていれば破棄の確認を出す（新規・編集とも）

#### いつもの家事の管理画面

```
┌ [閉じる]    いつもの家事        [⋯] [＋] ┐
│ 無料プラン 7 / 10件  [上限を増やす]       │ ← 無料プランのときだけ
│ 掃除                                      │
│   風呂掃除              10pt           ≡ │
│   換気扇                30pt           ≡ │
│ 洗濯                                      │
│   布団干し              20pt           ≡ │
│ その他                                    │
│   ゴミ出し              10pt           ≡ │
└──────────────────────────┘
  [⋯] = カテゴリを管理 / テンプレートから取り込む
```

- カテゴリごとのセクションで表示する（家事が0件のカテゴリのセクションは出さない）
- 行のタップで編集モーダル、スワイプで削除（コピー方式で他に影響しないため、確認は出さない）
- 並べ替えはカテゴリ内で行う。カテゴリをまたぐ移動は編集モーダルのカテゴリ変更で行う
- 右上の「＋」で追加モーダルを開く（上限なら案内アラート）
- 無料プランのときは件数と「上限を増やす」（Paywall）を表示する。上限を超えている分は行をグレーアウトし、「プレミアムプランで使えます」と添える
- 0件のときは空状態を表示する（「いつもの家事を登録しませんか？」＋追加ボタン。テンプレートに家事があれば「テンプレートから取り込む」も並べる）

**追加・編集モーダル（ハーフモーダル）**

- 項目: 家事の名前（必須・グループ内で重複不可）、ポイント、カテゴリ
- カテゴリの選択肢: プリセット、カスタム、その他（未設定）、「＋ 新しいカテゴリ」（テキスト入力のアラートで作成し、そのまま選択状態にする）

**カテゴリ管理画面（Push遷移）**

- プリセットは鍵アイコン付きで表示し、操作できない
- カスタムはタップで名前変更（アラート）、スワイプで削除、並べ替えができる
- 削除時は「このカテゴリの家事は『その他』に表示されます」と確認を出す
- 右上の「＋」で追加する

**テンプレートから取り込む（シート）**

- テンプレートの全曜日から家事を集め、名前で重複を除いて一覧にする（名前・ポイントは最初に見つかったものを使う）
- すでに同じ名前のいつもの家事があるものは、チェック済み・操作不可として「登録済み」と表示する
- チェックしたものを「N件取り込む」で一括追加する。カテゴリは未設定
- 無料プランでは残り件数までしかチェックできない。超えようとしたら上限の案内アラートを出す

#### ホームの「おすすめの設定」セクション

`RegisteredContent` の一番下（今 `PromoteHouseworkTemplateBanner` がある位置）に「おすすめの設定」セクションを作り、設定をすすめるカードをまとめる。

| 順 | カード | 表示条件 | 文言 | タップ時 |
|---|---|---|---|---|
| 1 | テンプレート | テンプレートが未作成 かつ ×で閉じていない | 見出し「家事のテンプレートを設定しませんか？」／本文「曜日ごとの家事を登録しておくと、毎週の家事が自動で並びます。」／ボタン「テンプレートを設定する」 | テンプレート画面（既存どおり） |
| 2 | いつもの家事 | いつもの家事が0件 かつ ×で閉じていない | 見出し「いつもの家事を登録しませんか？」／本文「よくやる家事を登録しておくと、次からタップするだけで追加できます。」／ボタン「いつもの家事を登録する」 | いつもの家事の管理画面 |

- 各カードの右上に×ボタンを置き、押したら**恒久的に表示しない**。状態は**端末ごと**に `@AppStorage` へ保存する
- 表示するカードが0枚になったら、セクションの見出しごと隠す
- 既存のテンプレートバナーの文言（「設定されていません」「分担しましょう！」）は、義務のように読めるため上の文言に置き換える（`.claude/rules/ux-writing.md`）

#### 設定画面

- 設定画面に「いつもの家事」の行を追加し、管理画面を開く

### 非機能要件 / 制約

- 既存の入力履歴（`HouseworkHistoryList`／`@AppStorage`）は残す
- テンプレートの既存データ構造（`HouseworkTemplates/{id}/Days`）は変更しない
- 無料プランの上限・名前の重複不可は、**クライアント側でのみ**判定する
  - プレミアム判定の根拠の `Account.isPremium` がクライアント書き込みのため、セキュリティルールでは正当性を検証できない（`Houseworks.expiredAt` と同じ残存リスク）
  - 同居人が同時に追加した場合、一時的に上限超過や名前の重複が起こりうるが、許容する
- 同時編集は後勝ち（ロックやPresenceは設けない）
- 末端のコンポーネントは値を受け取って描画するだけにする（`.claude/rules/presentation-logic-placement.md`）。選ぶ部品もこれに従う

---

## 設計方針

### 1. モジュール構成

```
HouseworkFeature ─────────┐
HouseworkTemplateFeature ─┼─→ FrequentHouseworkFeature ─→ HometeDomain / HometeUI / HometeResources
                          │      ・FrequentHouseworkPicker（選ぶ部品）
                          │      ・RegisterSourceTabs（2タブの枠。両featureで共用）
                          │      ・管理画面／編集モーダル／カテゴリ管理／取り込み
AppRoot ──────────────────┘   （AppRoute.frequentHouseworkManagement を解決）
HomeFeature / SettingFeature ─→ AppRoute経由で管理画面を開く（FrequentHouseworkFeatureには依存しない）
```

- `LocalPackage/Package.swift` に `FrequentHouseworkFeature` と `FrequentHouseworkFeatureTests` を追加する
- `HouseworkFeature` と `HouseworkTemplateFeature` の依存に `FrequentHouseworkFeature` を追加する
- `doc/multimodules_structure.md` と `CLAUDE.md`（主要ディレクトリ・テストターゲット）を更新する

### 2. Firestore

```
Cohabitant/{cohabitantId}
  ├── Houseworks/{houseworkId}                       ← 既存
  ├── HouseworkTemplates/{templateId}                ← 既存
  ├── FrequentHouseworks/{itemId}                    ← 新規
  └── FrequentHouseworkCategories/{categoryId}       ← 新規（カスタムカテゴリのみ）
```

#### `FrequentHouseworks/{itemId}`

```
{
  "id": String,            // ドキュメントIDと一致（UUID）
  "title": String,
  "point": Int,
  "categoryId": String?,   // 未設定ならフィールドなし。プリセットIDまたはカスタムカテゴリID
  "sortOrder": Int,        // カテゴリ内の並び順
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

#### `FrequentHouseworkCategories/{categoryId}`

```
{
  "id": String,            // ドキュメントIDと一致（UUID）
  "name": String,
  "sortOrder": Int,
  "createdAt": Timestamp
}
```

- プリセットカテゴリはFirestoreに持たず、アプリ内の定数とする。IDは `preset.cleaning` / `preset.laundry` / `preset.cooking` / `preset.shopping` / `preset.garbage`
- 並べ替えは、移動したセクション内の `sortOrder` を振り直して `WriteBatch` で一括更新する（1グループあたりの件数が少ないため）
- 件数が少なく、選ぶ部品で常に使うので、グループ参加中は2つのコレクションを常時購読する

#### セキュリティルール（`firebase/firestore.rules`）

```
match /FrequentHouseworks/{itemId} {
  allow read, delete: if isCohabitantMember(cohabitantId);
  allow create, update: if isCohabitantMember(cohabitantId)
                        && request.resource.data.id == itemId;
}

match /FrequentHouseworkCategories/{categoryId} {
  allow read, delete: if isCohabitantMember(cohabitantId);
  allow create, update: if isCohabitantMember(cohabitantId)
                        && request.resource.data.id == categoryId;
}
```

- `firebase/functions/test/rules/firestore.rules.test.ts` にメンバー／非メンバーの読み書きテストを追加する
- アカウント削除時のデータ削除（`deleteUserData.ts`）は `recursiveDelete` でCohabitant配下をまとめて消しているため、処理の変更は不要。コメントの列挙だけ更新する

### 3. ドメイン（`HometeDomain/Cohabitant/FrequentHousework/`）

| 型 | 役割 |
|---|---|
| `FrequentHouseworkItem` | いつもの家事1件（`id`, `title`, `point`, `categoryId?`, `sortOrder`, `createdAt`, `updatedAt`） |
| `FrequentHouseworkCategory` | カテゴリ。`preset(PresetCategory)` と `custom(id, name, sortOrder)` を表す |
| `PresetFrequentHouseworkCategory` | プリセット5種の定数（ID・表示名・表示順） |
| `FrequentHouseworkSection` | 表示用に「カテゴリ＋家事の配列」をまとめたもの。「その他」もここで表す |
| `FrequentHouseworkContext` | 全件＋カテゴリを持つ値型。セクション化・名前の重複判定・利用可否判定を担う（`HouseworkTemplateContext` と同じ役割） |
| `FrequentHouseworkLimitPolicy` | 無料の上限（10件）。`canAdd(count:isPremium:)`、`remainingCount`、`usableItemIds(context:isPremium:)` |
| `FrequentHouseworkStore` | `@Observable`。購読と、追加・編集・削除・並べ替え・取り込み・カテゴリ操作を行う。Analyticsの送信をここに集約する |
| `FrequentHouseworkError` | 名前の重複、上限超過などのエラー |

```swift
public struct FrequentHouseworkContext: Equatable, Sendable {
    public let items: [FrequentHouseworkItem]
    public let customCategories: [FrequentHouseworkCategory]

    /// 表示順（プリセット → カスタム → その他）のセクション。家事0件のセクションは含めない
    public var sections: [FrequentHouseworkSection] { ... }
    /// 絞り込みのチップに出すカテゴリ（家事0件のカテゴリも含む）
    public var filterCategories: [FrequentHouseworkCategory] { ... }
    /// 前後の空白を除いて同じ名前のいつもの家事があるか
    public func containsTitle(_ title: String, excluding id: String? = nil) -> Bool { ... }
}
```

- `FrequentHouseworkStore` は `AppTabView` で他のStoreと同じく `AppDependencies` から生成し、`task(id: loginContext.cohabitantId)` で購読を開始・切り替える
- 画面へは `\.frequentHouseworkContext`（読み取り用の値）と `FrequentHouseworkStore`（操作用）をEnvironmentで配る。Environmentキーは `HometeUI/Components/Environment/` に置く（`HouseworkTemplateContext+Environment.swift` と同じ場所）

### 4. Client / Infrastructure

`HometeDomain/Dependencies/FrequentHouseworkClient.swift`（`.previewValue`）と `HometeInfrastructure` の `.liveValue` を追加する。

```swift
public struct FrequentHouseworkClient: Sendable {
    public let addItemsSnapshotListener: @Sendable (_ id: String, _ cohabitantId: String) async -> AsyncStream<[FrequentHouseworkItem]>
    public let addCategoriesSnapshotListener: @Sendable (_ id: String, _ cohabitantId: String) async -> AsyncStream<[FrequentHouseworkCategory]>
    /// 追加・編集・並べ替え・取り込み（WriteBatchで一括書き込み）
    public let upsertItems: @Sendable (_ items: [FrequentHouseworkItem], _ cohabitantId: String) async throws -> Void
    public let deleteItem: @Sendable (_ id: String, _ cohabitantId: String) async throws -> Void
    /// カテゴリの追加・名前変更・並べ替え（WriteBatchで一括書き込み）
    public let upsertCategories: @Sendable (_ categories: [FrequentHouseworkCategory], _ cohabitantId: String) async throws -> Void
    public let deleteCategory: @Sendable (_ id: String, _ cohabitantId: String) async throws -> Void
    public let removeListener: @Sendable (_ id: String) async -> Void
}
```

- `CollectionPath` に `frequentHouseworks` / `frequentHouseworkCategories` を追加する

### 5. まとめて登録（`HouseworkListStore` / `HouseworkClient`）

- `HouseworkClient` に `insertItems(_ items: [HouseworkItem], _ cohabitantId: String)` を追加する（`WriteBatch` で一括書き込みし、全件成功か全件失敗かのどちらかにする）
- `HouseworkListStore.register(newItems:cohabitantId:step:)` を追加する
  - Analyticsの `housework` `register` は**1件につき1イベント**送る（既存の指標の意味を保つ）
  - プッシュ通知は1通だけ送る
- `PushNotificationContent.addNewHouseworkItems(_ titles: [String])` を追加する
  - 1件: 既存の `addNewHouseworkItem` と同じ（本文は家事名）
  - 複数: 本文を「布団干し ほか2件」にする
- 既存の `register(newItem:…)` は、テンプレートなど他の呼び出し元が残るなら残す。呼び出し元が登録シートだけなら新メソッドに寄せて削除する
- `DailyHouseworkList.isAlreadyRegistered` と登録シートの重複アラートは削除する（呼び出し元が常に `items: []` を渡していて、実際には動いていなかったため、挙動は変わらない）

### 6. 登録シート（`HouseworkFeature/RegisterHouseworkView/`）

- 状態は `RegisterHouseworkDraft`（`HouseworkFeature/Model/`）にまとめ、ロジックをユニットテストする

```swift
struct RegisterHouseworkDraft: Equatable {
    var selectedFrequentItemIds: [String]       // 選んだ順を保持する
    var queuedEntries: [ManualEntry]            // 「続けて入力する」で追加したもの
    var input: ManualEntry                      // 新しく入力タブで入力中のもの

    struct ManualEntry: Equatable {
        var title: String
        var point: Int
        var categoryId: String?
        var savesAsFrequent: Bool
    }

    /// 登録予定リスト（選択中のいつもの家事 → 続けて入力 → 入力中の順）
    func pendingEntries(context: FrequentHouseworkContext) -> [PendingEntry]
    var hasInput: Bool                            // キャンセル時の確認要否
    mutating func toggle(_ itemId: String)
    mutating func queueCurrentInput()             // 「続けて入力する」
    mutating func remove(_ entry: PendingEntry)   // 登録予定リストからの取り消し
}
```

- タブは `FrequentHouseworkFeature` の `RegisterSourceTabs` を使う
  - 上部の切り替え（`HouseworkBoardSegmentedControl` と同じ見た目）と `TabView(.page(indexDisplayMode: .never))` を同じ選択状態に結び付ける
  - カテゴリの横スクロールは、ページの `TabView` の中に置いた横 `ScrollView` になる。触り始めた場所の部品が優先されるため、カテゴリ領域ではスクロール、それ以外ではタブが切り替わる
- 登録予定リストの一覧は、下部の要約をタップしたときに開く別シート（`presentationDetents([.medium])`）にする
- 上限の案内アラート → `router.resolve(.paywall)`（Paywallの `step` は `frequent_housework_limit`）

### 7. 選ぶ部品（`FrequentHouseworkFeature/Picker/`）

値を受け取って描画し、イベントを返すだけにする。何を選べるかは呼び出し側（登録シート・テンプレートのモーダル）が `FrequentHouseworkContext` と `FrequentHouseworkLimitPolicy` から決めて渡す。

```swift
public struct FrequentHouseworkPicker: View {
    public init(
        filterCategories: [FrequentHouseworkCategory],
        sections: [FrequentHouseworkSection],
        selectedIds: Set<String>,
        disabledIds: Set<String>,           // 上限超過分
        onTapItem: @escaping (FrequentHouseworkItem) -> Void,
        onTapManage: @escaping () -> Void
    )
}
```

- 絞り込みで選んでいるカテゴリは部品の内部状態（`@State`）で持つ（表示だけの状態のため）
- 0件のときの空状態も部品に含め、「管理」ボタンと同じイベントを返す

### 8. テンプレートのモーダル（`HouseworkTemplateFeature/EditModal/`）

- `HouseworkTemplateItemEditModal` の新規追加モードを `RegisterSourceTabs` で包む。いつもの家事タブで選んだら `input.title` / `input.point` に入れ、「新しく入力」タブに切り替える
- `TemplateItemEditInput` に `savesAsFrequent` / `categoryId` を追加し、「決定」時に `FrequentHouseworkStore` へ保存する
- 破棄の確認のため、初期値との差分判定を `TemplateItemEditInput` に持たせる

### 9. ホームの「おすすめの設定」（`HomeFeature/.../RegisteredContent/`）

- `RecommendedSettingSection`（見出し＋カード群）と `RecommendedSettingCard`（見出し・本文・ボタン・×）を追加する
- `PromoteHouseworkTemplateBanner` は `RecommendedSettingCard` に置き換える。画像は既存の `PromoteHouseworkTemplateBannerIcon` を使い、いつもの家事用の画像は新しく用意する（用意できるまではSF Symbolで代用する）
- ×の状態は `@AppStorage` に保存する（Bool値なので標準の `@AppStorage("…")` を使う。キーは `dismissedRecommendedTemplate` / `dismissedRecommendedFrequentHousework`）
- どのカードを出すかは `RegisteredContent` が決め、セクションには表示するカードの配列を渡す

### 10. ルーティング

- `AppRoute.frequentHouseworkManagement` を追加し、`AppRoot` の `RouteResolver` で `FrequentHouseworkManagementScreen` を返す
- 開き方はどこからでも `fullScreenCoverOnIOS`（テンプレート画面と同じ）
- 選ぶ部品の「管理」は、登録シート（sheet）の上に重ねて開く

### 11. Analytics（`doc/analytics_events.md` も更新する）

**新規イベント `frequent_housework`**（`FrequentHouseworkStore` に送信を集約）

| パラメータ | 必須 | 値 |
|---|---|---|
| `action` | ○ | `create` / `edit` / `delete` / `import` / `limit_reached` / `create_category` / `delete_category` |
| `step` | — | `management` / `register` / `template` （起点画面。`create` と `limit_reached` に付ける） |
| `result` | — | `success` / `failure` |

- `create`: 家事1件につき1イベント（管理画面の追加、「いつもの家事に保存する」）
- `import`: 取り込み1回につき1イベント
- `limit_reached`: 上限の案内アラートを表示した

**既存イベントの変更**

- `housework` の `register` に `source`（`frequent` / `manual`）を追加する。いつもの家事から選んだ家事か、手入力の家事かを区別する
- `paywall` の `step` に `frequent_housework_limit` を追加する
- `recommended_setting`（新規）: `action` = `tap` / `dismiss`、`target` = `template` / `frequent_housework`

**画面表示（`AppScreen`）**

- `frequent_housework_management` / `frequent_housework_edit` / `frequent_housework_category` / `frequent_housework_import`

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規モジュール | `LocalPackage/Sources/Features/FrequentHouseworkFeature/` | 選ぶ部品・2タブの枠・管理画面一式 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/FrequentHousework/` | モデル・Context・LimitPolicy・Store・Error |
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/FrequentHouseworkClient.swift` | プロトコルと `.previewValue` |
| 新規Infra | `LocalPackage/Sources/HometeInfrastructure/`（`ImplFrequentHouseworkClient` など） | `.liveValue` |
| 修正Infra | `LocalPackage/Sources/HometeInfrastructure/Firestore/Reference/CollectionPath.swift` | コレクションパス追加 |
| 修正Client | `LocalPackage/Sources/HometeDomain/Dependencies/HouseworkClient.swift` | `insertItems` 追加 |
| 修正Store | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | まとめて登録 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/PushNotificationContent.swift` | まとめた通知 |
| 削除 | `DailyHouseworkList.isAlreadyRegistered` | 重複チェック削除 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Navigation/AppRoute.swift` | `frequentHouseworkManagement` |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/AnalyticsLog/` | イベント追加・変更 |
| 修正DI | `LocalPackage/Sources/HometeDomain/Dependencies/AppDependencies.swift` | Client追加 |
| 修正Root | `LocalPackage/Sources/AppRoot/AppTabView.swift` | Store生成・購読・Environment注入 |
| 修正Root | `LocalPackage/Sources/AppRoot/`（RouteResolver） | 管理画面の解決 |
| 新規UI | `LocalPackage/Sources/HometeUI/Components/Environment/FrequentHouseworkContext+Environment.swift` | Environmentキー |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/RegisterHouseworkView/RegisterHouseworkView.swift` | 2タブ・登録予定・まとめて登録・キャンセル |
| 新規Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/RegisterHouseworkDraft.swift` | 登録シートの状態 |
| 修正View | `LocalPackage/Sources/Features/HouseworkTemplateFeature/EditModal/HouseworkTemplateItemEditModal.swift` | 2タブ・保存チェック・破棄確認 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkTemplateFeature/Model/TemplateItemEditInput.swift` | 保存チェック・差分判定 |
| 修正View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/RegisteredContent.swift` | おすすめの設定セクション |
| 新規View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/Components/RecommendedSetting*.swift` | セクション・カード |
| 削除View | `.../Components/PromoteHouseworkTemplateBanner.swift` | カードに置き換え |
| 修正View | `LocalPackage/Sources/Features/SettingFeature/SettingView.swift` | 「いつもの家事」の行 |
| 修正 | `LocalPackage/Package.swift` | モジュール・テストターゲット・依存追加 |
| 修正 | `firebase/firestore.rules` / `firebase/functions/test/rules/firestore.rules.test.ts` | ルールとテスト |
| 修正 | `firebase/functions/src/deleteUserData.ts` | コメント更新のみ |
| 修正ドキュメント | `doc/analytics_events.md` / `doc/multimodules_structure.md` / `CLAUDE.md` | 追従 |

---

## タスク

差分が大きい（Dangerの500行警告を大きく超える）ため、下の区切りごとにPRを分ける。

### Phase 1: 設計確定

- [x] 位置づけ: 単発登録・テンプレートの下の独立feature（ADR-0020）
- [x] 呼び出し時はコピー。いつもの家事は管理画面でのみ変わる
- [x] 選ぶ部品は選ぶだけ。選んだあとの動きは呼び出し側が決める
- [x] 追加の入口: 管理画面・「いつもの家事に保存する」・テンプレートから取り込む
- [x] 管理画面の入口: 選ぶ部品の「管理」・設定画面・ホームの「おすすめの設定」
- [x] カテゴリ: プリセット（掃除・洗濯・料理・買い物・ゴミ）＋カスタム。未設定・削除済みは「その他」として表示
- [x] 名前: 「いつもの家事」。グループ内で同じ名前は不可
- [x] 登録シート: 2タブ（タップ・スワイプで切り替え、カテゴリの横スクロールが優先）、最初に開くタブは件数で決める
- [x] まとめて登録: 登録予定リストを常に表示、「続けて入力する」「N件登録する」、ポイントは変更不可
- [x] 重複登録は許容し、既存の重複チェックは削除
- [x] キャンセル: 入力があれば破棄確認。なければそのまま閉じる
- [x] プッシュ通知は1通にまとめる
- [x] テンプレートの追加モーダルも2タブ（いつもの家事は1件選択）
- [x] ホーム: 「おすすめの設定」セクション（テンプレート → いつもの家事）、×で恒久的に閉じる（端末ごと）、「〜しませんか？」の文言
- [x] 入力履歴は残す
- [x] 無料プランは10件まで。上限時は案内してPaywall。無料に戻ったら11件目以降は使えない。カスタムカテゴリは制限なし

### Phase 2: 実装

**PR 1: ドメイン・データ層**

- [ ] `FrequentHouseworkItem` / `FrequentHouseworkCategory` / `PresetFrequentHouseworkCategory` / `FrequentHouseworkSection` / `FrequentHouseworkContext` / `FrequentHouseworkLimitPolicy` / `FrequentHouseworkError`
- [ ] `FrequentHouseworkClient`（プロトコル・`.previewValue`・`.liveValue`）と `CollectionPath` の追加
- [ ] `FrequentHouseworkStore`（購読・CRUD・並べ替え・取り込み・カテゴリ操作・Analytics）
- [ ] `AppDependencies` / `AppTabView` への組み込みとEnvironmentキー
- [ ] Firestoreルールとルールテスト、`deleteUserData.ts` のコメント
- [ ] Analytics（`frequent_housework` / `paywall` の `step` / `AppScreen`）と `doc/analytics_events.md`
- [ ] ユニットテスト: Context（セクション化・「その他」の扱い・名前の重複判定）、LimitPolicy（上限・無料に戻ったときの利用可否）、Store

**PR 2: FrequentHouseworkFeature（管理画面）**

- [ ] `Package.swift` にモジュール追加、`doc/multimodules_structure.md` / `CLAUDE.md` 更新
- [ ] 管理画面・追加／編集モーダル・カテゴリ管理画面・テンプレートから取り込むシート
- [ ] 上限の案内アラートとPaywall誘導
- [ ] `AppRoute.frequentHouseworkManagement` と `RouteResolver`
- [ ] 設定画面の「いつもの家事」行
- [ ] 選ぶ部品 `FrequentHouseworkPicker` と2タブの枠 `RegisterSourceTabs`
- [ ] Preview（空・通常・上限超過・カテゴリあり）

**PR 3: 登録シートの2タブ化とまとめて登録**

- [ ] `HouseworkClient.insertItems` / `HouseworkListStore.register(newItems:…)` / `PushNotificationContent.addNewHouseworkItems`
- [ ] `housework` `register` への `source` 追加
- [ ] `RegisterHouseworkDraft` とユニットテスト（選択の切り替え・続けて入力・取り消し・登録予定の組み立て・破棄確認の要否）
- [ ] `RegisterHouseworkView` の作り直し（2タブ・登録予定リスト・キャンセル・保存チェック・入力履歴）
- [ ] 重複チェック（`isAlreadyRegistered`）とアラートの削除
- [ ] Preview（いつもの家事あり／なし・登録予定あり・通信中）

**PR 4: テンプレートのモーダル**

- [ ] `HouseworkTemplateItemEditModal` の新規追加モードの2タブ化
- [ ] `TemplateItemEditInput` の保存チェック・差分判定とユニットテスト
- [ ] 破棄の確認

**PR 5: ホームの「おすすめの設定」**

- [ ] `RecommendedSettingSection` / `RecommendedSettingCard` と×の保存
- [ ] `PromoteHouseworkTemplateBanner` の置き換えと文言変更
- [ ] いつもの家事カードの画像（用意できるまではSF Symbol）
- [ ] `recommended_setting` イベント
- [ ] Preview（2枚・1枚・0枚）

### Phase 3: 検証

- [ ] `swift build` でビルド通過
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] ユニットテスト実行（追加分含む）通過
- [ ] Firestoreルールテスト（`npm run test:rules`）通過
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] シミュレータで動作確認（`simulator-e2e-check`）
  - [ ] いつもの家事を2件選び、1件手入力して「3件登録する」→ ボードに3件並び、通知が1通
  - [ ] タブのスワイプ切り替えとカテゴリの横スクロールが干渉しない
  - [ ] テンプレートの追加でいつもの家事を選ぶと、名前・ポイントが入る
  - [ ] ホームのカードを×で閉じると、再起動後も出ない

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/283
- ADR: [ADR-0020](../adr/0020-frequent-housework-as-independent-copy-source.md)
- 既存実装（参考）:
  - `LocalPackage/Sources/Features/HouseworkFeature/RegisterHouseworkView/RegisterHouseworkView.swift`
  - `LocalPackage/Sources/Features/HouseworkTemplateFeature/EditModal/HouseworkTemplateItemEditModal.swift`
  - `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkTemplateContext.swift`
  - `LocalPackage/Sources/HometeDomain/Dependencies/HouseworkTemplateClient.swift`
  - `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/RegisteredContent.swift`
  - [doc/strategy/housework_template.md](housework_template.md)
