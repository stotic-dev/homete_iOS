# 家事週間テンプレート機能 対応方針

関連Issue: [#67 家事の週間テンプレート機能の追加](https://github.com/stotic-dev/homete_iOS/issues/67)

> テンプレートを「適用」せず、表示時にマージする仮想ビュー方式を採用した経緯は [ADR-0003](../adr/0003-housework-template-virtual-view.md) を参照。
> 当初検討した「テンプレート適用ロジックを Cloud Functions に集約する」案は [ADR-0002](../adr/0002-housework-template-apply-on-backend.md)（却下済）に記録している。

## 概要

毎週繰り返される定型的な家事（例: 月曜日はゴミ出し、水曜日は掃除）をテンプレートとして登録し、`HouseworkBoardView` の incomplete 表示に自動的に組み込めるようにする機能を追加する。

テンプレートに登録された家事は `Houseworks` コレクションには書き込まず、画面表示時にテンプレート定義と既存 `Houseworks` をマージして表示する。ユーザーがその家事を `pendingApproval` 以降の状態に遷移させた時点で初めて `Houseworks` コレクションにドキュメントを作成する。

---

## Firestoreの設計方針

### コレクション構造

```
Cohabitant/{cohabitantId}
  └── Houseworks/{houseworkId}                ← 既存: 実際の家事アイテム
  └── HouseworkTemplates/{templateId}        ← 新規: テンプレートのメタドキュメント
      └── Days/{dayOfWeek}                   ← 曜日ごとの家事定義
      └── Editors/{userId}                   ← 編集中ユーザー（Presence用）
```

### HouseworkTemplates ドキュメント設計

#### `HouseworkTemplates/{templateId}`（テンプレートのメタドキュメント）

```
{
  "templateId": String,   // テンプレートID
  "name": String,         // テンプレート名
  "version": Int          // 楽観的ロック用バージョン
}
```

#### `HouseworkTemplates/{templateId}/Days/{dayOfWeek}`（曜日ごとの家事定義）

ドキュメントIDは曜日を表す数値文字列（`"0"` 〜 `"6"`）。

| ドキュメントID | 曜日 |
|---|---|
| `"0"` | 日曜日 |
| `"1"` | 月曜日 |
| `"2"` | 火曜日 |
| `"3"` | 水曜日 |
| `"4"` | 木曜日 |
| `"5"` | 金曜日 |
| `"6"` | 土曜日 |

```
{
  "dayOfWeek": Int,           // 0-6（ドキュメントIDと一致）
  "items": [
    {
      "id": String,           // テンプレートアイテムの安定ID（UUID）
      "title": String,        // 家事名
      "point": Int,           // 家事ポイント
      "updatedAt": Timestamp  // アイテムの作成・編集時刻（表示範囲制御に使用）
    },
    ...
  ]
}
```

`id` および `updatedAt` の役割は「HouseworkBoardView 表示方式」セクションを参照。

#### `HouseworkTemplates/{templateId}/Editors/{userId}`（Presence用）

```
{
  "userId": String,           // 編集中のユーザーID
  "updatedAt": Timestamp,     // 最終更新日時（クライアント側のTTL判定に使用）
  "expiredAt": Timestamp      // 有効期限（Firestore TTLポリシーによる自動削除用）
}
```

### コンフリクト制御

家族全員がテンプレートを同時編集できるため、以下の2つの仕組みを組み合わせて対応する。

#### 楽観的ロック（書き込み時の競合検知）

- テンプレートドキュメント（`HouseworkTemplates/{templateId}`）に `version: Int` を持たせる
- 曜日定義の書き込みは「1回の保存で変更があった複数の `Days/{dayOfWeek}` をまとめて更新する」一括書き込みとし、Firestore トランザクション内で現在の `version` を確認する。読み取り時と一致すれば対象 `Days` ドキュメントを順に書き込み、最後に `version + 1` して保存する。不一致なら書き込みを拒否してUIにエラーを通知する
- `version` はテンプレートドキュメントに集約することで、どの曜日が更新されても整合性を保つ
- 編集中クライアントは `HouseworkTemplates/{templateId}` の SnapshotListener を張って `version` をリアルタイムに追従する。これにより、他メンバーの保存後もローカルの `currentVersion` が最新化され、続けて保存しても不必要にコンフリクトを起こさない

#### Presence（編集中ユーザーの表示）

- テンプレート編集画面を開いたとき: `Editors/{自分のuserId}` を upsert（`updatedAt = 現在時刻`、`expiredAt = 現在時刻 + 5分`）
- 保存・キャンセル・画面離脱時: `Editors/{自分のuserId}` を削除
- アプリ終了・クラッシュ時: ドキュメントが残留するが以下の2段構えで対処する
  - **クライアント側**: `updatedAt` が5分以上古ければ「離席済み」として無視（表示しない）
  - **Firestore TTLポリシー**: `expiredAt` フィールドを TTL ポリシーに設定し、期限切れのドキュメントを自動削除（削除はコスト無料、最大24時間の遅延あり）
- ドキュメントIDが `userId` なので各ユーザーが自分のドキュメントのみ書き込み、Presence更新自体での書き込み競合は起きない

**2つの役割の分担:**

| 仕組み | 目的 | タイミング |
|---|---|---|
| `version`（楽観的ロック） | 上書きを検知して保存拒否 | 書き込み時に検知・通知 |
| `Editors`（Presence） | 誰が編集中かをUIに表示 | コンフリクト前にユーザーが予測できる |

### 設計の根拠

**テンプレートを複数持てる構造にする理由**

`HouseworkTemplates/{templateId}` をメタドキュメントとして持ち、家事定義をサブコレクション（`Days`）に分離することで、将来的に「平日テンプレート」「週末テンプレート」のように複数のテンプレートを持てる拡張性を確保する。

**Presenceをサブコレクションにする理由**

`editors` をテンプレートドキュメントのフィールド（配列）で持たせると、複数ユーザーの同時更新時に `{ userId, updatedAt }` オブジェクトの配列マージが難しく（`arrayUnion` はオブジェクト同一性を全フィールドで比較するため）、楽観的ロックの `version` 更新と関心が混在する。`Editors/{userId}` をサブコレクションにすることで、各ユーザーが自分のドキュメントのみ書き込む形となり競合が起きない。

**テンプレート削除時のサブコレクション**

Firestoreはドキュメントを削除してもサブコレクションを自動削除しない。テンプレートを削除する際はクライアント側で `Days`（固定7件）と `Editors`（0〜N件）を Firestore バッチ削除で明示的に削除する。

**テンプレートアイテムに安定IDと `updatedAt` を持たせる理由**

「HouseworkBoardView 表示方式」セクションを参照。仮想 incomplete 表示と実 Housework の重複防止、および過去日付への意図しない波及の防止のため、アイテム単位での安定ID と編集時刻が必要となる。

**トレードオフ**

- 1曜日内のアイテムを個別追加・削除する場合、`items` 配列全体を書き直す必要がある
  - `arrayUnion` / `arrayRemove` はオブジェクト配列の要素更新に向かないため
  - テンプレートのアイテムIDはFirestoreドキュメントIDではなくアプリ側でUUIDを割り当てて管理する

### 既存コレクションへの影響

**`Houseworks` コレクション**

`HouseworkItem` に `templateHouseworkItemId: String?` を追加する。テンプレート由来の家事（仮想 incomplete から状態遷移して作成されたもの）にのみ値が入り、手動追加された家事では `nil` のままになる。

テンプレート由来かつ状態遷移していない家事は `Houseworks` コレクションに書き込まれない（表示時にマージで仮想表示する。「HouseworkBoardView 表示方式」セクション参照）。

**`Cohabitant` ドキュメント**

変更なし。仮想ビュー方式では「適用済み状態」を管理する必要がない（テンプレート適用操作自体が存在しないため）。

### セキュリティルール

ログイン済みかつ同じ `cohabitantId` を持つメンバーのみ読み書きを許可する。`Editors/{userId}` の書き込みは自分の `userId` のドキュメントのみに限定する。

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isCohabitantMember(cohabitantId) {
      return request.auth != null &&
             request.auth.uid in get(/databases/$(database)/documents/Cohabitant/$(cohabitantId)).data.members;
    }

    match /Cohabitant/{cohabitantId}/HouseworkTemplates/{templateId} {
      allow read, write: if isCohabitantMember(cohabitantId);

      match /Days/{dayOfWeek} {
        allow read, write: if isCohabitantMember(cohabitantId);
      }

      match /Editors/{userId} {
        allow read: if isCohabitantMember(cohabitantId);
        allow write: if isCohabitantMember(cohabitantId) && request.auth.uid == userId;
      }
    }
  }
}
```

---

## iOSアプリの実装方針

### モジュール構成

テンプレート設定・管理機能は `HouseworkTemplateFeature` として新規モジュールを追加する。

**分離する理由:**
- `HouseworkFeature`（今週の家事を見る・完了する）とは解決する課題が異なる
- `HouseworkFeature`・`HomeFeature` の複数モジュールから呼び出されるため、どちらかに含めると Feature 間直接依存が生じる

**遷移元と AppRoute:**

テンプレート設定画面への導線は以下の2画面から行う。いずれも異なる Feature モジュールからの遷移のため、RouteResolver パターンを使用する。

| 遷移元 | モジュール | 遷移タイミング |
|---|---|---|
| `HouseworkBoardView` | `HouseworkFeature` | 家事ボード画面からの設定導線 |
| Home画面 | `HomeFeature` | 初回利用時のテンプレート設定促進 |

```swift
// HometeDomain の AppRoute に追加
enum AppRoute: Hashable {
    case cohabitantRegistration
    case setting
    case houseworkTemplate   // 追加
}
```

`AppRoot` の `RouteResolverInjection` で `HouseworkTemplateFeature` の View を解決し、各遷移元は `router.resolve(.houseworkTemplate)` で遷移する。

**モジュール依存関係（追加分）:**

```
HouseworkTemplateFeature
  → HometeDomain
  → HometeUI
  → HometeResources

AppRoot
  → HouseworkTemplateFeature（既存の Feature と同様に追加）
```

---

### 画面仕様

#### 画面構成

テンプレート機能は以下の3つの画面で構成される。

```
HouseworkTemplateView（テンプレート編集画面 / メイン画面）
  ├─ HouseworkTemplateItemEditModal（家事追加・編集モーダル / ハーフモーダル）
  └─ HouseworkTemplateItemDetailView（家事詳細画面 / Push 遷移）
       └─ HouseworkTemplateItemEditModal（編集ボタンから再利用）
```

#### MVP制約

MVP では「テンプレートは1件のみ」とする。テンプレート一覧画面は実装せず、`HouseworkTemplateView` を開いた時点で唯一のテンプレートを直接表示する。将来的に複数テンプレート対応する場合は、上位に一覧画面を挟む構造に拡張する。

#### Empty State

`HouseworkTemplates` コレクションにドキュメントが0件の場合は、Empty State を表示する。

- 「テンプレートを作成する」ボタンを画面中央に配置する
- ボタンタップで `HouseworkTemplateListStore.createTemplate` を呼び、cohabitantId に紐づく1件目のテンプレートを作成する
- 作成成功後は同画面のまま編集可能な通常表示に切り替える

#### HouseworkTemplateView（テンプレート編集画面）

##### 表示モード

画面には「閲覧モード」と「編集モード」の2つのモードがある。

| モード | 開始トリガー | 終了トリガー |
|---|---|---|
| 閲覧モード | 画面表示時のデフォルト | 編集ボタンタップで編集モードへ |
| 編集モード | ナビゲーション右上の編集ボタンタップ | 保存成功 / キャンセル確定 / コンフリクトアラートの確認 |

##### 画面構成（概略）

```
┌──────────────────────────────────────────┐
│ [キャンセル] 家事テンプレート [編集/保存] │ ← Navigation Bar
├──────────────────────────────────────────┤
│ 編集中: Aさん, Bさん                     │ ← 編集中ユーザー表示（編集モード中のみ）
│ ⚠ 他のユーザーが編集中です...      [×]   │ ← コンフリクト注意バナー（条件付き）
├──────────────────────────────────────────┤
│ 月曜日                                   │
│  ┌─────────────┐ ┌─────────────┐         │
│  │ 洗濯  10pt  │ │ 掃除  15pt  │         │
│  └─────────────┘ └─────────────┘         │
│ 火曜日                                   │
│  ┌─────────────┐                         │
│  │ ゴミ出し 5pt│                         │
│  └─────────────┘                         │
│ ...                                      │
│ 日曜日                                   │
│  ...                                     │
├──────────────────────────────────────────┤
│                                  [＋]    │ ← 家事追加ボタン（編集モード中のみ）
└──────────────────────────────────────────┘
```

##### ナビゲーションバー

| 位置 | 要素 | 閲覧モード | 編集モード |
|---|---|---|---|
| 左上 | 閉じる / キャンセル | 閉じるボタン（`dismiss()`） | キャンセルボタン |
| タイトル | "家事テンプレート" | 表示 | 表示 |
| 右上 | 編集 / 保存 | 編集ボタンを表示 | 保存ボタンに入れ替え |

##### 編集中ユーザー表示

編集モード中のみ、画面上部に「編集中の他ユーザー」を表示する。

- 参照元: `HouseworkTemplateEditStore.editors` のうち、自分以外で `isActive(now:)` が true（5分以内に updatedAt が更新されたもの）の editor
- 表示形式: ユーザー名（または ID）を「編集中: Aさん, Bさん」の形で並べる
- 自分自身は表示対象から除外する

##### コンフリクト注意バナー

編集モード中、上述の「自分以外のアクティブな editor」が1人以上存在する間、画面上部に注意バナーを表示する。

- 文言例: 「他のユーザーがテンプレートを編集中です。保存時にコンフリクトすると編集内容が消える場合があります。」
- 右端に × ボタンを配置し、タップで非表示にできる
- 一度 × で閉じても、他ユーザーがアクティブな間は同セッション中に再表示されることはない（×で「閉じた」事実をセッション中保持する）
- 編集モードを抜けて再度入った場合は閉じた状態はリセットされる

##### 曜日リスト表示

月〜日の7曜日それぞれについて、当該曜日に登録されているテンプレートアイテム（`HouseworkTemplateItem`）を一覧表示する。

- 曜日の並び順: 月 → 火 → 水 → 木 → 金 → 土 → 日
- 参照元: 閲覧モード時は `HouseworkTemplateListStore.selectedDays` を、編集モード時は編集セッションのローカル State を表示する
- 各アイテム行に表示する項目: タイトル、ポイント

#### 家事アイテムへのインタラクション

| 操作 | 閲覧モード | 編集モード |
|---|---|---|
| タップ | 家事詳細画面へ Push 遷移 | 家事詳細画面へ Push 遷移 |
| 長押し（コンテキストメニュー） | 非表示 | 「編集」「削除」メニューを表示 |
| ドラッグ&ドロップ | 不可 | 別の曜日へ移動 |

##### タップ

家事アイテムをタップすると、家事詳細画面（`HouseworkTemplateItemDetailView`）へ Push 遷移する。

##### 長押し（編集モード中のみ）

家事アイテムを長押しすると、コンテキストメニューを表示する。

- 編集: 家事追加・編集モーダルを「編集モード」で開く
- 削除: 該当アイテムを仮削除する（保存時に確定）

##### ドラッグ&ドロップ（編集モード中のみ）

家事アイテムをドラッグ&ドロップで別の曜日へ追加できる。

- 移動元の `Day.items` はそのまま維持し、ドロップ先の `Day.items` に同じアイテムを追加する（複数曜日に登録されているアイテムが意図せず単一曜日に縮退するのを防ぐため）
- ドロップ先に既に同じアイテムが登録されている場合は何もしない
- 追加した曜日の新エントリの `updatedAt` を操作時刻に設定する（仮想 incomplete 表示の表示範囲制御に反映される）。既存曜日に登録済みのエントリの `updatedAt` は変更しない
- 仮保存状態として保持し、保存ボタンで初めて Firestore に書き込む

#### 家事追加ボタン

編集モード中のみ、画面右下にフローティングボタン（＋）を表示する。タップでハーフモーダルの家事追加画面を表示する。

#### 家事追加・編集モーダル（ハーフモーダル）

##### 表示方法

`.sheet(...)` + `.presentationDetents([.medium, .large])` でハーフモーダル表示する。

##### 画面構成（概略）

```
┌──────────────────────────────────────────┐
│             家事を追加 / 編集            │ ← タイトル
├──────────────────────────────────────────┤
│ 家事の名前                               │
│ [_______________________________________]│ ← TextField
│                                          │
│ ポイント                                 │
│         [─────●─────]   10               │ ← Slider
│                                          │
│ 曜日                                     │
│ [月] [火] [水] [木] [金] [土] [日]       │ ← 複数選択トグル
├──────────────────────────────────────────┤
│              [決定]                      │
└──────────────────────────────────────────┘
```

##### 入力要素

| 項目 | UI | バリデーション |
|---|---|---|
| 家事名 | TextField | 空でない |
| ポイント | Slider（1〜100、ステップ1） | デフォルト10 |
| 曜日 | 複数選択トグル（月〜日） | 1個以上選択 |

##### 新規追加モードと編集モード

| モード | トリガー | 初期値 | 決定ボタンの挙動 |
|---|---|---|---|
| 新規追加 | 編集モード中の＋ボタン | 全て空・デフォルト値、曜日は全て未選択 | 各選択曜日の `Day.items` に新規アイテムを追加 |
| 編集 | 詳細画面の編集ボタン / 長押しメニューの「編集」 | 既存アイテムの値で初期化、登録曜日が選択状態 | 既存アイテムを更新（曜日変更時は元の曜日から削除し、新しい曜日に追加） |

複数曜日が選択された場合は、各曜日の `Day.items` に同じ家事を割り当てる。アイテム ID の割り当て規則（曜日ごとに新規 UUID か、共通 UUID か）は実装時に確定する。

##### 「決定」ボタンの挙動

- 仮保存状態として `HouseworkTemplateView` のローカル編集 State に反映する（この時点では Firestore には書き込まない）
- モーダルを閉じる
- `HouseworkTemplateView` の表示にも仮保存内容が即反映され、保存ボタンで初めて Firestore に書き込む

##### バリデーション

- 家事名が空、または曜日が0個選択の場合は「決定」ボタンを無効化する

#### 家事詳細画面（HouseworkTemplateItemDetailView）

##### 画面構成

```
┌──────────────────────────────────────────┐
│ [<戻る] テンプレート家事    [編集][削除] │ ← Navigation Bar
├──────────────────────────────────────────┤
│ タイトル: 洗濯                           │
│ ポイント: 10                             │
│ 登録曜日: 月曜日, 水曜日                 │
└──────────────────────────────────────────┘
```

##### ナビゲーションバー

| 位置 | 要素 | 挙動 | 表示条件 |
|---|---|---|---|
| 右上 | 編集ボタン | 家事追加・編集モーダルを「編集モード」で開く | 編集モード中のみ |
| 右上 | 削除ボタン | 該当アイテムを仮削除して詳細画面を pop する | 編集モード中のみ |

##### 表示項目

- 家事のタイトル
- ポイント
- 登録曜日（同一アイテムが複数曜日に登録されている場合は全て表示）

##### 仮保存状態の扱い

詳細画面で表示する内容は、ローカル編集 State の仮保存内容を反映する。詳細画面で編集モーダルを開いて変更を確定した場合も、仮保存状態として `HouseworkTemplateView` に反映される。

#### 編集モード中の状態管理

編集モード中は、Firestore からリスナーで受信した `selectedDays` をそのまま画面に直接バインドするのではなく、編集セッション開始時にスナップショットを取得して、ローカルの編集 State として保持する。保存ボタンで確定するまでの仮保存変更（追加・編集・削除・曜日間移動）はこのローカル State 上で反映される。

| 状態 | 保持場所 | 役割 |
|---|---|---|
| サーバー側最新の `selectedDays` | `HouseworkTemplateListStore.selectedDays` | 閲覧モード時の表示、保存後の反映元、コンフリクト後の最新内容取得元 |
| 編集セッション中の仮保存 State | `HouseworkTemplateEditStore`（または専用 Store） | 編集中の表示・確定までのバッファ |
| `currentVersion` | `HouseworkTemplateEditStore.currentVersion` | 保存時の楽観的ロックチェック |
| 他ユーザーの編集者一覧 | `HouseworkTemplateEditStore.editors` | 編集中ユーザー表示・コンフリクト注意バナーの表示条件 |
| バナーの×閉じ状態 | 画面 State（または `HouseworkTemplateEditStore`） | 編集セッション中の閉じ状態保持 |

##### 編集モード中の Days リスナー

編集モード中は `HouseworkTemplateListStore` の Days SnapshotListener により `selectedDays` は最新化され続けるが、編集セッションのローカル State には自動反映しない（ユーザーの未保存変更を失わないため）。

代わりに、後述のコンフリクト検知経路（`version` 変化）で「他ユーザーの更新を検知 → アラート → 最新内容で再描画」のフローで明示的にユーザーに確認を取る。

#### 保存・キャンセル

##### 保存ボタンの挙動

1. ローカル編集 State の仮保存内容から、変更があった `Day` のみを抽出する（差分計算）
2. `HouseworkTemplateListStore.saveDays(_:templateId:cohabitantId:currentVersion:)` を呼び出す
3. 成功時: 編集モードを終了し閲覧モードに戻る。`HouseworkTemplateEditStore.stopEditing` で `Editors/{自分のuserId}` を削除し、各 SnapshotListener を解除する
4. `HouseworkTemplateError.versionConflict` で失敗した場合: アラートを表示する（「画面データの更新タイミング > コンフリクト発生時」セクション参照）

##### キャンセルボタンの挙動

1. 仮保存中に未保存変更があるかを判定する（ローカル編集 State と編集開始時スナップショットの差分）
2. 未保存変更がある場合のみ、確認アラート「変更を破棄します。よろしいですか？」を表示する
3. 確認した場合（または未保存変更が無い場合）は、編集モードを終了し閲覧モードに戻る。`HouseworkTemplateEditStore.stopEditing` を呼び出して Editor 削除と SnapshotListener 解除を行う
4. ローカル編集 State は破棄する

#### 例外処理

例外処理の方針は「コンフリクト制御」と「画面データの更新タイミング > コンフリクト発生時」セクションを参照。主な例外パターンは以下の3つ。

| パターン | 検知方法 | UI挙動 |
|---|---|---|
| 編集中に他ユーザーがテンプレート更新 | `version` SnapshotListener が新しい version を受信 | アラート表示 → 確認後 `loadDays` で最新内容を fetch して編集 State にも反映 |
| 自分の保存が version 不一致で失敗 | `saveDays` が `HouseworkTemplateError.versionConflict` を throw | アラート表示。`currentVersion` は SnapshotListener により最新化されているため、ユーザーが再操作後に再試行できる |
| ネットワークエラー等の通常エラー | 各 Client メソッドの throw | `@CommonError` でエラーバナー表示（既存パターンを踏襲） |

---

### 新規追加するファイル

| 種別 | モジュール | ファイル | 概要 |
|---|---|---|---|
| Feature | `HouseworkTemplateFeature`（新規） | `HouseworkTemplateScreen.swift` | テンプレート画面のスクリーンエントリー（NavigationStack を含むラッパー、既存） |
| Feature | `HouseworkTemplateFeature`（新規） | `HouseworkTemplateView.swift` | テンプレート編集画面の本体。閲覧・編集モード切替、曜日別家事一覧表示、編集者表示、注意バナー、家事追加ボタンを保持 |
| Feature | `HouseworkTemplateFeature`（新規） | `HouseworkTemplateEmptyView.swift` | テンプレートが0件の初期状態のEmpty表示。「テンプレートを作成する」ボタンを配置 |
| Feature | `HouseworkTemplateFeature`（新規） | `HouseworkTemplateItemEditModal.swift` | 家事追加・編集のハーフモーダル（新規・編集兼用） |
| Feature | `HouseworkTemplateFeature`（新規） | `HouseworkTemplateItemDetailView.swift` | 家事詳細画面（タイトル・ポイント・登録曜日表示、編集・削除ボタン） |
| Feature | `HouseworkTemplateFeature`（新規） | `Components/`（必要に応じて） | 家事行、曜日セクションヘッダ、コンフリクト注意バナー、編集者表示などのサブコンポーネント |
| Feature | `HouseworkTemplateFeature`（新規） | `Stores/HouseworkTemplateEditStore.swift`（既存） | 既存。編集セッション中のローカル仮保存 State も保持する形で拡張する |
| Domain Model | `HometeDomain` | `HouseworkTemplateMeta.swift` | テンプレートのメタ情報（templateId, name、version は Infrastructure 層でのみ扱う） |
| Domain Model | `HometeDomain` | `HouseworkTemplateDay.swift` | 曜日ごとの家事定義（dayOfWeek, items） |
| Domain Model | `HometeDomain` | `HouseworkTemplateItem.swift` | テンプレートアイテム（id, title, point, updatedAt） |
| Domain Model | `HometeDomain` | `HouseworkTemplateEditor.swift` | 編集中ユーザー情報（userId, updatedAt, expiredAt） |
| Client | `HometeDomain` | `HouseworkTemplateClient.swift` | テンプレートのCRUD・Presence管理 |
| Store | `HometeDomain` | `HouseworkTemplateListStore.swift` | テンプレート一覧・Days の読み書きの状態管理 |

### 既存ファイルへの変更

| ファイル | モジュール | 変更内容 |
|---|---|---|
| `CollectionPath.swift` | `HometeInfrastructure` | `houseworkTemplates = "HouseworkTemplates"`、`days = "Days"`、`editors = "Editors"` を追加 |
| `FirestoreExtensionForReferencePath.swift` | `HometeInfrastructure` | `houseworkTemplateRef(cohabitantId:templateId:)`、`houseworkTemplateDaysRef`、`houseworkTemplateEditorRef` を追加 |
| `HouseworkItem.swift` | `HometeDomain` | `templateHouseworkItemId: String?` を追加。テンプレート由来の Housework のみ値を持つ |
| `AppDependencies.swift` | `HometeDomain` | `HouseworkTemplateClient` を追加 |
| `AppRoute.swift` | `HometeDomain` | `.houseworkTemplate` case を追加 |
| `RouteResolverInjection` | `AppRoot` | `.houseworkTemplate` → `HouseworkTemplateView` の解決を追加 |
| `Package.swift` | `LocalPackage` | `HouseworkTemplateFeature` ターゲットを追加、`AppRoot` の依存に追加 |
| `HouseworkBoardView` 関連 Store | `HometeDomain` / `HouseworkFeature` | `Houseworks` に加えて `HouseworkTemplates/{templateId}/Days` を購読し、表示時マージを行うよう改修 |

### 画面データの更新タイミング

#### テンプレート一覧・閲覧画面

閲覧は最新状態でなくても致命的ではなく、リアルタイムリスナーを常時張るコストが見合わないため、画面表示時のワンショット取得とする。

| タイミング | 対象 | 方法 |
|---|---|---|
| 画面表示時 | `HouseworkTemplates`（メタ一覧）+ `Days` | ワンショット |

#### 編集画面

編集中に他のメンバーの変更・Presence・楽観的ロック用バージョンをリアルタイムに反映する必要があるため、編集モードに入った時点でSnapshotListenerを開始する。リスナーは編集モードを抜けた時点で解除し、不要なコストを避ける。

| タイミング | 対象 | 方法 | 目的 |
|---|---|---|---|
| 編集モード開始時 | `Days` | SnapshotListener 開始 | 他メンバーの変更をリアルタイムに検知 |
| 編集モード開始時 | `Editors` | SnapshotListener 開始 | 誰が編集中かをリアルタイム表示 |
| 編集モード開始時 | `HouseworkTemplates/{templateId}` の `version` | SnapshotListener 開始 | 楽観的ロック用 `currentVersion` をリアルタイム追従 |
| 編集モード終了時 | `Days`・`Editors`・`version` | SnapshotListener 解除 | 不要なリスナーを解放 |

**Store の責務分担:**

- `Days` の SnapshotListener と曜日定義の一括保存（`saveDays`）は `HouseworkTemplateListStore` が保持する。閲覧画面でも `Days` を利用するため、編集セッション固有の状態とは切り分ける
- `Editors` と `version` の SnapshotListener、Editor の keepalive は編集セッション固有のため `HouseworkTemplateEditStore` が保持する

#### コンフリクト発生時

コンフリクトは以下の2経路で検知し、それぞれユーザーにアラートで通知する。

| 検知経路 | 検知方法 | UI挙動 |
|---|---|---|
| 編集中に他ユーザーがテンプレートを更新（先回り検知） | `HouseworkTemplateEditStore` の `version` SnapshotListener が新しい `version` を受け取る | アラートを表示する。確認後、`HouseworkTemplateListStore` から最新のテンプレート内容を fetch し、View に反映する |
| 自分の保存処理が version 不一致で失敗 | `HouseworkTemplateListStore.saveDays` が `HouseworkTemplateError.versionConflict` を throw | アラートを表示する |

`version` SnapshotListener により `currentVersion` は常に最新化されているため、コンフリクト後のユーザー操作（再編集・再保存）は新しい `currentVersion` で再試行できる。

#### フロー概要

```
閲覧画面 ─ 表示時ワンショット ─ リスナーなし
                ↓ 編集ボタンタップ
編集画面 ─ Days + Editors + version の SnapshotListener 開始
                ↓ 保存（複数曜日を一括書き込み） / キャンセル
          ─ SnapshotListener 解除
                ↓ 編集中に version 変化を検知（他ユーザーが更新）
          ─ アラート表示 + listStore で最新内容を fetch して View に反映
                ↓ 保存時に versionConflict が throw された
          ─ アラート表示
```

---

## HouseworkBoardView 表示方式

テンプレートの家事は `Houseworks` コレクションには書き込まず、`HouseworkBoardView` 表示時に仮想的に組み立てて表示する。

### 「テンプレート適用」操作は存在しない

ユーザーから見ても、明示的な「適用する」アクションは存在しない。テンプレートを編集すれば、翌日以降の `HouseworkBoardView` に自動的に反映される。

### 表示マージルール

`HouseworkBoardView` の incomplete 表示は、各表示対象日について以下のルールで組み立てる。

1. **実 Housework**: その日付の `Houseworks` ドキュメントは常にそのまま表示する
2. **仮想 incomplete（テンプレート由来）**: その日付の曜日に対応する `HouseworkTemplates/{templateId}/Days/{dayOfWeek}` の `items` のうち、以下を**両方**満たすものを `incomplete` として追加表示する
   - **表示範囲条件**: 表示対象日（0時0分に正規化）`>=` `templateItem.updatedAt` を日付正規化したもの
   - **重複防止条件**: その日付の `Houseworks` に `templateHouseworkItemId == templateItem.id` を持つドキュメントが存在しない

### ルールの根拠

**`templateHouseworkItemId` による重複防止**

ユーザーが仮想 incomplete を `pendingApproval` などに遷移させると、その時点で `templateHouseworkItemId` を埋めた実 Housework が作成される。同じ日付・同じテンプレートアイテムに対する仮想 incomplete を引き続き表示してしまうと家事が二重に表示されてしまうため、ID 一致による除外でこれを防ぐ。

**`updatedAt` による表示範囲制御**

`updatedAt` を考慮しない場合、テンプレートに新しい家事を追加するとその曜日に該当する過去すべての日付にも仮想 incomplete が湧き出てしまい、「過去日付に未完了の家事が大量に出る」状態になる。

`updatedAt` を日付正規化（0時0分）して、表示対象日がそれ以降の場合にのみ表示することで、テンプレートに追加・編集された家事は「変更日以降の該当曜日」にのみ反映されるようになる。

### 状態遷移時の Housework 作成（Lazy 作成）

仮想 incomplete に対してユーザーがアクション（`pendingApproval` への遷移など）を行った時点で、初めて実 Housework を作成する。

作成内容:

| フィールド | 値 |
|---|---|
| `id` | 新規 UUID |
| `templateHouseworkItemId` | テンプレートアイテムの `id` |
| `date` | 操作が行われた表示対象日 |
| `title` | テンプレートアイテムの `title` をスナップショット |
| `point` | テンプレートアイテムの `point` をスナップショット |
| `state` | `pendingApproval`（または遷移先の状態） |
| `executor` | 操作したユーザー |

スナップショットされた `title` / `point` は以降テンプレート側を編集しても更新されない。完了済みの記録は当時の内容を保持する仕様とする。

### テンプレート編集後の見え方

| 操作 | 過去日付 | 当日以降 |
|---|---|---|
| テンプレートアイテムを追加 | 表示されない（`updatedAt` が今日以降のため） | 該当曜日に表示される |
| テンプレートアイテムを編集 | 編集前のスナップショットを持つ実 Housework はそのまま、仮想 incomplete は `updatedAt` 更新により表示が当日以降に絞られる | 編集後の内容で該当曜日に表示される |
| テンプレートアイテムを削除 | 編集前のスナップショットを持つ実 Housework はそのまま、仮想 incomplete は表示されなくなる | 表示されなくなる |
