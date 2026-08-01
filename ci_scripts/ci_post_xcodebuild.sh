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

        # doc/adr/0005: 実測の結果、test-without-building は build-for-testing とは
        # 別の使い捨てランナーで動いており、$CI_PRIMARY_REPOSITORY_PATH が空文字
        # （gitチェックアウトが一切存在しない）ことが判明した。Apple公式フォーラムでも
        # 「テストを実行する環境にはソースコードがクローンされない」と明記されており、
        # test-without-building 側での記録・push は構造的に成立しない。
        #
        # そこで、gitチェックアウトが存在する build-for-testing 側の ci_post_xcodebuild.sh から、
        # 直前のビルドで既に生成済みの -testProductsPath を使い、自前で
        # `xcodebuild test-without-building` を2回実行する（① verify専用パスで純粋比較のみ行い
        # ログで可視化 → ② 記録パスで実際にミスマッチ/未記録分を書き込む）。同一ランナー内で
        # 完結するため、書き込みがそのまま git 差分として検出できる（検証ステップ1・Build 212で確認済み）。
        # 差分があれば通常のcommitメッセージでcommitし、PRブランチへpushする（検証ステップ2）。
        #
        # このpush自体が新たなVRTビルドを誘発して無限ループにならないよう、[ci skip] ではなく
        # Xcode Cloud側のワークフロー起動条件（Custom Conditions）で「スナップショットディレクトリのみの
        # 変更では起動しない」設定を別途入れている。[ci skip] を使わないのは、それがGitHub Actions側の
        # Dangerワークフローの起動も止めてしまうため。
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

        # SNAPSHOT_TESTING_RECORD はワークフロー全体（自己呼び出し版・Xcode Cloud公式の
        # 別ランナー版）で共有される xctestplan の環境変数のため、ここでは自己呼び出しの
        # 各回ごとに明示的に値を指定し、ワークフロー側の設定値に依存させない。

        # ① verify専用パス: 明示的に空を指定して純粋比較のみを行う（記録は一切しない）。
        # ここでの失敗はミスマッチ/未記録の存在を意味し、後続の記録パスで解消される想定のため
        # スクリプト自体は継続する（set -e に引っかからないよう || で握りつぶす）。
        echo "--- xcodebuild test-without-building (self-invoked, verify-only pass) ---"
        SNAPSHOT_TESTING_RECORD= xcodebuild test-without-building \
            -destination "platform=iOS Simulator,id=$DEVICE_ID" \
            -testProductsPath "$TEST_PRODUCTS_PATH" \
            -testPlan hometeSnapshotTestsForCI \
            -resultBundlePath /Volumes/workspace/vrt-verify-resultbundle.xcresult \
            && echo "✓ verify pass: all snapshots already match" \
            || echo "✗ verify pass: mismatch or missing snapshot detected (record pass will follow)"

        # ② 記録パス: 明示的に failed を指定し、①で検出されたミスマッチ/未記録分のみを書き込む。
        echo "--- xcodebuild test-without-building (self-invoked, record pass) ---"
        SNAPSHOT_TESTING_RECORD=failed xcodebuild test-without-building \
            -destination "platform=iOS Simulator,id=$DEVICE_ID" \
            -testProductsPath "$TEST_PRODUCTS_PATH" \
            -testPlan hometeSnapshotTestsForCI \
            -resultBundlePath /Volumes/workspace/vrt-record-resultbundle.xcresult \
            || echo "xcodebuild test-without-building exited non-zero (isRecordingSnapshotsが真ならXCTFailは抑止されるはずなので要調査)"

        SNAPSHOT_DIR="hometeSnapshotTests/__Snapshots__/PreviewTests.generated"
        CI_SCRIPTS_SNAPSHOT_DIR="ci_scripts/__Snapshots__"

        # fork PR は secret 環境変数（GITHUB_TOKEN）が渡らずpush先も他人のリポジトリになるため対象外。
        # PRに紐付かないビルド（例: mainへの直push起点）も対象外とする。
        if [ -z "$CI_PULL_REQUEST_NUMBER" ]; then
            echo "Skipping commit/push (not associated with a pull request)"
            exit 0
        fi
        if [ "$CI_PULL_REQUEST_SOURCE_REPO" != "$CI_PULL_REQUEST_TARGET_REPO" ]; then
            echo "Skipping commit/push (fork PR: $CI_PULL_REQUEST_SOURCE_REPO != $CI_PULL_REQUEST_TARGET_REPO)"
            exit 0
        fi

        git add -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR"

        echo "--- git status (short) for snapshot dirs ---"
        git status --short -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR" || true

        # git diff --stat は追跡済みファイルの変更しか見ないため、新規（missing→記録）ファイルを
        # 見落とす。git add 後の --cached --quiet でステージ済み差分の有無を判定する。
        if git diff --cached --quiet -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR"; then
            echo "No snapshot changes to commit."
            echo "==========================="
            exit 0
        fi

        echo "--- git diff --cached --stat for snapshot dirs ---"
        git diff --cached --stat -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR" || true

        if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPOSITORY" ]; then
            echo "WARNING: GITHUB_TOKEN or GITHUB_REPOSITORY is not set. Skipping commit/push."
            echo "==========================="
            exit 0
        fi

        # Xcode CloudではGit設定がされていないため最低限の設定を行う
        git config user.email "taichis844@gmail.com"
        git config user.name "stotic-dev"

        git commit -m "$(cat <<'COMMIT_MSG'
chore: VRT参照スナップショットを自動更新

doc/adr/0005: Xcode Cloud上で記録した参照PNGの自動commitです。
PRコメントのDangerによるbefore/after画像差分でレビューしてください。
COMMIT_MSG
)"

        REMOTE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
        git push "$REMOTE_URL" "HEAD:refs/heads/$CI_PULL_REQUEST_SOURCE_BRANCH"
        echo "✓ Pushed snapshot updates to $CI_PULL_REQUEST_SOURCE_BRANCH"
        echo "==========================="
        ;;

    *)
        echo "Skipping ci_post_xcodebuild.sh (CI_WORKFLOW=$CI_WORKFLOW)"
        ;;
esac
