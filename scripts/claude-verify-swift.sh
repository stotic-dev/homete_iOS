#!/bin/bash
# Claude Code の Stop フックから呼ばれる Swift 検証スクリプト。
#
# 目的:
#   検証手順をスキル/ルールに「お願い」として書くだけだと、Claude が読み飛ばした
#   場合にビルドが壊れたままターンが終わる。フックは harness が実行するので確実に
#   走り、失敗時は exit 2 で Claude を叩き起こして修正させられる。
#
# 挙動:
#   - Swift ファイルに変更が無ければ何もしない（exit 0）
#   - 前回検証が通った時点から変化が無ければ何もしない（exit 0）
#   - make test-packages を実行（SwiftPMビルド + SwiftLintプラグイン + ユニットテスト）
#   - 失敗したら要約を stdout に出して exit 2（Claude が起こされる）
#   - 3回連続で失敗したら諦めて exit 0（無限ループ防止）
#
# 手動実行してデバッグする場合:
#   echo '{}' | scripts/claude-verify-swift.sh; echo "exit=$?"

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 0

STATE_DIR="$REPO_ROOT/.git/claude-verify"
STAMP_FILE="$STATE_DIR/last-verified"
FAIL_COUNT_FILE="$STATE_DIR/consecutive-failures"
LOG_FILE="$STATE_DIR/last-run.log"
MAX_CONSECUTIVE_FAILURES=3

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

# --- 変更された Swift ファイルがあるか判定 --------------------------------

# 未コミットの変更（追跡外の新規ファイルも含む）
uncommitted="$(git status --porcelain -uall -- '*.swift' 2>/dev/null)"

# ブランチ上でコミット済みの変更（main から分岐して以降）
committed=""
if base="$(git merge-base HEAD main 2>/dev/null)"; then
    committed="$(git diff --name-only "$base"...HEAD -- '*.swift' 2>/dev/null)"
fi

if [[ -z "$uncommitted" && -z "$committed" ]]; then
    exit 0
fi

# --- 前回検証時から変化があるか判定 ----------------------------------------

fingerprint="$(
    {
        git rev-parse HEAD 2>/dev/null
        printf '%s\n' "$uncommitted"
        git diff HEAD -- '*.swift' 2>/dev/null
        # 追跡外ファイルは内容も含める（git diff に出てこないため）
        git ls-files --others --exclude-standard -- '*.swift' 2>/dev/null \
            | while IFS= read -r f; do [[ -f "$f" ]] && shasum -a 256 "$f"; done
    } | shasum -a 256 | cut -d' ' -f1
)"

if [[ -f "$STAMP_FILE" && "$(cat "$STAMP_FILE" 2>/dev/null)" == "$fingerprint" ]]; then
    exit 0
fi

# --- 連続失敗のガード -------------------------------------------------------

fail_count=0
[[ -f "$FAIL_COUNT_FILE" ]] && fail_count="$(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo 0)"
[[ "$fail_count" =~ ^[0-9]+$ ]] || fail_count=0

if (( fail_count >= MAX_CONSECUTIVE_FAILURES )); then
    echo 0 > "$FAIL_COUNT_FILE"
    printf '{"systemMessage":"Swift検証が%d回連続で失敗したため自動検証を停止しました。%s を確認してください。"}\n' \
        "$MAX_CONSECUTIVE_FAILURES" "${LOG_FILE#"$REPO_ROOT"/}"
    exit 0
fi

# --- 検証実行 ---------------------------------------------------------------

if make test-packages > "$LOG_FILE" 2>&1; then
    echo "$fingerprint" > "$STAMP_FILE"
    echo 0 > "$FAIL_COUNT_FILE"
    exit 0
fi

attempt=$((fail_count + 1))
echo "$attempt" > "$FAIL_COUNT_FILE"

echo "make test-packages が失敗しました（${attempt}回目 / 上限${MAX_CONSECUTIVE_FAILURES}回）。以下を修正してから終了してください。"
echo
echo "--- エラー抜粋 ---"
grep -E "error:|error :|failed|✘|Fatal error|Test .* failed" "$LOG_FILE" | tail -40
echo
echo "--- 末尾 ---"
tail -25 "$LOG_FILE"
echo
echo "全文: ${LOG_FILE#"$REPO_ROOT"/}"

exit 2
