#!/bin/sh

set -e

case "$CI_WORKFLOW" in
    "Upload For AppStore")
        echo "=== Upload For AppStore workflow ==="

        # archive成功時のみ実行
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
        echo "==========================="
        ;;

    "VRT")
        echo "=== VRT workflow ==="

        # doc/adr/0005 検証ステップ1: SNAPSHOT_TESTING_RECORD=failed 実行時に
        # シミュレータプロセスが $CI_PRIMARY_REPOSITORY_PATH 配下（参照PNG）へ
        # 書き込めているかを git status で確認する。push は行わずログ出力のみ。
        # xcodebuildはbuild-for-testingとtest-without-buildingの2アクションに分かれるため、
        # 実際にテストが実行された後（test-without-building）の1回だけ確認する。
        if [ "$CI_XCODEBUILD_ACTION" != "test-without-building" ]; then
            echo "Skipping snapshot write-access check (CI_XCODEBUILD_ACTION=$CI_XCODEBUILD_ACTION)"
            exit 0
        fi

        cd "$CI_PRIMARY_REPOSITORY_PATH"

        SNAPSHOT_DIR="hometeSnapshotTests/__Snapshots__/PreviewTests.generated"

        echo "SNAPSHOT_TESTING_RECORD=$SNAPSHOT_TESTING_RECORD"
        echo "--- git status (short) for $SNAPSHOT_DIR ---"
        git status --short -- "$SNAPSHOT_DIR" || true
        echo "--- git diff --stat for $SNAPSHOT_DIR ---"
        git diff --stat -- "$SNAPSHOT_DIR" || true
        echo "==========================="
        ;;

    *)
        echo "Skipping ci_post_xcodebuild.sh (CI_WORKFLOW=$CI_WORKFLOW)"
        ;;
esac
