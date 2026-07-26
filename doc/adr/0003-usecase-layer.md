## タイトル: 複数Storeを合成するUseCase層の導入

* **承認済**
* stotic-dev
* 日付: 2026-07-25
* 技術的背景: RevenueCat SDK導入（[ADR-0004](0004-revenuecat-sdk-adoption.md)）に伴う認証⇔サブスクリプション連携ロジックの置き場所検討

## 文脈、背景や問題点の説明

RevenueCat連携の実装で、ログイン/ログアウトに応じて `SubscriptionStore.logIn/logOut` を呼び出す必要が生じた。既存の Client + Store パターンでは Store は Client 層にのみ依存し、Store 同士が互いを参照する構造は存在しない。そのため、この連携ロジックは唯一 `AccountAuthStore` と `AccountStore` の両方の状態を参照できる `RootView`（View層）に実装されていた。

**複数Storeを跨ぐオーケストレーションロジックは、今後もView層に書き続けて良いか？**

## 決定事項

* 複数の Store・ドメインモデル・Client を合成する処理を表現する「UseCase」層を `HometeDomain` に新設する
* UseCase は複数の Store インスタンスを直接保持してよい（Store 同士が互いを参照することは引き続き禁止のまま）
* View（`RootView` 等）は UseCase を呼び出すことで、クロスStoreのオーケストレーションロジックをプレゼンテーションロジックから分離する
* 命名は `〇〇UseCase` とし、メソッド名は `execute` のような汎用名ではなく用途が分かる名前にする
* 最初の適用例として、認証状態変化とサブスクリプション状態の同期を行う `AuthSubscriptionSyncUseCase` を `RootView.onChangeAuth()` から抽出する

## 考慮した選択肢

* **View（RootView）に処理を残す（現状維持）**: 追加実装は不要だが、View がオーケストレーションロジックを持ち続けて肥大化し、SwiftUIの`View`に依存する形でしかテストできない
* **AccountAuthStoreにSubscriptionStoreへの参照を持たせる**: Store間の直接依存が発生し、既存のClient + Store DIパターンの規約を崩す。将来的に依存関係が複雑化するリスクがある
* **UseCase層を新設（採用）**: Store間の直接依存を避けつつ、View側からオーケストレーションロジックを排除できる。単体でテスト可能

## 決定結果

### 決定にあたり考慮したメリット

* View（SwiftUI）に依存せず、複数Storeを跨ぐビジネスロジックを単体テストできる
* Store は「単一ドメインの状態管理」という責務に留まり、Store間の直接依存を防げる
* 今後増えうる複数Store連携処理（例: アカウント削除時の関連データクリーンアップ）の受け皿になる

### 決定にあたり考慮したデメリット

* `View → Store → Client → Service` という既存の4層構造に新しい層が加わり、アーキテクチャがやや複雑になる
* 「ViewからStoreを直接呼ぶケース」と「UseCase経由で呼ぶケース」の使い分けルールを徹底する必要がある（複数Storeを跨ぐ場合のみUseCaseを使う、単一Storeで完結する場合は直接呼ぶ、という運用ルールを前提とする）

## 参考

* [ADR-0001: マルチモジュール構成の採用](0001-spm-multimodule-structure.md)
* [ADR-0004: RevenueCat SDKの採用](0004-revenuecat-sdk-adoption.md)
