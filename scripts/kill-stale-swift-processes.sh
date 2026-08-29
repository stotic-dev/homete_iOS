#!/bin/bash
# 指定したLocalPackageに紐づく、真にstaleなswiftビルド/テストプロセスだけを止める。
#
# 呼び出し元（scripts/with-local-package-lock.sh）が「ロック保持者が既に死んでいる」
# ことを確認した上でのみ呼ぶ想定のため、ここでは生存確認をせず該当プロセスを
# 無条件で止める。
#
# 掃除の手段は2系統ある。
#
# 1. `ps -eo pid=,args=` によるスキャン
#    args先頭（実行バイナリ）が swift 系ツールチェーンのものに限定してマッチすることで、
#    make/sh/pkill など無関係なプロセス（argvにたまたま同じパス文字列を含むもの）を
#    巻き込まない。取りこぼしが無いのはこちらだけ。
#
# 2. `<LocalPackage>/.build/.lock` の保持者を止める
#    Claude Code のサンドボックス下では ps / pgrep / sysctl kern.proc がいずれも
#    禁止されており、1が丸ごと使えない（`/bin/ps: Operation not permitted`）。
#    SwiftPM はこのロックファイルに自身のPIDを書いてから flock(2) で排他するため、
#    プロセス一覧なしでも「今まさにビルドロックを握っている者」だけは特定できる。
#    後続の swift コマンドを無言で待たせる実害を出しているのは大抵これなので、
#    1が使えないときはここだけでも掃除する。
#
# 終了コード:
#   0 = プロセス一覧を取得したうえで掃除した（取りこぼし無し）
#   2 = プロセス一覧を取得できなかった（2のみ実施）。呼び出し元は警告すること。
#       黙って成功扱いで終わると、掃除がスキップされたことに誰も気付けない。
#
# 使い方: scripts/kill-stale-swift-processes.sh <LocalPackage絶対パス>

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_PATH="${1:?usage: $0 <LocalPackage absolute path>}"
BUILD_PATH="$PACKAGE_PATH/.build"
LOCK_PROBE="$SCRIPT_DIR/swiftpm-build-lock.py"

status=0

# --- 1. プロセス一覧からのスキャン -----------------------------------------

# ps自身のエラー（Operation not permitted 等）は原因の手掛かりになるので、握り潰さず
# そのまま stderr へ流す。
if ps_output="$(ps -eo pid=,args=)" && [[ -n "$ps_output" ]]; then
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" ]] && continue
        pid="${line%% *}"
        rest="${line#* }"
        bin="${rest%% *}"
        base="${bin##*/}"
        case "$base" in
            swift | swift-build | swift-test | swiftpm-testing-helper)
                if [[ "$rest" == *"$PACKAGE_PATH"* ]]; then
                    if kill "$pid" 2>/dev/null; then
                        echo "staleなswiftプロセスを停止しました: PID ${pid} (${base})" >&2
                    fi
                fi
                ;;
        esac
    done <<<"$ps_output"
else
    status=2
    echo "警告: プロセス一覧(ps)を取得できないため、staleなswiftプロセスの全体スキャンをスキップしました。" >&2
    echo "      Claude Codeのサンドボックス下では ps / pgrep / sysctl kern.proc がいずれも禁止されています。" >&2
    echo "      代わりに ${BUILD_PATH}/.lock の保持者のみを対象に掃除を試みます。" >&2
fi

# --- 2. ビルドロックの保持者 -------------------------------------------------

if ! command -v python3 >/dev/null 2>&1 || [[ ! -f "$LOCK_PROBE" ]]; then
    echo "警告: ${LOCK_PROBE} を実行できないため、ビルドロック経由の掃除をスキップしました。" >&2
    exit "$status"
fi

lock_state="$(python3 "$LOCK_PROBE" "$BUILD_PATH" 2>/dev/null)"
case "$lock_state" in
    "held "*)
        holder="${lock_state#held }"
        if [[ "$holder" =~ ^[0-9]+$ ]] && kill -0 "$holder" 2>/dev/null; then
            if kill "$holder" 2>/dev/null; then
                echo "ビルドロック(${BUILD_PATH}/.lock)を保持していた PID ${holder} を停止しました。" >&2
            fi
        else
            echo "警告: ビルドロック(${BUILD_PATH}/.lock)は保持されていますが、保持者のPIDを特定できませんでした。" >&2
            echo "      この後の swift コマンドは出力を出さないまま待機し続ける可能性があります。" >&2
        fi
        ;;
esac

exit "$status"
