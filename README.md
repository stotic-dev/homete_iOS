# homete_iOS

homete の iOS アプリリポジトリ

## ドキュメント

- [コードスタイル統一: SwiftFormat & SwiftLint](doc/tech/code-style.md) — フォーマッタ/リンタの役割分担と使い方
- [マルチモジュール構成](doc/multimodules_structure.md) — SPM モジュール構成

## ローカル環境構築

### xcconfig（シークレット設定）

`homete/Resouces/Secret.xcconfig`（本番用）・`homete/Resouces/Secret_dev.xcconfig`（開発用）はAdMobアプリID・広告ユニットID・RevenueCatのCustom Scheme URL・RevenueCatのAPIキー（`REVENUECAT_API_KEY`）などのシークレット値を含むため、gitignoreされておりリポジトリには含まれません。

`REVENUECAT_API_KEY`はRevenueCatダッシュボードの Project settings > API keys から発行される、iOSアプリ用のPublic SDK Keyを設定してください。

初回セットアップ時は、同ディレクトリの `.xcconfig.sample` をコピーして値を埋めてください。

```bash
cp homete/Resouces/Secret.xcconfig.sample homete/Resouces/Secret.xcconfig
cp homete/Resouces/Secret_dev.xcconfig.sample homete/Resouces/Secret_dev.xcconfig
```

実際の値はチームメンバーに確認してください。ファイルが無い状態でもビルド自体は通りますが、AdMob/RevenueCatの初期化に必要な値が空になります。

## 証明書・プロビジョニングプロファイルの管理

証明書管理には [Fastlane Match](https://docs.fastlane.tools/actions/match/) を使用しています。

### プロファイルの更新

```bash
# 開発用
bundle exec fastlane update_profile

# 本番用
bundle exec fastlane update_profile_prod
```

### 証明書が Developer Portal と不一致になった場合

以下のエラーが出た場合は証明書が不一致になっています。

```
Certificate 'XXXXXXXXXX' (stored in your storage) is not available on the Developer Portal
```

全ての証明書・プロビジョニングプロファイルを一掃してから再生成してください。

```bash
# 証明書・プロビジョニングプロファイルを全削除
bundle exec fastlane nuke_certificates

# 削除後に再生成
bundle exec fastlane update_profile         # 開発用
bundle exec fastlane update_profile_prod    # 本番用
```
