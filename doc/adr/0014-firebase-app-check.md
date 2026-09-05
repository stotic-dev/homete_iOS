## タイトル: Firebase App Checkを導入してバックエンドへの不正アクセスを防ぐ

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-08-31
* 技術的背景やその他関連チケット No: [#239](https://github.com/stotic-dev/homete_iOS/issues/239)、関連: [#233](https://github.com/stotic-dev/homete_iOS/issues/233)

## 文脈、背景や問題点の説明

`GoogleService-Info.plist` に含まれるAPIキーやプロジェクトIDはアプリバイナリから容易に抽出できるため、App Checkが無い状態ではcurlやスクリプトからFirestore・Cloud Functionsを直接叩ける。`notifyothercohabitants` や `synchouseworkretention` を連打されるとFunctions実行・FCM送信・Firestore書き込みの課金が膨らみ、課金上限のない個人開発では金銭的被害に直結する。

Firestoreセキュリティルールの厳格化（#233）は「他人のデータを読み書きさせない」ことは担保できるが、「正規ユーザーとして認証したうえで自分のデータに大量アクセスする」ことは防げない。呼び出し元が正規アプリであることを検証する層が別途必要。

## 決定事項

* iOSアプリにFirebase App Checkを導入し、配布ビルドでは **App Attest** を使う
* ローカル開発ビルドでは **Debug Provider** を使う。App Attestはシミュレータで動かず、Xcodeの開発用署名でも証明書検証に通らないため
* プロバイダの切り替えはコンパイル時に決める。Stg構成は「TestFlight配布だが開発用Firebaseプロジェクトを参照する」ためDEBUGを定義しており、DEBUGだけではローカルビルドと区別できない。Stg構成にだけ `STG` フラグを追加し、`#if DEBUG && !STG` でDebug Providerを選ぶ
* App Attestのentitlement（`com.apple.developer.devicecheck.appattest-environment`）はDebug構成で `development`、Stg/Release構成で `production`
* Callable関数（`notifyothercohabitants` / `synchouseworkretention`）に `enforceAppCheck` オプションを渡す口を用意する。**導入時点では `false`（モニタリングのみ）** とし、Firebaseコンソールのメトリクスで正規アプリからのリクエストが100%検証済みとして計上されることを確認してから `true` に切り替える
* `enforceAppCheck` は `src/appCheckOptions.ts` の1箇所に集約し、切り替えが1行の差分で済むようにする

## 考慮した選択肢

* **App Attest（採用）**: Secure Enclaveの鍵でアプリの正当性を証明する。iOS 14以降で利用可能で、本プロジェクトのdeployment target 17.0では制約にならない
* **DeviceCheck**: iOS 11以降で使えるが、検証するのはデバイスであってアプリの正当性ではない。deployment targetの制約が無い以上、App Attestより弱い保証を選ぶ理由がない
* **Firestoreルールの厳格化のみ（#233）**: 認証済みユーザーによる大量アクセスを防げない。App Checkと排他ではないため、多層防御として併用する
* **導入と同時に強制適用**: 検証に失敗する経路（古いバージョンのアプリ、デバッグトークン未登録の開発機など）があると既存ユーザーを締め出す。モニタリング期間を挟む方を採る

## 決定結果

### 決定にあたり考慮したメリット

* 正規アプリ以外からのFirestore・Functionsアクセスを遮断でき、想定外の課金を防げる
* セキュリティルールでは防げない「認証済みユーザーによる大量アクセス」に対する層が増える
* 強制適用の切り替えが `appCheckOptions.ts` の1行とFirebaseコンソールの操作で完結する

### 決定にあたり考慮したデメリット

* ローカル開発ではFirebaseコンソールへのデバッグトークン登録が必要になり、開発機やシミュレータを作り直すたびに手間が発生する（手順はCLAUDE.md参照）
* entitlementが増えるため、Xcode Cloudの自動署名でプロビジョニングプロファイルが再発行される
* モニタリング期間中は防御効果が無い。強制適用への切り替えを別途忘れずに行う必要がある

## 補足: エミュレータ・E2Eテストへの影響

`firebase/functions/test/e2e/` のテストはCallable関数をHTTP経由で呼ばず、Firestoreエミュレータに対してロジックを直接検証している。App Check検証はCallableのHTTPレイヤで行われるため、`enforceAppCheck` を `true` にしてもこれらのテストには影響しない。

## 参考

* [Firebase App Check (iOS)](https://firebase.google.com/docs/app-check/ios/app-attest-provider)
* [App Attest — Apple Developer](https://developer.apple.com/documentation/devicecheck/dcappattestservice)
