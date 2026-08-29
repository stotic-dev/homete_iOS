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
    if ! echo "$$" >"$LOCK_PID_FILE" 2>/dev/null; then
        # PID書き込みに失敗した場合はロックを保持しない（半端な状態を残さない）。
        rm -rf "$LOCK_DIR" 2>/dev/null
        return 1
    fi
    return 0
}

while ! acquire_lock; do
    holder_pid="$(cat "$LOCK_PID_FILE" 2>/dev/null || true)"

    if [[ -z "$holder_pid" ]]; then
        # mkdir直後・PID書き込み前の初期化中の可能性がある。stale扱いにせず少し待つ。
        # ただしPID書き込みが永久に来ない異常系（ロック保持者がmkdir直後に死んだ等）で
        # 無限ループしないよう、この待機もタイムアウトに含める。
        if (( waited >= WAIT_TIMEOUT_SECONDS )); then
            echo "${WAIT_TIMEOUT_SECONDS}秒待ってもロックのPIDファイルが書き込まれませんでした。${LOCK_DIR} の状況を確認してください。" >&2
            exit 1
        fi
        sleep 1
        waited=$((waited + 1))
        continue
    fi

    if kill -0 "$holder_pid" 2>/dev/null; then
        if (( waited == 0 )); then
            echo "別のswiftビルド/テストが実行中です（PID ${holder_pid}）。完了を待ちます..." >&2
        fi
        if (( waited >= WAIT_TIMEOUT_SECONDS )); then
            echo "${WAIT_TIMEOUT_SECONDS}秒待っても完了しませんでした。PID ${holder_pid} の状況を確認してください。" >&2
            exit 1
        fi
        sleep 2
        waited=$((waited + 2))
        continue
    fi

    # ロック保持者が死んでいる = staleなロック。
    # mvはatomicなので、複数プロセスが同時にstale判定しても移動を実行できるのは1つだけになる
    # （rm -rfだと非存在でも成功扱いになり排他できず、後発が先発の再取得済みプロセスを殺しうる）。
    #
    # ただしmvはパスが一致していれば無条件で成功するため、「自分がholder_pidを読んでから
    # mvするまでの間に、別プロセスが同じstaleロックをmvで奪取→掃除→再取得し、新しい
    # 生存ロックを作っていた」ケース（ABA）では、その新しい生存ロックごと奪ってしまう。
    # 移動後のPIDが自分の観測したholder_pidと一致するかを確認し、一致しない場合は
    # 別プロセスの生存ロックを奪ってしまったとみなして元の場所に戻す。
    reclaim_dir="${LOCK_DIR}.reclaim.$$"
    if mv "$LOCK_DIR" "$reclaim_dir" 2>/dev/null; then
        reclaimed_pid="$(cat "$reclaim_dir/pid" 2>/dev/null || true)"
        if [[ "$reclaimed_pid" == "$holder_pid" ]]; then
            rm -rf "$reclaim_dir" 2>/dev/null
            "$SCRIPT_DIR/kill-stale-swift-processes.sh" "$PACKAGE_PATH"
        elif ! mv "$reclaim_dir" "$LOCK_DIR" 2>/dev/null; then
            # 戻す前に別プロセスが新規にロックを取得していた場合はそちらを優先する。
            rm -rf "$reclaim_dir" 2>/dev/null
        fi
    fi
done

cleanup() {
    rm -rf "$LOCK_DIR" 2>/dev/null
}
trap cleanup EXIT

"$@"
