#!/bin/bash

# 引数チェック
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <ipa_path> <api_key> <api_issuer> <apple_id>"
  exit 1
fi

# 引数の割り当て
IPA_PATH="$1"
API_KEY="$2"
API_ISSUER="$3"
APPLE_ID="$4"

# 一時ディレクトリ作成
TMP_DIR=$(mktemp -d)

# 1. ipaを一時ディレクトリに展開
unzip -q "$IPA_PATH" -d "$TMP_DIR"

# 2. Info.plistのパスを取得
APP_PATH=$(find "$TMP_DIR/Payload" -name "*.app" | head -n 1)
PLIST_PATH="$APP_PATH/Info.plist"

# 3. バージョン・ビルド番号を取得
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PLIST_PATH")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_PATH")
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$PLIST_PATH")

# 4. altoolでアップロード
xcrun altool \
  --upload-package "$IPA_PATH" \
  --type ios \
  --apple-id "$APPLE_ID" \
  --bundle-version "$BUILD" \
  --bundle-short-version-string "$VERSION" \
  --bundle-id "$BUNDLE_ID" \
  --apiKey "$API_KEY" \
  --apiIssuer "$API_ISSUER"

# 5. 一時ディレクトリ削除
rm -rf "$TMP_DIR"