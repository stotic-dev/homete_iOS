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

        # doc/adr/0005 検証ステップ1（改訂）: 実測の結果、test-without-building は
        # build-for-testing とは別の使い捨てランナーで動いており、$CI_PRIMARY_REPOSITORY_PATH
        # が空文字（gitチェックアウトが一切存在しない）ことが判明した。Apple公式フォーラムでも
        # 「テストを実行する環境にはソースコードがクローンされない」と明記されており、
        # test-without-building 側での記録・push は構造的に成立しない。
        #
        # そこで、gitチェックアウトが存在する build-for-testing 側の ci_post_xcodebuild.sh から、
        # 直前のビルドで既に生成済みの -testProductsPath を使い、自前で
        # `xcodebuild test-without-building` を実行する。同一ランナー内で完結するため、
        # SNAPSHOT_TESTING_RECORD=failed による書き込みがそのまま git 差分として検出できるはず。
        # 現段階では commit/push はまだ行わず、書き込みが実際に発生するかをログ出力のみで確認する。
        if [ "$CI_XCODEBUILD_ACTION" != "build-for-testing" ]; then
            echo "Skipping VRT CLI re-run (CI_XCODEBUILD_ACTION=$CI_XCODEBUILD_ACTION)"
            exit 0
        fi

        echo "CI_PRIMARY_REPOSITORY_PATH=$CI_PRIMARY_REPOSITORY_PATH"
        echo "SNAPSHOT_TESTING_RECORD=$SNAPSHOT_TESTING_RECORD"
        echo "CI_XCODE_CLOUD=$CI_XCODE_CLOUD"

        cd "$CI_PRIMARY_REPOSITORY_PATH"

        if [ -d .git ]; then
            echo "✓ .git exists on this runner (build-for-testing)"
        else
            echo "✗ .git NOT found (unexpected on build-for-testing runner)"
        fi

        TEST_PRODUCTS_PATH="/Volumes/workspace/TestProducts.xctestproducts"
        if [ ! -d "$TEST_PRODUCTS_PATH" ]; then
            echo "✗ $TEST_PRODUCTS_PATH not found. Skipping VRT record run."
            exit 0
        fi
        echo "✓ $TEST_PRODUCTS_PATH exists"

        DEVICE_LINE=$(xcrun simctl list devices available | grep -m1 "iPhone 16 (")
        DEVICE_ID=$(echo "$DEVICE_LINE" | grep -oE '[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}')

        if [ -z "$DEVICE_ID" ]; then
            echo "✗ iPhone 16 simulator not found. Skipping VRT record run."
            exit 0
        fi
        echo "Using simulator: $DEVICE_ID ($DEVICE_LINE)"

        echo "--- xcodebuild test-without-building (self-invoked on build-for-testing runner) ---"
        xcodebuild test-without-building \
            -destination "platform=iOS Simulator,id=$DEVICE_ID" \
            -testProductsPath "$TEST_PRODUCTS_PATH" \
            -testPlan hometeSnapshotTestsForCI \
            -resultBundlePath /Volumes/workspace/vrt-record-resultbundle.xcresult \
            || echo "xcodebuild test-without-building exited non-zero (isRecordingSnapshotsが真ならXCTFailは抑止されるはずなので要調査)"

        SNAPSHOT_DIR="hometeSnapshotTests/__Snapshots__/PreviewTests.generated"
        CI_SCRIPTS_SNAPSHOT_DIR="ci_scripts/__Snapshots__"

        echo "--- git status (short) for snapshot dirs ---"
        git status --short -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR" || true
        echo "--- git diff --stat for snapshot dirs ---"
        git diff --stat -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR" || true
        echo "==========================="
        ;;

    *)
        echo "Skipping ci_post_xcodebuild.sh (CI_WORKFLOW=$CI_WORKFLOW)"
        ;;
esac
