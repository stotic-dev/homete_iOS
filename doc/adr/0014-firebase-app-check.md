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
* Firestore・Callable関数とも**導入と同時に強制適用する**。Callable関数は `enforceAppCheck: true`、Firestoreはコンソールでstg/prod両プロジェクトを適用済みにする
* `enforceAppCheck` は `src/appCheckOptions.ts` の1箇所に集約し、両関数で同じ設定を共有する

## 考慮した選択肢

* **App Attest（採用）**: Secure Enclaveの鍵でアプリの正当性を証明する。iOS 14以降で利用可能で、本プロジェクトのdeployment target 17.0では制約にならない
* **DeviceCheck**: iOS 11以降で使えるが、検証するのはデバイスであってアプリの正当性ではない。deployment targetの制約が無い以上、App Attestより弱い保証を選ぶ理由がない
* **Firestoreルールの厳格化のみ（#233）**: 認証済みユーザーによる大量アクセスを防げない。App Checkと排他ではないため、多層防御として併用する
* **モニタリング期間を挟んでから強制適用**: 一般には、検証に失敗する経路（App Check非対応の古いバージョンなど）を持つ既存ユーザーを締め出さないために必要な段取り。ただし本アプリは**未リリースで締め出す相手がいない**ため、期間を置く利益がなく、その間バックエンドが無防備なまま残るデメリットだけが残る。導入と同時に強制適用する方を採った
* **Callable関数の検証結果を自前でログに残す**: Callable関数はApp Checkのメトリクス対象サービスではないため、モニタリングするなら `request.app` の有無を自分で記録するしかない。しかし強制適用では未検証のリクエストがハンドラに到達しないので、ログは常に「検証済み」しか出さない。定数を出力するだけになるため入れない

## 決定結果

### 決定にあたり考慮したメリット

* 正規アプリ以外からのFirestore・Functionsアクセスを遮断でき、想定外の課金を防げる
* セキュリティルールでは防げない「認証済みユーザーによる大量アクセス」に対する層が増える
* 強制適用の切り替えが `appCheckOptions.ts` の1行とFirebaseコンソールの操作で完結する
* リリース前に有効化するため、ユーザーを締め出すリスクを負わずに最初から防御が効く

### 決定にあたり考慮したデメリット

* ローカル開発ではFirebaseコンソールへのデバッグトークン登録が必要になり、開発機やシミュレータを作り直すたびに手間が発生する（手順はCLAUDE.md参照）
* entitlementが増えるため、Xcode Cloudの自動署名でプロビジョニングプロファイルが再発行される
* リリース後にApp Attestの検証が想定外に失敗した場合、ユーザーはバックエンドに一切アクセスできなくなる。TestFlight配信の段階で実機での動作を必ず確認すること

## 補足: FirestoreとCallable関数で有効化の仕組みが違う

有効化の方法が2つのサービスで全く異なる。混同すると「コンソールで適用済みにしたのにFunctionsが素通しのまま」ということが起きるため、区別して扱う。

| | Firestore | Callable Functions |
|---|---|---|
| 強制適用の切り替え | Firebaseコンソール（App Check → APIs） | コードの `enforceAppCheck` + デプロイ |
| 検証を行う場所 | Firestoreバックエンド | デプロイされた関数のランタイム（firebase-functions SDK） |
| コンソールのメトリクス | あり | **なし**（App Checkのメトリクス対象サービスに含まれない） |
| モニタリング | コンソールのメトリクス | 手段なし（メトリクスもログも取れない） |

Callable関数では、firebase-functions SDKの `checkAppCheckToken` が `enforceAppCheck` の値に関係なく常に実行され、検証を通った場合だけ `request.app` が埋まる。`enforceAppCheck` が制御するのは拒否するかどうかだけ。

つまり `enforceAppCheck: false` はSDKのデフォルトと同一で、それ自体では何も有効化しない。**Callable関数の強制適用はコンソールでは切り替えられず、デプロイを伴う**点に注意する。

## 補足: エミュレータ・E2Eテストへの影響

`firebase/functions/test/e2e/` のテストはCallable関数をHTTP経由で呼ばず、Firestoreエミュレータに対してロジックを直接検証している。App Check検証はCallableのHTTPレイヤで行われるため、`enforceAppCheck` を `true` にしてもこれらのテストには影響しない。

## 参考

* [Firebase App Check (iOS)](https://firebase.google.com/docs/app-check/ios/app-attest-provider)
* [App Attest — Apple Developer](https://developer.apple.com/documentation/devicecheck/dcappattestservice)
