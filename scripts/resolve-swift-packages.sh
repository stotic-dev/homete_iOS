#!/bin/bash
# ProjectTools / LocalPackage のSwiftPM依存を取得する（git clone / checkoutの作成・更新）。
#
# 背景: Claude Codeのサンドボックスは、プロジェクト配下の `.git/config` と `.git/hooks` への
# 書き込みを必ず拒否する（gitフック注入対策の必須deny。allowWriteでは開けない）。
# SwiftPMは依存を取り直すときに `.build/checkouts/<pkg>/.git/config` を書くため、
# 新規worktreeや依存更新（Dependabotのマージ後など）の直後はサンドボックス内のビルドが
# `You don't have permission to save the file "config" in the folder ".git"` で落ちる。
#
# このスクリプトは依存の取得だけをサンドボックス外で流すためのもの。一度通れば以降の
# ビルド・テストはサンドボックス内で完結する。サンドボックス外で動かす前提なので、
# SwiftPM自身のマニフェストサンドボックスは切らない（`--disable-sandbox` を付けない）。
#
# 呼び出し元: `make resolve-packages`

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "ProjectToolsの依存を取得中..."
swift package resolve --package-path "$ROOT/ProjectTools" --scratch-path "$ROOT/ProjectTools/.build"

echo "LocalPackageの依存を取得中..."
"$ROOT/scripts/with-local-package-lock.sh" "$ROOT/LocalPackage" -- \
    swift package resolve --package-path "$ROOT/LocalPackage"
