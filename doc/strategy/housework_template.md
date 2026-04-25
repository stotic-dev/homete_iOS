# 家事週間テンプレート機能 対応方針

関連Issue: [#67 家事の週間テンプレート機能の追加](https://github.com/stotic-dev/homete_iOS/issues/67)

## 概要

毎週繰り返される定型的な家事（例: 月曜日はゴミ出し、水曜日は掃除）をテンプレートとして登録し、
週単位で一括適用できる機能を追加する。

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
      "title": String,        // 家事名
      "point": Int            // 家事ポイント
    },
    ...
  ]
}
```

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
- `Days/{dayOfWeek}` の書き込み時に Firestore トランザクションで現在の `version` を確認し、読み取り時と一致すれば `version + 1` して保存。不一致なら書き込みを拒否してUIにエラーを通知する
- `version` はテンプレートドキュメントに集約することで、どの曜日が更新されても整合性を保つ

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

**トレードオフ**

- 1曜日内のアイテムを個別追加・削除する場合、`items` 配列全体を書き直す必要がある
  - `arrayUnion` / `arrayRemove` はオブジェクト配列の要素更新に向かないため
  - テンプレートのアイテムIDはFirestoreドキュメントIDではなくアプリ側でUUIDを割り当てて管理する

### 既存コレクションへの影響

**`Houseworks` コレクション**

変更なし。テンプレートを適用する際は、テンプレートのアイテムをもとに `HouseworkItem` を生成して `Houseworks` へ書き込む。生成ロジックは既存の `HouseworkClient.insertOrUpdateItem` を再利用する。

**`Cohabitant` ドキュメント**

適用されるのは `Cohabitant` の `Houseworks` なので、適用済み状態も `Cohabitant` に属する情報として管理する。テンプレートが複数になっても対応できるよう `templateId` をキーにしたマップ形式で持つ。

```
Cohabitant/{cohabitantId}
  - id: String
  - members: [String]
  - appliedTemplates: {              // 追加
      [templateId]: {
        lastAppliedWeek: String,     // 例: "2026-W17"
        lastAppliedVersion: Int      // 適用時の template の version
      }
    }
```

**スキップロジック（自動適用時）:**

| lastAppliedWeek | lastAppliedVersion | 結果 |
|---|---|---|
| 先週以前 | 任意 | 適用（新しい週） |
| 今週 | 現在の version と異なる | 適用（今週テンプレートが変更された） |
| 今週 | 現在の version と一致 | スキップ（今週すでに同じ内容で適用済み） |

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

### 新規追加するファイル

| 種別 | モジュール | ファイル | 概要 |
|---|---|---|---|
| Feature | `HouseworkTemplateFeature`（新規） | `HouseworkTemplateView.swift` 等 | テンプレート設定・管理画面 |
| Feature | `HouseworkTemplateFeature`（新規） | `HouseworkTemplateEmptyView.swift` | テンプレートが0件の初期状態のEmpty表示 |
| Domain Model | `HometeDomain` | `HouseworkTemplateMeta.swift` | テンプレートのメタ情報（templateId, name, version） |
| Domain Model | `HometeDomain` | `HouseworkTemplateDay.swift` | 曜日ごとの家事定義（dayOfWeek, items） |
| Domain Model | `HometeDomain` | `HouseworkTemplateItem.swift` | テンプレートアイテム（title, point） |
| Domain Model | `HometeDomain` | `HouseworkTemplateEditor.swift` | 編集中ユーザー情報（userId, updatedAt） |
| Client | `HometeDomain` | `HouseworkTemplateClient.swift` | テンプレートのCRUD・Presence管理 |
| Store | `HometeDomain` | テンプレート画面用Store | テンプレート一覧・編集のUI状態管理 |

### 既存ファイルへの変更

| ファイル | モジュール | 変更内容 |
|---|---|---|
| `CollectionPath.swift` | `HometeInfrastructure` | `houseworkTemplates = "HouseworkTemplates"`、`days = "Days"`、`editors = "Editors"` を追加 |
| `FirestoreExtensionForReferencePath.swift` | `HometeInfrastructure` | `houseworkTemplateRef(cohabitantId:templateId:)`、`houseworkTemplateDaysRef`、`houseworkTemplateEditorRef` を追加 |
| `CohabitantData.swift` | `HometeDomain` | `appliedTemplates: [String: AppliedTemplateInfo]` フィールドを追加 |
| `AppDependencies.swift` | `HometeDomain` | `HouseworkTemplateClient` を追加 |
| `AppRoute.swift` | `HometeDomain` | `.houseworkTemplate` case を追加 |
| `RouteResolverInjection` | `AppRoot` | `.houseworkTemplate` → `HouseworkTemplateView` の解決を追加 |
| `Package.swift` | `LocalPackage` | `HouseworkTemplateFeature` ターゲットを追加、`AppRoot` の依存に追加 |
| Firebase Functions | `firebase/functions/src/` | `applyWeeklyTemplate` Scheduled Function を追加 |

### 画面データの更新タイミング

#### テンプレート一覧・閲覧画面

閲覧は最新状態でなくても致命的ではなく、リアルタイムリスナーを常時張るコストが見合わないため、画面表示時のワンショット取得とする。

| タイミング | 対象 | 方法 |
|---|---|---|
| 画面表示時 | `HouseworkTemplates`（メタ一覧）+ `Days` | ワンショット |

#### 編集画面

編集中に他のメンバーの変更やPresenceをリアルタイムに反映する必要があるため、編集モードに入った時点でSnapshotListenerを開始する。リスナーは編集モードを抜けた時点で解除し、不要なコストを避ける。

| タイミング | 対象 | 方法 | 目的 |
|---|---|---|---|
| 編集モード開始時 | `Days` | SnapshotListener 開始 | 他メンバーの変更をリアルタイムに検知 |
| 編集モード開始時 | `Editors` | SnapshotListener 開始 | 誰が編集中かをリアルタイム表示 |
| 編集モード終了時 | `Days`・`Editors` | SnapshotListener 解除 | 不要なリスナーを解放 |

#### コンフリクト発生時

編集モード中はすでに `Days` のSnapshotListenerが張られているため、コンフリクト後も変更は自動的に流れてくる。追加の再取得は不要で、リスナーの最新値でUIを更新してエラーを通知する。

| タイミング | 対象 | 方法 |
|---|---|---|
| 書き込み失敗（version不一致）時 | - | リスナーの最新値でUI更新 + エラー表示 |

#### フロー概要

```
閲覧画面 ─ 表示時ワンショット ─ リスナーなし
                ↓ 編集ボタンタップ
編集画面 ─ Days + Editors の SnapshotListener 開始
                ↓ 保存 / キャンセル
          ─ SnapshotListener 解除
                ↓ 保存時に version が不一致（コンフリクト）
          ─ リスナーの最新値でUI更新 + エラー表示
```

### テンプレート適用フロー

#### 適用の種類

テンプレートの適用には手動と自動の2種類がある。

| 種類 | トリガー | 実行場所 |
|---|---|---|
| 手動適用 | ユーザー操作 | クライアント（iOS） |
| 自動適用 | 毎週月曜0時（JST） | バックエンド（Cloud Functions Scheduled） |

クライアント側で自動適用を行うと複数ユーザーから同時に適用されるリスクがあるため、自動適用はバックエンドのバッチ処理で行う。

#### 対象日付の仕様（手動適用）

- 適用範囲は現在日付〜現在日付+6日（7日間）に固定する
- ユーザーによる日付選択は行わない
- 対象7日間の中に `incomplete` の家事が存在する日が1日でもあれば、上書きになるためユーザーに確認を求める

#### 上書き方針

テンプレート適用は曜日単位で完全上書きとする。

| 家事の状態 | 扱い |
|---|---|
| `incomplete`（未完了） | 削除対象 |
| `pendingApproval`（承認待ち） | 残す |
| `completed`（完了済み） | 残す |

テンプレートから新規追加される家事は常に `incomplete` 状態で作成されるため、完了・承認済みの家事には影響しない。

#### 手動適用ステップ

1. ユーザーが「適用する」を実行（適用範囲は現在日付〜+6日の7日間に自動設定）
2. 対象7日間の `Days` サブコレクション該当ドキュメントを取得（最大7読み取り）
3. 対象7日間の中に `incomplete` の家事が存在する日が1日でもあれば上書き確認ダイアログを表示
4. 確認後、対象7日間の `incomplete` 状態の家事を全件削除（`HouseworkClient.removeItem` を使用）
5. テンプレートのアイテムをもとに `incomplete` 状態の `HouseworkItem` を生成し、`DailyHouseworkMetaData` で `indexedDate` と `expiredAt` を設定
6. `HouseworkClient.insertOrUpdateItem` で `Houseworks` へ書き込み

#### 自動適用ステップ（Cloud Functions Scheduled）

毎週月曜0時（JST）に Firebase Cloud Functions の Scheduled Functions で実行する。

```typescript
export const applyWeeklyTemplate = onSchedule(
  { schedule: "every monday 00:00", timeZone: "Asia/Tokyo" },
  async (event) => { ... }
);
```

1. 全 `Cohabitant` ドキュメントを取得
2. 各 Cohabitant について `appliedTemplates` を確認し、スキップ判定を行う
   - `lastAppliedWeek === 今週` かつ `lastAppliedVersion === 現在の version` → スキップ
   - `Days` にアイテムが1件もない → スキップ
3. 適用対象の場合、翌週の `incomplete` 家事を全件削除してテンプレートのアイテムを書き込む（Firestore バッチ書き込みで削除・追加を1リクエストにまとめる）
4. `Cohabitant.appliedTemplates[templateId]` の `lastAppliedWeek` と `lastAppliedVersion` を更新
