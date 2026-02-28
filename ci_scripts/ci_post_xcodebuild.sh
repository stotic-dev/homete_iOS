#!/bin/sh

# testアクションの後のみ実行する（build/archiveの後はスキップ）
if [ "$CI_XCODEBUILD_ACTION" != "test-without-building" ]; then
    echo "testアクションではないためスキップします（CI_XCODEBUILD_ACTION=${CI_XCODEBUILD_ACTION}）"
    exit 0
fi

# Danger はGitHub Actionsに移行済み
echo "post_xcodebuild: テスト完了"
