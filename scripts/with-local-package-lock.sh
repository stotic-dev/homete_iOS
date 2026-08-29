#!/bin/bash
# LocalPackageに対するswift build/testの多重実行を排他制御してから実行する。
#
# 背景: 以前は各Makefileターゲットの先頭で `pkill -f <LocalPackageのパス>` により
# 「stale（前回セッションの残骸）プロセス」を掃除していたが、これは「stale」と
# 「同じworktreeで今まさに走っている別のmake実行」を区別できなかった。Stopフックの
# 自動検証と手動実行が重なると、後発のpkillが先発の現在進行中のswift-test/ヘルパー
# プロセスを正しくマッチした上で殺してしまい、SIGTERMで異常終了していた。
#
# 対策: PIDを記録したロックディレクトリで排他制御する。
#   - ロックを取れれば、真にstaleなプロセス（ロック保持者が既に死んでいる場合のみ）を
#     kill-stale-swift-processes.sh で掃除してから実行する
#   - ロックが生存中の別プロセスに保持されていれば、pkillせずその完了を待つ
#
# 使い方: scripts/with-local-package-lock.sh <LocalPackage絶対パス> -- <実行するコマンド...>

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_PATH="${1:?usage: $0 <LocalPackage absolute path> -- <command...>}"
shift
if [[ "${1:-}" != "--" ]]; then
    echo "usage: $0 <LocalPackage absolute path> -- <command...>" >&2
    exit 1
fi
shift

LOCK_DIR="$PACKAGE_PATH/.build/.make-lock"
LOCK_PID_FILE="$LOCK_DIR/pid"
WAIT_TIMEOUT_SECONDS=600
waited=0

mkdir -p "$(dirname "$LOCK_DIR")" 2>/dev/null

acquire_lock() {
    mkdir "$LOCK_DIR" 2>/dev/null || return 1
    echo "$$" >"$LOCK_PID_FILE"
    return 0
}

while ! acquire_lock; do
    holder_pid="$(cat "$LOCK_PID_FILE" 2>/dev/null || true)"

    if [[ -n "$holder_pid" ]] && kill -0 "$holder_pid" 2>/dev/null; then
        if (( waited == 0 )); then
            echo "別のswiftビルド/テストが実行中です（PID ${holder_pid}）。完了を待ちます..." >&2
        fi
        if (( waited >= WAIT_TIMEOUT_SECONDS )); then
            echo "${WAIT_TIMEOUT_SECONDS}秒待っても完了しませんでした。PID ${holder_pid} の状況を確認してください。" >&2
            exit 1
        fi
        sleep 2
        waited=$((waited + 2))
    else
        # ロック保持者が死んでいる = staleなロック。真にstaleなプロセスだけ掃除して奪取する。
        rm -rf "$LOCK_DIR" 2>/dev/null
        "$SCRIPT_DIR/kill-stale-swift-processes.sh" "$PACKAGE_PATH"
    fi
done

cleanup() {
    rm -rf "$LOCK_DIR" 2>/dev/null
}
trap cleanup EXIT

"$@"
