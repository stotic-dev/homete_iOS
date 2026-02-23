#!/bin/sh

# Xcode CloudでSwift Package Managerプラグインの検証をスキップする
# PrefireTestsPluginなどのパッケージプラグインを許可するために必要
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

# スナップショット参照ファイルの確認
SNAPSHOT_DIR="$CI_WORKSPACE/hometeSnapshotTests/__Snapshots__/PreviewTests.generated"
CI_SCRIPTS_SNAPSHOT_DIR="$CI_WORKSPACE/ci_scripts/__Snapshots__"

echo "=== Snapshot files check ==="
echo "CI_WORKSPACE: $CI_WORKSPACE"

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
