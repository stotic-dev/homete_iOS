#!/bin/sh

set -e

# Upload For AppStoreワークフロー以外では何もしない
if [ "$CI_WORKFLOW" != "Upload For AppStore" ]; then
    echo "Skipping ci_pre_xcodebuild.sh (CI_WORKFLOW=$CI_WORKFLOW)"
    exit 0
fi

# Xcode Cloudが発行するビルド番号を全Targetに反映
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcrun agvtool new-version -all "$CI_BUILD_NUMBER"
echo "✓ Build number updated to $CI_BUILD_NUMBER"
