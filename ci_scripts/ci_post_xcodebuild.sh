#!/bin/sh

set -e

# Upload For AppStoreワークフローのarchive成功時のみ実行
if [ "$CI_WORKFLOW" != "Upload For AppStore" ]; then
    echo "Skipping ci_post_xcodebuild.sh (CI_WORKFLOW=$CI_WORKFLOW)"
    exit 0
fi

if [ "$CI_XCODEBUILD_ACTION" != "archive" ]; then
    echo "Skipping git tag creation (CI_XCODEBUILD_ACTION=$CI_XCODEBUILD_ACTION)"
    exit 0
fi

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Marketing version（CFBundleShortVersionString）からタグ名を生成
APP_VERSION=$(xcrun agvtool what-marketing-version -terse1)
TAG_NAME="v${APP_VERSION}"
echo "Creating git tag: $TAG_NAME"

# Xcode CloudではGit設定がされていないため最低限の設定を行う
git config user.email "taichis844@gmail.com"
git config user.name "stotic-dev"

# 既存タグがあれば上書き
git tag -f "$TAG_NAME"

# push用の認証情報（GITHUB_TOKEN）が設定されている場合のみpushを試みる
if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPOSITORY" ]; then
    REMOTE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    git push "$REMOTE_URL" "$TAG_NAME" --force
    echo "✓ Pushed tag $TAG_NAME"
else
    echo "WARNING: GITHUB_TOKEN or GITHUB_REPOSITORY is not set. Tag created locally but not pushed."
fi
