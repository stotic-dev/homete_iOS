#!/bin/sh

set -e

# Xcode Cloudランナーのアーキテクチャ（Intel / Apple Silicon）を確認する
echo "=== Runner architecture ==="
echo "uname -m: $(uname -m)"
echo "arch: $(arch)"
echo "CPU brand: $(sysctl -n machdep.cpu.brand_string)"
echo "==========================="

# Xcode CloudでSwift Package Managerプラグインの検証をスキップする
# SwiftGenPlugin、PrefireTestsPluginなどのBuild Tool Pluginを許可するために必要
# どのワークフローでも共通で必要なため、switch-caseの外で実行する
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

case "$CI_WORKFLOW" in
    "VRT")
        echo "=== VRT workflow ==="

        # スナップショット参照ファイルの確認
        SNAPSHOT_DIR="$CI_PRIMARY_REPOSITORY_PATH/hometeSnapshotTests/__Snapshots__/PreviewTests.generated"
        CI_SCRIPTS_SNAPSHOT_DIR="$CI_PRIMARY_REPOSITORY_PATH/ci_scripts/__Snapshots__"

        echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"

        if [ -d "$SNAPSHOT_DIR" ]; then
            FILE_COUNT=$(ls "$SNAPSHOT_DIR" | wc -l)
            echo "✓ Snapshot directory exists at original path. File count: $FILE_COUNT"
        else
            echo "WARNING: Snapshot directory not found at: $SNAPSHOT_DIR"
        fi

        if [ -d "$CI_SCRIPTS_SNAPSHOT_DIR" ]; then
            FILE_COUNT=$(ls "$CI_SCRIPTS_SNAPSHOT_DIR" | wc -l)
            echo "✓ Snapshot directory accessible via ci_scripts. File count: $FILE_COUNT"
        else
            echo "WARNING: ci_scripts snapshot directory not found at: $CI_SCRIPTS_SNAPSHOT_DIR"
        fi
        echo "==========================="
        ;;

    "Upload For AppStore")
        echo "=== Upload For AppStore workflow ==="

        # 本番Firebase設定をsecretからデコードして配置
        if [ -z "$GOOGLESERVICE_INFO" ]; then
            echo "ERROR: GOOGLESERVICE_INFO environment variable is not set"
            exit 1
        fi
        echo "$GOOGLESERVICE_INFO" | base64 --decode > "$CI_PRIMARY_REPOSITORY_PATH/homete/GoogleService-Info.plist"
        echo "✓ GoogleService-Info.plist decoded and placed"
        echo "==========================="
        ;;

    "Upload Stg TestFlight")
        echo "=== Upload Stg TestFlight workflow ==="

        # Stg用Firebase設定をsecretからデコードして配置
        if [ -z "$GOOGLESERVICE_INFO" ]; then
            echo "ERROR: GOOGLESERVICE_INFO environment variable is not set"
            exit 1
        fi
        echo "$GOOGLESERVICE_INFO" | base64 --decode > "$CI_PRIMARY_REPOSITORY_PATH/homete/GoogleService-Info-dev.plist"
        echo "✓ GoogleService-Info-dev.plist decoded and placed"
        echo "==========================="
        ;;

    *)
        echo "Skipping ci_post_clone.sh (CI_WORKFLOW=$CI_WORKFLOW)"
        ;;
esac
