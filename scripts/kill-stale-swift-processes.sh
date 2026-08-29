#!/bin/bash
# 指定したLocalPackageに紐づく、真にstaleなswiftビルド/テストプロセスだけを止める。
#
# `ps -eo args` の args 先頭（実行バイナリ）が swift 系ツールチェーンのものに限定して
# マッチすることで、make/sh/pkill など無関係なプロセス（argvにたまたま同じパス文字列を
# 含むもの）を巻き込まない。呼び出し元（scripts/with-local-package-lock.sh）が
# 「ロック保持者が既に死んでいる」ことを確認した上でのみ呼ぶ想定のため、ここでは
# 生存確認をせず該当プロセスを無条件で止める。
#
# 使い方: scripts/kill-stale-swift-processes.sh <LocalPackage絶対パス>

set -uo pipefail

PACKAGE_PATH="${1:?usage: $0 <LocalPackage absolute path>}"

ps -eo pid=,args= | while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "$line" ]] && continue
    pid="${line%% *}"
    rest="${line#* }"
    bin="${rest%% *}"
    base="${bin##*/}"
    case "$base" in
        swift | swift-build | swift-test | swiftpm-testing-helper)
            if [[ "$rest" == *"$PACKAGE_PATH"* ]]; then
                kill "$pid" 2>/dev/null
            fi
            ;;
    esac
done

exit 0
