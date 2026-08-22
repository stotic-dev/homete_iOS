---
paths:
  - "LocalPackage/Sources/**/*.swift"
---

# Environmentからの依存取得ルール

Viewが`AppDependencies`配下のClient・UseCase・Managerを使うときは、**`AppDependencies`全体ではなく、使うものだけをkeypathで個別に取り出す**。

```swift
// ✅ 正しい: 使う依存だけをkeypathで宣言する
@Environment(\.appDependencies.notificationPermissionUseCase) var notificationPermissionUseCase
@Environment(\.appDependencies.analyticsClient) var analyticsClient

// ❌ 誤り: コンテナごと取り出して呼び出し側でぶら下げる
@Environment(\.appDependencies) var appDependencies
// ...
appDependencies.analyticsClient.log(.somethingHappened())
```

## なぜ個別に取り出すのか

- **そのViewが何に依存しているかがプロパティ宣言だけで分かる。** コンテナごと持つと、依存の把握に`body`とプレゼンテーションロジックを全部読む必要が出る。レビューで「このViewはこんなものまで触っていたのか」という見落としが起きるのはこのパターン
- **意図しない依存へ手が伸びにくくなる。** `appDependencies.`と打てば全Clientが補完に出てくるため、本来そのViewの責務ではないClientを気軽に呼べてしまう
- **呼び出し箇所が短くなり、テスト・Previewで差し替える対象も明示される**

既存コード（`SignInUpWithAppleButton`、`PremiumIntroductionView`、`CohabitantRegistrationProcessingLeader`など）はこの形になっている。新規実装もこれに倣うこと。

## 例外

`AppDependencies`全体を受け取ってよいのは、**依存を配る／組み立てることが責務のレイヤ**に限る。

- `DependenciesInjectLayer` — Environmentへ注入する層そのもの
- `AppTabView` のようにStore群を`AppDependencies`から生成するファクトリ処理
- デバッグ画面などで依存をまるごと差し替える箇所（`.environment(\.appDependencies, .previewValue)`）

「画面のプレゼンテーションロジックから使う」用途は例外に当たらない。

## 関連: デバッグ画面は実依存を継承しない

デバッグ用の画面で本番フローを再現する場合、Storeだけを差し替えても`AppDependencies`と`RouteResolver`はrootのlive実装を継承したままになる。Analytics送信・OSの権限ダイアログ・課金フローといった副作用が実環境に飛ぶため、`.environment(\.appDependencies, .previewValue)`とダミーの`RouteResolver`を必ず併せて注入する（`DebugOnboardingScreen`が実例）。
