#!/bin/sh

set -e

# doc/adr/0005: VRTワークフローのpushには、長期有効なPAT（GITHUB_TOKEN Secret）ではなく
# GitHub Appのインストールアクセストークン（有効期限1時間、ビルド毎に都度発行）を使う。
# 事前にVRTワークフローのXcode Cloud環境変数として以下を設定しておく必要がある:
#   GH_APP_ID                 : GitHub AppのApp ID
#   GH_APP_PRIVATE_KEY_BASE64 : GitHub Appの秘密鍵(.pem)をbase64エンコードした文字列（Secret）
#   GITHUB_REPOSITORY         : 対象リポジトリ（owner/repo形式）
# GitHub App側は対象リポジトリにインストール済みで、Contents: Read and write 権限が必要。
#
# 成功時は installation access token を標準出力に出す（呼び出し側で `TOKEN=$(resolve_github_app_token)`
# のように変数へ代入して受け取る）。診断ログは標準エラーへ出し、標準出力を汚さない。
# 必要な環境変数が無い、またはAPI呼び出しに失敗した場合は非0を返す。
resolve_github_app_token() {
    if [ -z "$GH_APP_ID" ] || [ -z "$GH_APP_PRIVATE_KEY_BASE64" ] || [ -z "$GITHUB_REPOSITORY" ]; then
        echo "GH_APP_ID / GH_APP_PRIVATE_KEY_BASE64 / GITHUB_REPOSITORY のいずれかが未設定です" >&2
        return 1
    fi

    PRIVATE_KEY_PATH=$(mktemp)
    echo "$GH_APP_PRIVATE_KEY_BASE64" | base64 -d > "$PRIVATE_KEY_PATH"

    NOW=$(date +%s)
    IAT=$((NOW - 60))
    EXP=$((NOW + 540))

    JWT_HEADER=$(printf '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '\n=' | tr '+/' '-_')
    JWT_PAYLOAD=$(printf '{"iat":%s,"exp":%s,"iss":%s}' "$IAT" "$EXP" "$GH_APP_ID" | base64 | tr -d '\n=' | tr '+/' '-_')
    JWT_UNSIGNED="${JWT_HEADER}.${JWT_PAYLOAD}"
    JWT_SIGNATURE=$(printf '%s' "$JWT_UNSIGNED" | openssl dgst -sha256 -sign "$PRIVATE_KEY_PATH" -binary | base64 | tr -d '\n=' | tr '+/' '-_')
    APP_JWT="${JWT_UNSIGNED}.${JWT_SIGNATURE}"
    rm -f "$PRIVATE_KEY_PATH"

    INSTALLATION_ID=$(curl -s \
        -H "Authorization: Bearer $APP_JWT" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/installation" \
        | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id",""))')

    if [ -z "$INSTALLATION_ID" ]; then
        echo "GitHub Appのinstallation id取得に失敗しました（$GITHUB_REPOSITORY にAppがインストールされているか確認してください）" >&2
        return 1
    fi

    INSTALLATION_TOKEN=$(curl -s -X POST \
        -H "Authorization: Bearer $APP_JWT" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/app/installations/${INSTALLATION_ID}/access_tokens" \
        | python3 -c 'import json,sys; print(json.load(sys.stdin).get("token",""))')

    if [ -z "$INSTALLATION_TOKEN" ]; then
        echo "GitHub Appのinstallation access token取得に失敗しました" >&2
        return 1
    fi

    echo "$INSTALLATION_TOKEN"
}

# doc/adr/0005: スナップショットテストを記録モード（failed）で流し、変わった参照PNGを
# PRブランチへcommit・pushする。引数は xcodebuild に渡すアクションとオプション
# （-destination・-collect-test-diagnostics・記録モードの指定はこの関数で付ける）。
#
# 注意: Xcode Cloud の PR ビルドは、PR ブランチの実 HEAD ではなくターゲットブランチ
# （main）との「マージプレビューコミット」を checkout している（実測で確認済み）。
# そのため、記録処理の前に PR ブランチの実 HEAD へ checkout し直してから記録・commit・push
# する。これにより push が main を巻き込んだマージコミットにならず、実HEADのみを親とする
# 単一コミットになる。
#
# doc/adr/0030: このpush自体が新たなVRTビルドを誘発して無限ループにならないよう、
# コミットメッセージに [ci skip] を付ける（Xcode Cloudが公式サポートするスキップ指示）。
# GitHub Actions側のスキップ指示は push / pull_request イベントにしか効かないため、
# Dangerワークフロー（ci_danger.yml）は pull_request_target に切り替えてスキップ対象から
# 外してある。これによりVRTビルドだけを止め、Dangerによるbefore/after画像差分の報告は
# このbot commitに対しても走る。
#
# 引数はテストを流す関数の名前。その関数は $DEVICE_ID のシミュレータでテストを流し、xcodebuild の
# 終了コードを VRT_RUN_STATUS に入れる（シミュレータが見つからず流せなかったときは1）。
# 終了コードをどう扱うかは呼び出し側で決める。commit・pushの失敗は set -e でそのまま落とす。
record_and_push_snapshots() {
    VRT_RUN_STATUS=0

    echo "CI_PRIMARY_REPOSITORY_PATH=$CI_PRIMARY_REPOSITORY_PATH"
    echo "SNAPSHOT_TESTING_RECORD=$SNAPSHOT_TESTING_RECORD"
    echo "CI_XCODE_CLOUD=$CI_XCODE_CLOUD"

    cd "$CI_PRIMARY_REPOSITORY_PATH"

    if [ -d .git ]; then
        echo "✓ .git exists on this runner ($CI_XCODEBUILD_ACTION)"
    else
        echo "✗ .git NOT found (unexpected on $CI_XCODEBUILD_ACTION runner)"
    fi

    DEVICE_LINE=$(xcrun simctl list devices available | grep -m1 "iPhone 16 (")
    DEVICE_ID=$(echo "$DEVICE_LINE" | grep -oE '[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}')

    if [ -z "$DEVICE_ID" ]; then
        echo "✗ iPhone 16 simulator not found. Skipping VRT record run."
        VRT_RUN_STATUS=1
        return 0
    fi
    echo "Using simulator: $DEVICE_ID ($DEVICE_LINE)"

    SNAPSHOT_DIR="hometeSnapshotTests/__Snapshots__/PreviewTests.generated"
    CI_SCRIPTS_SNAPSHOT_DIR="ci_scripts/__Snapshots__"

    # fork PR は secret 環境変数（GH_APP_PRIVATE_KEY_BASE64等）が渡らずpush先も他人のリポジトリに
    # なるため対象外。PRに紐付かないビルド（例: mainへの直push起点）も対象外とする。
    # 記録処理より前に判定し、pushする場合は記録前に実HEADへcheckoutし直す（後述）。
    PUSH_ENABLED=1
    if [ -z "$CI_PULL_REQUEST_NUMBER" ]; then
        echo "Skipping commit/push (not associated with a pull request)"
        PUSH_ENABLED=0
    elif [ "$CI_PULL_REQUEST_SOURCE_REPO" != "$CI_PULL_REQUEST_TARGET_REPO" ]; then
        echo "Skipping commit/push (fork PR: $CI_PULL_REQUEST_SOURCE_REPO != $CI_PULL_REQUEST_TARGET_REPO)"
        PUSH_ENABLED=0
    elif [ -z "$GITHUB_REPOSITORY" ]; then
        echo "WARNING: GITHUB_REPOSITORY is not set. Skipping commit/push."
        PUSH_ENABLED=0
    elif ! GITHUB_TOKEN=$(resolve_github_app_token); then
        echo "WARNING: Failed to obtain GitHub App installation token. Skipping commit/push."
        PUSH_ENABLED=0
    else
        echo "✓ Obtained GitHub App installation access token"
    fi

    if [ "$PUSH_ENABLED" = "1" ]; then
        REMOTE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

        # Xcode Cloud の PR ビルドは PR ブランチの実 HEAD ではなく、ターゲットブランチ（main）との
        # マージプレビューコミットを checkout している（実測で確認済み）。記録処理より前に
        # PR ブランチの実 HEAD へ checkout し直しておくことで、後続の `git commit` + `git push HEAD:...`
        # が自然に「実HEADのみを親とする単一コミット」になり、mainを巻き込むマージコミットが
        # PRブランチへ混入するのを防ぐ。
        git fetch "$REMOTE_URL" "$CI_PULL_REQUEST_SOURCE_BRANCH"
        git checkout -B "$CI_PULL_REQUEST_SOURCE_BRANCH" FETCH_HEAD
        echo "✓ Checked out real HEAD of $CI_PULL_REQUEST_SOURCE_BRANCH (merge previewから離脱): $(git rev-parse HEAD)"
    fi

    "$1"

    git add -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR"

    echo "--- git status (short) for snapshot dirs ---"
    git status --short -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR" || true

    # git diff --stat は追跡済みファイルの変更しか見ないため、新規（missing→記録）ファイルを
    # 見落とす。git add 後の --cached --quiet でステージ済み差分の有無を判定する。
    if git diff --cached --quiet -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR"; then
        echo "No snapshot changes to commit."
        return 0
    fi

    echo "--- git diff --cached --stat for snapshot dirs ---"
    git diff --cached --stat -- "$SNAPSHOT_DIR" "$CI_SCRIPTS_SNAPSHOT_DIR" || true

    if [ "$PUSH_ENABLED" != "1" ]; then
        echo "Snapshot changes detected, but push is skipped (see above)."
        return 0
    fi

    # Xcode CloudではGit設定がされていないため最低限の設定を行う
    git config user.email "taichis844@gmail.com"
    git config user.name "stotic-dev"

    git commit -m "$(cat <<'COMMIT_MSG'
chore: VRT参照スナップショットを自動更新 [ci skip]

doc/adr/0005: Xcode Cloud上で記録した参照PNGの自動commitです。
PRコメントのDangerによるbefore/after画像差分でレビューしてください。
COMMIT_MSG
)"

    git push "$REMOTE_URL" "HEAD:refs/heads/$CI_PULL_REQUEST_SOURCE_BRANCH"
    echo "✓ Pushed snapshot updates to $CI_PULL_REQUEST_SOURCE_BRANCH"
}

# スナップショットテストを記録モードで流す。引数は xcodebuild に渡すアクションとオプション
# （-destination・-collect-test-diagnostics・記録モードの指定はこの関数で付ける）。
#
# xctestplan の $(SNAPSHOT_TESTING_RECORD) は build-for-testing の時点で展開されて
# xctestrun に焼き込まれるため、test-without-building を呼ぶシェルで値を付けてもテストに届かない
# （ワークフローに変数が無いと空になってキーごと消え、既定の missing で動く）。
# TEST_RUNNER_ 接頭辞の変数は xcodebuild が接頭辞を外してテストプロセスへ渡すので、
# こちらで failed を指定し、ワークフロー側の設定値に依存させない。
run_recording_tests() {
    echo "--- xcodebuild $1 (self-invoked on $CI_XCODEBUILD_ACTION runner) ---"
    TEST_RUNNER_SNAPSHOT_TESTING_RECORD=failed xcodebuild "$@" \
        -destination "platform=iOS Simulator,id=$DEVICE_ID" \
        -collect-test-diagnostics never \
        || VRT_RUN_STATUS=$?
}

# VRTのテストアクションが作ったテストの成果物で、全件を流す
run_vrt_test_products() {
    run_recording_tests test-without-building \
        -testProductsPath "$TEST_PRODUCTS_PATH" \
        -testPlan hometeSnapshotTestsForCI \
        -resultBundlePath /Volumes/workspace/vrt-record-resultbundle.xcresult
}

# doc/adr/0063: 変更の起点（PRのターゲットブランチのコミット）を出す。決められなければ非0を返す
resolve_vrt_base() {
    if [ -z "$CI_PULL_REQUEST_NUMBER" ] || [ -z "$CI_PULL_REQUEST_TARGET_COMMIT" ]; then
        echo "PRに紐付かないビルドです" >&2
        return 1
    fi
    # 依存グラフに出ない変化（Xcode Cloudの環境の更新など）を、リリース前に拾う
    case "$CI_PULL_REQUEST_SOURCE_BRANCH" in
        release/*)
            echo "リリースPRです" >&2
            return 1
            ;;
    esac
    if ! git cat-file -e "${CI_PULL_REQUEST_TARGET_COMMIT}^{commit}" 2>/dev/null; then
        # 浅いcloneでターゲットのコミットが無ければ取ってくる
        if ! git fetch -q "${REMOTE_URL:-origin}" "$CI_PULL_REQUEST_TARGET_COMMIT" >&2; then
            echo "ターゲットのコミット（$CI_PULL_REQUEST_TARGET_COMMIT）を取得できません" >&2
            return 1
        fi
    fi
    if ! git merge-base "$CI_PULL_REQUEST_TARGET_COMMIT" HEAD >/dev/null 2>&1; then
        echo "ターゲットのコミットとの分岐点が見つかりません（浅いclone）" >&2
        return 1
    fi
    echo "$CI_PULL_REQUEST_TARGET_COMMIT"
}

# doc/adr/0063: PRでは、変更から推移的に影響を受けるモジュールのプレビューだけを流す。
# VRTの設定・Package.resolved・HometeUIなど全モジュールに届く変更、リリースPR、起点を決められない
# ときは全件を流す。対象が無ければテストを流さない（流さなかった参照PNGはそのまま残る）
run_vrt_light() {
    VRT_DERIVED_DATA="${CI_DERIVED_DATA_PATH:-/Volumes/workspace/DerivedData}"
    VRT_RESULT_BUNDLE=/Volumes/workspace/vrt-light-resultbundle.xcresult
    set -- \
        -project hometeVRT.xcodeproj \
        -scheme hometeSnapshotTests \
        -testPlan hometeSnapshotTestsForCI \
        -derivedDataPath "$VRT_DERIVED_DATA"

    if ! VRT_BASE=$(resolve_vrt_base); then
        echo "全件を流します"
        run_vrt_light_all "$@"
        return 0
    fi
    echo "変更の起点: $VRT_BASE"
    python3 scripts/affected-modules.py summary --transitive --base "$VRT_BASE" || true

    # 判定に失敗したら全件に倒す
    if ! VRT_ALL=$(python3 scripts/affected-modules.py vrt-all --transitive --base "$VRT_BASE") \
        || ! candidates=$(python3 scripts/affected-modules.py vrt-tests --transitive --base "$VRT_BASE"); then
        echo "影響範囲を判定できないので、全件を流します"
        run_vrt_light_all "$@"
        return 0
    fi
    if [ "$VRT_ALL" != "no" ]; then
        run_vrt_light_all "$@"
        return 0
    fi
    if [ -z "$candidates" ]; then
        echo "VRTの対象になるモジュールに影響が無いので、テストを流しません"
        return 0
    fi

    echo "--- xcodebuild build-for-testing ---"
    xcodebuild build-for-testing "$@" \
        -destination "platform=iOS Simulator,id=$DEVICE_ID" \
        -onlyUsePackageVersionsFromResolvedFile \
        -skipPackagePluginValidation \
        -skipMacroValidation \
        || { VRT_RUN_STATUS=$?; return 0; }

    # Prefireが実際に生成したテストと突き合わせる（.prefireIgnored() などで対象外のプレビューもあるため）
    generated=$(find "$VRT_DERIVED_DATA/Build/Intermediates.noindex/BuildToolPluginIntermediates" \
        -name PreviewTests.generated.swift -path '*PrefireTestsPlugin*' | head -1)
    if [ -z "$generated" ] \
        || ! tests=$(python3 scripts/affected-modules.py vrt-tests --transitive --base "$VRT_BASE" --generated "$generated"); then
        echo "Prefireの生成コードと突き合わせられないので、全件を流します"
        run_recording_tests test-without-building "$@" -resultBundlePath "$VRT_RESULT_BUNDLE"
        return 0
    fi
    if [ -z "$tests" ]; then
        echo "影響を受けるモジュールに、VRTの対象になるプレビューがありません"
        return 0
    fi

    # テスト名は識別子なので空白を含まない。分割させるためにクォートせずに展開する
    only_testing=""
    for name in $tests; do
        only_testing="$only_testing -only-testing:hometeSnapshotTests/PreviewTests/test_${name}_Preview"
    done
    echo "対象のテスト: $(echo "$tests" | wc -l | tr -d ' ')件"
    # shellcheck disable=SC2086
    run_recording_tests test-without-building "$@" -resultBundlePath "$VRT_RESULT_BUNDLE" $only_testing
}

run_vrt_light_all() {
    run_recording_tests test "$@" \
        -resultBundlePath "$VRT_RESULT_BUNDLE" \
        -onlyUsePackageVersionsFromResolvedFile \
        -skipPackagePluginValidation \
        -skipMacroValidation
}

case "$CI_WORKFLOW" in
    "Upload For AppStore")
        echo "=== Upload For AppStore workflow ==="

        # doc/adr/0016: バージョンタグの作成はGitHub Actions側（release-merged.yml、
        # リリースPRのmainマージ時）に一本化したため、ここでは何もしない。
        echo "Tag creation is handled by GitHub Actions (release-merged.yml). Nothing to do here."
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
        # `TEST_RUNNER_SNAPSHOT_TESTING_RECORD=failed` で `xcodebuild test-without-building` を実行する。
        # 同一ランナー内で完結するため、書き込みがそのまま git 差分として検出できる
        # （検証ステップ1・Build 212で確認済み）。差分があれば通常のcommitメッセージでcommitし、
        # PRブランチへpushする（検証ステップ2）。
        if [ "$CI_XCODEBUILD_ACTION" != "build-for-testing" ]; then
            echo "Skipping VRT CLI re-run (CI_XCODEBUILD_ACTION=$CI_XCODEBUILD_ACTION)"
            exit 0
        fi

        TEST_PRODUCTS_PATH="/Volumes/workspace/TestProducts.xctestproducts"
        if [ ! -d "$TEST_PRODUCTS_PATH" ]; then
            echo "✗ $TEST_PRODUCTS_PATH not found. Skipping VRT record run."
            exit 0
        fi
        echo "✓ $TEST_PRODUCTS_PATH exists"

        record_and_push_snapshots run_vrt_test_products

        # 合否はXcode Cloud公式のテストアクションで判定するので、ここでは落とさない
        if [ "$VRT_RUN_STATUS" -ne 0 ]; then
            echo "xcodebuild test-without-building exited non-zero (isRecordingSnapshotsが真ならXCTFailは抑止されるはずなので要調査)"
        fi
        echo "==========================="
        ;;

    "VRT_light")
        echo "=== VRT_light workflow ==="

        # doc/adr/0052: VRTのテストアクションを使わず、Buildアクション（空のhometeVRTHostだけを
        # ビルドする）の後でスナップショットテストを1回だけ流し、記録・commit・pushまで済ませる。
        # VRTは記録用と判定用に同じテストを2回流し、別ランナーの準備と結果のアップロードも
        # 待つので、その分を省く。テストのビルドもここで行う（Buildアクションは
        # generic/platform=iOS 向けで、シミュレータ向けの成果物を使い回せないため）。
        # doc/adr/0063: PRでは影響を受けるプレビューだけを流す（run_vrt_light）。
        if [ "$CI_XCODEBUILD_ACTION" != "build" ]; then
            echo "Skipping VRT_light run (CI_XCODEBUILD_ACTION=$CI_XCODEBUILD_ACTION)"
            exit 0
        fi

        record_and_push_snapshots run_vrt_light

        # 記録モードでは不一致でもXCTFailしないので、ここで落ちるのはビルドの失敗やクラッシュ。
        # このワークフローにはテストアクションが無いので、ここで落とさないと誰も気付かない
        if [ "$VRT_RUN_STATUS" -ne 0 ]; then
            echo "✗ xcodebuild test exited with $VRT_RUN_STATUS"
            exit 1
        fi
        echo "==========================="
        ;;

    *)
        echo "Skipping ci_post_xcodebuild.sh (CI_WORKFLOW=$CI_WORKFLOW)"
        ;;
esac
