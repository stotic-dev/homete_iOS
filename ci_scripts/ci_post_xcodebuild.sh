#!/bin/sh

# testアクションの後のみ実行する（build/archiveの後はスキップ）
if [ "$CI_XCODEBUILD_ACTION" != "test-without-building" ]; then
    echo "testアクションではないためスキップします（CI_XCODEBUILD_ACTION=${CI_XCODEBUILD_ACTION}）"
    exit 0
fi

# DANGER_ENABLEDが設定されていない場合はスキップ（Xcode Cloudの環境変数で制御）
if [ "$DANGER_ENABLED" != "YES" ]; then
    echo "DANGER_ENABLED=YES が設定されていないためDangerをスキップします"
    exit 0
fi

# PRビルド時のみ実行
if [ -z "$CI_PULL_REQUEST_NUMBER" ]; then
    echo "PRビルドではないためDangerをスキップします"
    exit 0
fi

echo "Dangerを実行します (PR #${CI_PULL_REQUEST_NUMBER})"

# Node.js / npmをインストール（Xcode Cloud環境にはデフォルトでnpmがない）
brew install node

# DangerJS（danger-swiftが依存）をインストール
npm install -g danger

# ProjectToolsディレクトリでビルドして実行（ci.ymlと同じ方法）
cd "$CI_PRIMARY_REPOSITORY_PATH/ProjectTools"
swift build
swift run danger-swift ci --cwd ../
