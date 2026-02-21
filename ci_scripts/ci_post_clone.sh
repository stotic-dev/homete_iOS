#!/bin/sh

# Xcode CloudでSwift Package Managerプラグインの検証をスキップする
# PrefireTestsPluginなどのパッケージプラグインを許可するために必要
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

# スナップショット参照ファイルの存在を確認（デバッグ用）
SNAPSHOT_DIR="$CI_WORKSPACE/hometeSnapshotTests/__Snapshots__/PreviewTests.generated"
echo "=== Snapshot files check ==="
echo "CI_WORKSPACE: $CI_WORKSPACE"
if [ -d "$SNAPSHOT_DIR" ]; then
    FILE_COUNT=$(ls "$SNAPSHOT_DIR" | wc -l)
    echo "Snapshot directory exists. File count: $FILE_COUNT"
else
    echo "WARNING: Snapshot directory not found at: $SNAPSHOT_DIR"
fi
echo "==========================="
