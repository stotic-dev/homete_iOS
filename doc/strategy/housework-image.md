# 家事の画像（プレミアムプラン限定） 実装方針

> 関連Issue: [#457 Feature: プレミアムプラン限定で家事に画像を追加できるようにする](https://github.com/stotic-dev/homete_iOS/issues/457)
> ブランチ: `feat/457-housework-image`
> ADR: [ADR-0067 家事に添える画像の実体をFirebase Storageに置き、参照だけを家事のドキュメントに持たせる](../adr/0067-housework-images-on-firebase-storage.md)
> 関連: [housework-memo.md](housework-memo.md)（ADR-0034）、[premium_plan.md](../premium_plan.md)

## ステータス

- [x] 要件確定（Issueの確定事項、2026-10-18）
- [x] 設計確定
- [x] iOS側の実装完了
- [x] iOS側のテスト追加完了
- [ ] homete_backend側の実装（下記「バックエンドの対応」）
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

プレミアムプランの人が、その日の家事に写真を添えられるようにする。ゴミの分別方法・仕上がりの見本・買う商品の見た目など、
文字では伝えにくい家事の情報を家事そのものに残し、チャットに散らばっていた写真を家事を見るだけで分かるようにする。

## 要件

Issueの確定事項に、実装時に決めた事項（2026-11-03）を加えたもの。

- 対象はその日の家事（`HouseworkItem`）。家事詳細と、家事を追加する画面から添える。テンプレート・いつもの家事は対象外
- 写真はフォトライブラリから選ぶか、カメラで撮る。1家事あたり10枚まで
- 端末で長辺1,600px・JPEG・2MBまでに縮小し、位置情報などのメタデータを落としてから上げる
- 追加できるのはプレミアムプランの本人だけ。閲覧は同居人グループの全員（無料プランを含む）
- 消せるのはプレミアムプランの人と、その画像を追加した人（解約後も自分が追加した画像は消せる）
- 無料プランでも「画像を追加」を出し、押したらPaywall（`step=housework_image`）へ誘導する
- 追加できるのは未完了の家事だけ（メモと同じ）。完了済み・「やらない」の家事では閲覧と削除だけ。削除は家事の状態に関係なくできる
- 家事を追加する画面で、くり返す家事（テンプレートに登録する）には添えられない。選んだ画像は残したまま隠し、くり返しをやめるとまた出る
- 画像の追加・削除では同居人に通知しない。完了通知にも載せない
- 家事ボードの行に「画像あり」のアイコン（`photo`）を出す
- 「もう一度やる」と、テンプレートの家事を別の日へまわすときに作る家事は、画像を引き継がない（同じIDのまま日付を移す場合は引き継ぐ）
- 保持期限は家事と同じ。家事が消えたら画像の実体も消す（バックエンド）

## 設計

### データ

`HouseworkItem.images: [HouseworkImage]?`（`HometeModel`）。参照は`id`・`storagePath`・`uploaderId`。

- `nil`: 一度も画像を添えていない（ドキュメントに`images`が無い）
- 空の配列: 添えた画像をすべて消した。旧アプリ対策のルール（`images`を消す更新を拒否）のため、空でも残す

状態を変えるメソッドはすべて`images`を引き継ぐ（`makeRedone`・`makePostponedCopy`を除く）。テストは`HouseworkItemTest.ImageCase`。

### プラン判定

`HouseworkImagePolicy`（`HometeModel`）。`addableCount`・`validateAdding`・`canDelete`を持つ。ADR-0034と同じく、操作している本人の
`SubscriptionStore.isPremium`で判定し、ルールはプランに依存しない検査だけにする。

### 書き込み

| 操作 | 順番 | 実装 |
|---|---|---|
| 家事詳細で追加 | 縮小 → 実体を上げる → 参照を`arrayUnion`（未登録の家事はドキュメントごと作る。同居人が先に作っていたら、トランザクションの中で参照の追記に切り替える）。参照の書き込みに失敗したら実体を消す | `HouseworkListStore.addImages` → `HouseworkImageUseCase.add` |
| 家事を追加する画面で登録 | 選んだ時点で縮小して入力中の家事に持つ → 登録時に実体を上げる → 参照付きの家事を一括で書く。失敗したら実体を消す | `HouseworkListStore.register` → `HouseworkImageUseCase.register` |
| 削除 | 参照を`arrayRemove` → 実体を消す（失敗はログだけ） | `HouseworkListStore.removeImage` → `HouseworkImageUseCase.remove` |

Clientは`HouseworkImageClient`（実体の`upload`・`delete`・`fetch`）と、`HouseworkClient`の`addImages`・`removeImage`（参照）。
`liveValue`は`StorageService`（Firebase Storage）と`HouseworkImageCache`（端末のキャッシュ）で実装する。
ログアウト（退会を含む）したら、`RootView`が`clearCache`で端末のキャッシュを消す。

### 画面

| 画面 | 変更 |
|---|---|
| 家事詳細 | メモの下に画像の欄（`HouseworkDetailImageComponent`）。サムネイルのグリッド、「画像を追加」（写真を選ぶ／写真を撮る）、無料プランは王冠付きのボタンでPaywall |
| 拡大表示 | `HouseworkImageViewerScreen`（フルスクリーン、左右にスワイプ、消せる画像だけゴミ箱のボタン、消す前に確認）。`screen_view`は`housework_image_viewer` |
| 家事を追加する画面 | `ManualHouseworkForm`の「登録する家事」の下に画像の欄。サムネイルをタップすると外す確認 |
| 家事ボードの行 | タイトル横に「画像あり」のアイコン |

画像の欄の見た目は`HouseworkImageSectionContent`、追加ボタンの状態は`HouseworkImageAddState`、写真を選ぶ・撮る画面は
`houseworkImagePicker`（`PhotosPicker`と`CameraPicker`）に分けた。カメラの権限文言（`NSCameraUsageDescription`）は
`homete.xcodeproj`のビルド設定と`InfoPlist.xcstrings`に入れた。

### Analytics

`housework`イベントの`action`に`add_image`・`remove_image`、`paywall`の`step`に`housework_image`、`screen_view`に`housework_image_viewer`
を足した（[analytics_events.md](../analytics_events.md)）。

## バックエンドの対応（homete_backend）

このリポジトリには含まれない。リリース前にhomete_backend側で揃える必要がある。揃うまで、画像の追加はStorageへの書き込みで失敗する（stgで`403 Permission denied.`になることを2026-11-03に確認）。

- ルール・App Check: [homete_backend#30](https://github.com/stotic-dev/homete_backend/issues/30)
- 家事・グループが消えたときの画像の削除: [homete_backend#31](https://github.com/stotic-dev/homete_backend/issues/31)


- [ ] STG・本番でStorageバケットを有効化し、`firebase.json`に`storage.rules`を足す
- [ ] `storage.rules`: `Cohabitant/{cohabitantId}/Houseworks/{houseworkId}/{imageId}`を、グループのメンバーだけが読み書きできるようにする。
      書き込みは`contentType == 'image/jpeg'`・2MB以下に制限する。ルールのユニットテストをCIに足す
- [ ] Firestoreルール: `images`は10件まで、各要素は`id`・`storagePath`・`uploaderId`だけ。既存の`images`があれば更新後も残る（`keepsMemo`と同じ）
- [ ] 家事のドキュメントが消えたとき（TTLを含む）に、Storageの家事のフォルダを消すFirestoreトリガー
- [ ] `deleteuserdata`でグループごと消すときに、Storageのグループのフォルダも消す（3人以上のグループで1人が退会した場合は残す）
- [ ] App Check（Storage）の強制適用
- [ ] （任意）Storageのルールで`Account/{uid}.isPremium`を見て、追加をプレミアムプランに限る（ADR-0067「考慮した選択肢」）

## リリース前の確認

- [x] プライバシーマニフェスト（`PrivacyInfo.xcprivacy`）に「写真またはビデオ」を足す
- [x] プライバシーポリシー（`docs/privacy.html`）に、写真の取得・保存・共有・削除を追記する
- [ ] App Store Connectのプライバシーラベルに「ユーザーコンテンツ：写真またはビデオ」（ユーザーに紐づく・トラッキングに使わない・アプリの機能）を足す。App Store Connectで手で設定する
- [ ] App ReviewのUGC要件（同居人だけに共有される閉じた空間であること）の説明を用意する
- [ ] RevenueCatのPaywallの訴求文言に画像を載せるか決める（[premium_plan.md](../premium_plan.md)）

## 見送った項目

- 完了時の「やった証拠」写真、テンプレート・いつもの家事の画像（Issueの代替案。別Issueで検討）
- 画像の拡大表示でのピンチズーム
