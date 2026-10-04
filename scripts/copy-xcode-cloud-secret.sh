#!/bin/bash
# Xcode Cloudのシークレット環境変数に貼る値（ローカルのxcconfigをbase64にしたもの）をクリップボードへコピーする。
#
# ci_scripts/ci_post_clone.sh が `echo "$SECRET_XCCONFIG" | base64 --decode` で復元するので、
# ここでは改行なし1行のbase64にしてコピーする。値そのものは画面に出さない。
#
# 使い方:
#   scripts/copy-xcode-cloud-secret.sh            # SECRET_XCCONFIG（本番: homete/Resouces/Secret.xcconfig）
#   scripts/copy-xcode-cloud-secret.sh dev        # SECRET_XCCONFIG_DEV（STG: homete/Resouces/Secret_dev.xcconfig）

set -euo pipefail

cd "$(dirname "$0")/.."

case "${1:-prod}" in
    prod)
        VAR_NAME="SECRET_XCCONFIG"
        FILE="homete/Resouces/Secret.xcconfig"
        WORKFLOWS="Upload For AppStore / Upload Release Candidate TestFlight"
        ;;
    dev)
        VAR_NAME="SECRET_XCCONFIG_DEV"
        FILE="homete/Resouces/Secret_dev.xcconfig"
        WORKFLOWS="Upload Stg TestFlight"
        ;;
    *)
        echo "Usage: $0 [prod|dev]" >&2
        exit 1
        ;;
esac

if [ ! -f "$FILE" ]; then
    echo "ERROR: $FILE がありません（${FILE}.sample をコピーして値を埋めてください）" >&2
    exit 1
fi

# 値が空のキーがあると、ビルドは通るのに広告や課金が動かないアプリが配信されてしまうので止める
EMPTY_KEYS=$(grep -E '^[A-Z0-9_]+[[:space:]]*=[[:space:]]*$' "$FILE" | cut -d= -f1 | tr -d ' ' || true)
if [ -n "$EMPTY_KEYS" ]; then
    echo "ERROR: $FILE に値が空のキーがあります:" >&2
    echo "$EMPTY_KEYS" | sed 's/^/  - /' >&2
    exit 1
fi

# GoogleのサンプルパブリッシャーID（テスト広告用）が残っていたら、本番では収益が出ないので警告する
if [ "$VAR_NAME" = "SECRET_XCCONFIG" ] && grep -q 'ca-app-pub-3940256099942544' "$FILE"; then
    echo "WARNING: $FILE にAdMobのテスト用ID（ca-app-pub-3940256099942544）が含まれています" >&2
fi

base64 < "$FILE" | tr -d '\n' | pbcopy

echo "✅ $VAR_NAME の値をクリップボードにコピーしました（元: $FILE）"
echo "   含まれるキー: $(grep -E '^[A-Z0-9_]+[[:space:]]*=' "$FILE" | cut -d= -f1 | tr -d ' ' | paste -sd ',' - | sed 's/,/, /g')"
echo ""
echo "Xcode Cloudでの設定先:"
echo "  App Store Connect → Xcode Cloud → ワークフロー（$WORKFLOWS）"
echo "  → 環境 → 環境変数 → $VAR_NAME に貼り付け、「シークレット」にチェック"
