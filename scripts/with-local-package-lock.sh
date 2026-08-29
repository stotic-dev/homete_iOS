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
    #
    # 以前はmvでLOCK_DIRを退避してから後始末していたが、mv実行からPID引き継ぎ完了までの
    # 間、LOCK_DIRが不在になる瞬間があった。その隙に別の待機者がacquire_lockで新規に
    # LOCK_DIRを掴んで実行を始めてしまうと、自分が後から呼ぶkill-stale-swift-processes.sh
    # がその別waiterの新しいプロセスを誤って殺してしまう（退避先ディレクトリのPID一致
    # 検証だけでは、この「LOCK_DIRという場所そのものが無防備になる時間帯」は防げない）。
    #
    # 対策: LOCK_DIR自体は最後まで削除・移動せず存在させ続け、「stale後始末を行う権利」
    # だけを専用ロック（LOCK_DIR.cleaning）で排他制御する。LOCK_DIRが常に存在するため
    # 他プロセスのacquire_lockは終始失敗し、掴み直しの隙が生まれない。後始末権を得た
    # プロセスは、kill完了後にLOCK_PID_FILEを自分のPIDへ書き換えることでロックを引き継ぐ。
    cleaning_lock="${LOCK_DIR}.cleaning"
    if ! mkdir "$cleaning_lock" 2>/dev/null; then
        # 他プロセスが後始末中。完了を待つ。
        if (( waited >= WAIT_TIMEOUT_SECONDS )); then
            echo "${WAIT_TIMEOUT_SECONDS}秒待ってもstaleロックの後始末が完了しませんでした。${cleaning_lock} の状況を確認してください。" >&2
            exit 1
        fi
        sleep 1
        waited=$((waited + 1))
        continue
    fi

    # 後始末権を得た後、状況が変わっていないか再確認する
    # （待っている間に他プロセスが正常にロックを引き継いでいた場合は何もしない）。
    current_pid="$(cat "$LOCK_PID_FILE" 2>/dev/null || true)"
    if [[ "$current_pid" == "$holder_pid" ]] && ! kill -0 "$holder_pid" 2>/dev/null; then
        "$SCRIPT_DIR/kill-stale-swift-processes.sh" "$PACKAGE_PATH"
        if ! echo "$$" >"$LOCK_PID_FILE" 2>/dev/null; then
            echo "ロックのPIDファイル書き込みに失敗しました: ${LOCK_PID_FILE}" >&2
            rm -rf "$cleaning_lock" 2>/dev/null
            exit 1
        fi
        rm -rf "$cleaning_lock" 2>/dev/null
        break
    fi

    rm -rf "$cleaning_lock" 2>/dev/null
done

cleanup() {
    rm -rf "$LOCK_DIR" 2>/dev/null
}
trap cleanup EXIT

"$@"
