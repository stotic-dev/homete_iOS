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
        # 書き込めているかを確認する。push は行わずログ出力のみ。
        # xcodebuildはbuild-for-testingとtest-without-buildingの2アクションに分かれるため、
        # 実際にテストが実行された後（test-without-building）の1回だけ確認する。
        #
        # 実測: test-without-building は build-for-testing とは別のランナーで動いており、
        # $CI_PRIMARY_REPOSITORY_PATH に .git が存在しない（git status/diff が使えない）。
        # そのため git に依存せず、ci_scripts/__Snapshots__（../hometeSnapshotTests/__Snapshots__/
        # PreviewTests.generated への相対シンボリックリンク、リポジトリにコミット済み）経由で
        # ディレクトリの実在・ファイル数・更新時刻を確認する。
        if [ "$CI_XCODEBUILD_ACTION" != "test-without-building" ]; then
            echo "Skipping snapshot write-access check (CI_XCODEBUILD_ACTION=$CI_XCODEBUILD_ACTION)"
            exit 0
        fi

        echo "CI_PRIMARY_REPOSITORY_PATH=$CI_PRIMARY_REPOSITORY_PATH"
        echo "SNAPSHOT_TESTING_RECORD=$SNAPSHOT_TESTING_RECORD"

        cd "$CI_PRIMARY_REPOSITORY_PATH"

        if [ -d .git ]; then
            echo "✓ .git exists on this runner"
        else
            echo "✗ .git NOT found on this runner (test-without-building may run on a separate runner from build-for-testing)"
        fi

        SNAPSHOT_DIR="hometeSnapshotTests/__Snapshots__/PreviewTests.generated"
        CI_SCRIPTS_SNAPSHOT_DIR="ci_scripts/__Snapshots__"

        for DIR in "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR"; do
            echo "--- $DIR ---"
            if [ -d "$DIR" ]; then
                echo "✓ exists. File count: $(find "$DIR" -name '*.png' | wc -l | tr -d ' ')"
                echo "newest 5 files by mtime:"
                find "$DIR" -name '*.png' -exec stat -f '%Sm %N' -t '%Y-%m-%dT%H:%M:%S' {} \; | sort -r | head -5
            else
                echo "✗ NOT found"
            fi
        done

        if [ -d .git ]; then
            echo "--- git status (short) for $SNAPSHOT_DIR ---"
            git status --short -- "$SNAPSHOT_DIR" || true
        fi
        echo "==========================="
        ;;

    *)
        echo "Skipping ci_post_xcodebuild.sh (CI_WORKFLOW=$CI_WORKFLOW)"
        ;;
esac
