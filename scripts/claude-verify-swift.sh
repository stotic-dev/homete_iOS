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
#   - make check-previews を実行（VRTでしか落ちない #Preview の誤りを先に検出）
#   - 失敗したら要約を stdout に出して exit 2（Claude が起こされる）
#   - 3回連続で失敗したら諦めて exit 0（無限ループ防止）
#
# ビルド・SwiftLint・ユニットテスト（make test-packages）はここでは実行しない。
# フックと手動実行が重なると SwiftPM の .build ロックで詰まるうえ、ターン終了が
# 数分単位で伸びるため。これらは .claude/skills/swift-code-verification/SKILL.md
# の手順に従って Claude 自身が実行する。
#
# 手動実行してデバッグする場合:
#   echo '{}' | scripts/claude-verify-swift.sh; echo "exit=$?"

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 0

# 状態の置き場は git 経由で解決する。リンクされた worktree では $REPO_ROOT/.git が
# ディレクトリではなくファイル（実体へのポインタ）なので、直に .git/ を掘ると失敗する。
# --absolute-git-dir は worktree ごとの metadata ディレクトリを返すため、fingerprint と
# 失敗カウントが worktree 間で混ざることもない。
GIT_DIR="$(git rev-parse --absolute-git-dir 2>/dev/null)"
if [[ -z "$GIT_DIR" ]]; then
    printf '{"systemMessage":"Swift検証: git ディレクトリを解決できないため検証をスキップしました。"}\n'
    exit 0
fi

STATE_DIR="$GIT_DIR/claude-verify"
STAMP_FILE="$STATE_DIR/last-verified"
FAIL_COUNT_FILE="$STATE_DIR/consecutive-failures"
LOG_FILE="$STATE_DIR/last-run.log"
MAX_CONSECUTIVE_FAILURES=3

if ! mkdir -p "$STATE_DIR" 2>/dev/null; then
    printf '{"systemMessage":"Swift検証: 状態ディレクトリ %s を作成できないため検証をスキップしました。"}\n' "$STATE_DIR"
    exit 0
fi

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

# VRT(Prefire)の生成コードはローカルのビルド対象に入らないため、#Preview の
# アクセス修飾子ミスは Xcode Cloud まで気付けない。先に静的検査で潰す。
if make check-previews > "$LOG_FILE" 2>&1; then
    echo "$fingerprint" > "$STAMP_FILE"
    echo 0 > "$FAIL_COUNT_FILE"
    exit 0
fi

attempt=$((fail_count + 1))
echo "$attempt" > "$FAIL_COUNT_FILE"

echo "make check-previews が失敗しました（${attempt}回目 / 上限${MAX_CONSECUTIVE_FAILURES}回）。以下を修正してから終了してください。"
echo
cat "$LOG_FILE"

exit 2
