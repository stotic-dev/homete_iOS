# homete_iOS

homete の iOS アプリリポジトリ

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
