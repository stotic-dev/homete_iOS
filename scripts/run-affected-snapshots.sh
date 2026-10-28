#!/bin/bash
# 変更したモジュールのプレビューだけ、ローカルでVRT（スナップショットテスト）を流す。
#
# 対象は scripts/affected-modules.py の vrt-tests（直接変えたHometeUI・Featureのプレビュー）。
# 全プレビューの確認と参照スナップショットの更新はXcode CloudのVRTに任せる（doc/adr/0048）。
#
# - 参照スナップショットは書き換えない。参照の無い新しいプレビューはライブラリが参照PNGを
#   書き出してしまうので、実行後に今回増えた追跡外のPNGを消す（参照の記録はCIが行う）
# - 差分が出たときの画像は $ARTIFACTS_DIR に出る
#
# 使い方: scripts/run-affected-snapshots.sh [<base ref>]（省略時は origin/main）

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

BASE="${1:-origin/main}"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData/hometeVRT-affected"
ARTIFACTS_DIR="$DERIVED_DATA/SnapshotFailures"
SNAPSHOT_DIR="hometeSnapshotTests/__Snapshots__/PreviewTests.generated"
candidates="$(python3 scripts/affected-modules.py vrt-tests --base "$BASE")"
if [ -z "$candidates" ]; then
    echo "VRTの対象になるモジュール（HometeUI・Feature）に変更が無いので、ローカルVRTは流しません。"
    exit 0
fi

# 参照スナップショットはXcode CloudのiOS 27.0・iPhone 16で記録している。マイナーバージョンが違うだけでも
# 描画に差分が出るので、iOS 27.0のiPhone 16に固定する（OSを書いた名前指定だと見つからないことがあるので、IDで指定する）
REQUIRED_RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-27-0"
device_id="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
for device in json.load(sys.stdin)["devices"].get(sys.argv[1], []):
    if device["name"] == "iPhone 16":
        print(device["udid"])
        break
' "$REQUIRED_RUNTIME")"
if [ -z "$device_id" ]; then
    echo "iOS 27.0のiPhone 16シミュレータがありません。iOS 27.0のランタイムを入れ、iPhone 16を作成してください。" >&2
    echo "他のバージョンでは参照スナップショットと描画が一致しないため、代わりのシミュレータでは流しません。" >&2
    exit 1
fi
DESTINATION="platform=iOS Simulator,id=$device_id"

xcodebuild_common=(
    -project hometeVRT.xcodeproj
    -scheme hometeSnapshotTests
    -testPlan snapshotTesting
    -destination "$DESTINATION"
    -derivedDataPath "$DERIVED_DATA"
)

echo "=== build-for-testing ==="
xcodebuild build-for-testing "${xcodebuild_common[@]}" -onlyUsePackageVersionsFromResolvedFile -quiet

# Prefireが実際に生成したテストと突き合わせる（.prefireIgnored() などで対象外のプレビューもあるため）
generated="$(find "$DERIVED_DATA/Build/Intermediates.noindex/BuildToolPluginIntermediates" \
    -name PreviewTests.generated.swift -path '*PrefireTestsPlugin*' | head -1)"
if [ -z "$generated" ]; then
    echo "Prefireの生成コード（PreviewTests.generated.swift）が見つかりません。" >&2
    exit 1
fi
tests="$(python3 scripts/affected-modules.py vrt-tests --base "$BASE" --generated "$generated")"
if [ -z "$tests" ]; then
    echo "変更したモジュールに、VRTの対象になるプレビューがありません。"
    exit 0
fi

only_testing=()
while IFS= read -r name; do
    only_testing+=("-only-testing:hometeSnapshotTests/PreviewTests/test_${name}_Preview")
done <<< "$tests"
echo "=== test-without-building（$(echo "$tests" | wc -l | tr -d ' ')件） ==="

before="$(git ls-files --others --exclude-standard -- "$SNAPSHOT_DIR" | sort)"
rm -rf "$ARTIFACTS_DIR"
status=0
# TEST_RUNNER_ を付けた環境変数はテストプロセスに渡る。参照PNGの場所は明示しないと、生成コードのある
# DerivedData側を見てしまい、全件「参照が無い」で失敗する（generateTestTemplate.stencil の snapshotDirectoryOverride）
# 参照スナップショットを記録するXcode Cloudのランナーは太平洋時間で動いている。タイムゾーンが違うと、
# 東京時間で固定した日付（previewDate）が表示上1日ずれて差分になるのでそろえる
TEST_RUNNER_TZ=America/Los_Angeles \
TEST_RUNNER_SNAPSHOT_REFERENCE_DIR="$REPO_ROOT/$SNAPSHOT_DIR" \
TEST_RUNNER_SNAPSHOT_ARTIFACTS="$ARTIFACTS_DIR" \
    xcodebuild test-without-building "${xcodebuild_common[@]}" "${only_testing[@]}" -quiet || status=$?

added="$(comm -13 <(echo "$before") <(git ls-files --others --exclude-standard -- "$SNAPSHOT_DIR" | sort))"
if [ -n "$added" ]; then
    echo "参照の無いプレビューのPNGが書き出されたので消します（参照の記録はCIのVRTが行う）:"
    echo "$added" | sed 's/^/  /'
    echo "$added" | while IFS= read -r f; do rm -f "$f"; done
fi

if [ "$status" -ne 0 ]; then
    echo "参照スナップショットとの差分があります。差分の画像: $ARTIFACTS_DIR" >&2
fi
exit "$status"
