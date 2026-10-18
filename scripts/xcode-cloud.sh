#!/bin/bash
#
# App Store Connect API を使ってXcode Cloudのビルドの状態・issue・テスト結果・artifactを確認するCLI
#
# 認証は scripts/appstoreconnect.sh と共通（JWTの生成とリクエストは同スクリプトを source して使う）。
# ASC_KEY_ID が未設定なら scripts/appstoreconnect.env を読み込む。
#
# Claude Codeからは `.claude/settings.json` の sandbox.excludedCommands でサンドボックス外に出している
# （秘密鍵の読み取りとApp Store Connect・artifactのダウンロード先への通信のため）。
# 経緯は doc/adr/0048-xcode-cloud-cli-outside-claude-sandbox.md。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${ASC_KEY_ID:-}" ] && [ -f "${SCRIPT_DIR}/appstoreconnect.env" ]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/appstoreconnect.env"
fi

# shellcheck source=appstoreconnect.sh
source "${SCRIPT_DIR}/appstoreconnect.sh"

UUID_PATTERN='^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'

usage() {
  cat <<'EOS'
Usage: scripts/xcode-cloud.sh <command> [args...]

  <build>  : PR番号 | ciBuildRunのID | App Store ConnectのビルドのURL（.../ci/builds/<ID>[/action/<ID>]）
             PR番号は `gh pr checks` に出ているXcode CloudのビルドURLから引く（ワークフローが複数あれば全部）
  <action> : ciBuildActionのID | App Store ConnectのアクションのURL（.../ci/builds/<ID>/action/<ID>）

コマンド:
  status <build>
    ビルドの進捗・結果と、各アクションの名前・種類・進捗・結果・issue数を表示する
  issues <action> [--type ERROR|WARNING|TEST_FAILURE|ANALYZER_WARNING]
    アクションのissue（ビルドエラー・警告・テスト失敗）を表示する
  tests <action> [--failed]
    アクションのテスト結果を表示する。--failed で FAILURE / MIXED のテストだけに絞る
  artifacts <action>
    アクションのartifact（LOG_BUNDLE / RESULT_BUNDLE / TEST_PRODUCTS など）を一覧する
  download <action> [--type <fileType>] [--name <ファイル名の部分一致>] [--out <dir>]
    artifactをダウンロードし、zipごとに新しい空のディレクトリへ展開する
    --out は存在しないか空のディレクトリだけ受け付ける（省略時は $TMPDIR に新しく作る）
    シンボリックリンクを含むzipは展開しない
  wait <build> [--interval <秒>] [--timeout <秒>]
    ビルドが完了するまでポーリングし、完了したら status を表示する（既定: 60秒間隔、3600秒で打ち切り）
    終了コード: 全ビルドがSUCCEEDEDなら0、それ以外で完了したら1、打ち切りなら124

Env:
  ASC_KEY_ID / ASC_ISSUER_ID / ASC_API_KEY_PATH（scripts/appstoreconnect.env から読み込む）
EOS
}

# links.next を辿って全ページの .data を1つのJSON配列にして出力する
# 使い方: fetch_all <path>
fetch_all() {
  local path="$1"
  local pages page next
  pages=$(mktemp "${TMPDIR:-/tmp}/xcode_cloud_pages.XXXXXX")

  while [ -n "$path" ]; do
    page=$(call GET "$path")
    printf '%s\n' "$page" >> "$pages"
    next=$(printf '%s' "$page" | jq -r '.links.next // empty')
    path="${next#"$API_HOST"}"
  done

  jq -s 'map(.data) | add // []' "$pages"
  rm -f "$pages"
}

# <build> の引数をciBuildRunのIDの一覧（改行区切り）にする
resolve_build_ids() {
  local arg="$1"

  if [[ "$arg" =~ /ci/builds/([^/?#]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$arg" =~ $UUID_PATTERN ]]; then
    echo "$arg"
  elif [[ "$arg" =~ ^#?[0-9]+$ ]]; then
    local checks ids
    # pending のチェックがあると gh は非0で終わるため、終了コードではなく出力で判定する
    checks=$(gh pr checks "${arg#\#}" --json link 2>/dev/null || true)
    ids=$(printf '%s' "$checks" | jq -r '.[]?.link // empty' | sed -nE 's#.*/ci/builds/([^/?#]+).*#\1#p' | sort -u)
    if [ -z "$ids" ]; then
      echo "エラー: PR #${arg#\#} のチェックにXcode CloudのビルドURLが見つかりません（gh pr checks ${arg#\#} を確認してください）" >&2
      exit 1
    fi
    echo "$ids"
  else
    echo "エラー: PR番号・ciBuildRunのID・App Store ConnectのURLのいずれかを指定してください: $arg" >&2
    exit 1
  fi
}

# <action> の引数をciBuildActionのIDにする
resolve_action_id() {
  local arg="$1"

  if [[ "$arg" =~ /action/([^/?#]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$arg" =~ $UUID_PATTERN ]]; then
    echo "$arg"
  else
    echo "エラー: ciBuildActionのID、または .../action/<ID> を含むURLを指定してください: $arg" >&2
    exit 1
  fi
}

# issueの種類ごとの件数を「エラー/警告/テスト失敗/解析」の形で出力する
# ciBuildActions の issueCounts は null で返ることが多いため、issueの一覧から数える
issue_summary() {
  local action_id="$1"
  fetch_all "/v1/ciBuildActions/${action_id}/issues?limit=200" | jq -r '
    group_by(.attributes.issueType) | map({key: .[0].attributes.issueType, value: length}) | from_entries
    | "\(.ERROR // 0)/\(.WARNING // 0)/\(.TEST_FAILURE // 0)/\(.ANALYZER_WARNING // 0)"'
}

show_build() {
  local build_id="$1"
  local run actions

  run=$(call GET "/v1/ciBuildRuns/${build_id}?include=workflow,pullRequest")
  printf '%s' "$run" | jq -r '
    .data.attributes as $a
    | ([.included[]? | select(.type == "ciWorkflows") | .attributes.name] | first // "-") as $workflow
    | ([.included[]? | select(.type == "scmPullRequests") | .attributes.number] | first) as $pr
    | "Build #\($a.number) [\($workflow)]\(if $pr then " PR #\($pr)" else "" end)  id=\(.data.id)",
      "  進捗: \($a.executionProgress)  結果: \($a.completionStatus // "-")  開始理由: \($a.startReason // "-")\(if $a.cancelReason then "  中止理由: \($a.cancelReason)" else "" end)",
      "  commit: \(($a.sourceCommit.commitSha // "-")[0:8]) \(($a.sourceCommit.message // "") | split("\n")[0])",
      "  作成: \($a.createdDate // "-")  開始: \($a.startedDate // "-")  終了: \($a.finishedDate // "-")"'

  actions=$(fetch_all "/v1/ciBuildRuns/${build_id}/actions?limit=200")
  echo "  アクション（issues = エラー/警告/テスト失敗/解析）:"
  printf '%s' "$actions" | jq -r '.[] | [.id, .attributes.actionType, .attributes.executionProgress, (.attributes.completionStatus // "-"), .attributes.name] | @tsv' |
    while IFS=$'\t' read -r id type progress result name; do
      printf '    %s  %-7s %-8s %-9s issues=%s  %s\n' "$id" "$type" "$progress" "$result" "$(issue_summary "$id")" "$name"
    done
}

cmd_status() {
  local target="${1:?<build> を指定してください}"
  local ids id first=1
  # for の展開に $(...) を直接書くと set -e が効かず、解決に失敗しても0で終わるため変数に受ける
  ids=$(resolve_build_ids "$target")
  for id in $ids; do
    [ "$first" -eq 1 ] || echo
    first=0
    show_build "$id"
  done
}

cmd_issues() {
  local action_id type=""
  action_id=$(resolve_action_id "${1:?<action> を指定してください}")
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --type) type="$2"; shift 2 ;;
      *) echo "エラー: 不明なオプション: $1" >&2; exit 1 ;;
    esac
  done

  # パスはXcode Cloudのワークスペース（/Volumes/workspace/repository/）からの相対にして表示する
  fetch_all "/v1/ciBuildActions/${action_id}/issues?limit=200" | jq -r --arg type "$type" '
    map(select($type == "" or .attributes.issueType == $type))
    | "issues: \(length)件", (.[] | .attributes
      | "[\(.issueType)] \((.fileSource.path // "-") | sub("^file://"; "") | sub("^/Volumes/workspace/repository/"; "")):\(.fileSource.lineNumber // "-")",
        (.message | split("\n") | map("    " + .) | join("\n")))'
}

cmd_tests() {
  local action_id failed_only=false
  action_id=$(resolve_action_id "${1:?<action> を指定してください}")
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --failed) failed_only=true; shift ;;
      *) echo "エラー: 不明なオプション: $1" >&2; exit 1 ;;
    esac
  done

  fetch_all "/v1/ciBuildActions/${action_id}/testResults?limit=200" | jq -r --argjson failed_only "$failed_only" '
    "tests: \(length)件 (\(group_by(.attributes.status) | map("\(.[0].attributes.status)=\(length)") | join(", ")))",
    (.[] | .attributes
      | select(($failed_only | not) or .status == "FAILURE" or .status == "MIXED")
      | "[\(.status)] \(.className)/\(.name)  (\([.destinationTestResults[]? | "\(.deviceName) \(.osVersion): \(.status)"] | join(", ")))",
        (if .status == "SUCCESS" or .message == null then empty else (.message | split("\n") | map("    " + .) | join("\n")) end))'
}

cmd_artifacts() {
  local action_id
  action_id=$(resolve_action_id "${1:?<action> を指定してください}")
  # downloadUrl は署名付きURLなので表示しない
  fetch_all "/v1/ciBuildActions/${action_id}/artifacts?limit=200" | jq -r '
    sort_by(.attributes.fileType, .attributes.fileName)[]
    | [.id, .attributes.fileType, "\((.attributes.fileSize // 0) / 1048576 * 10 | round / 10)MB", .attributes.fileName] | @tsv'
}

cmd_download() {
  local action_id type="" name="" out=""
  action_id=$(resolve_action_id "${1:?<action> を指定してください}")
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --type) type="$2"; shift 2 ;;
      --name) name="$2"; shift 2 ;;
      --out) out="$2"; shift 2 ;;
      *) echo "エラー: 不明なオプション: $1" >&2; exit 1 ;;
    esac
  done

  if [ -z "$out" ]; then
    out=$(mktemp -d "${TMPDIR:-/tmp}/xcode-cloud.XXXXXX")
  elif [ -e "$out" ] && { [ ! -d "$out" ] || [ -n "$(ls -A "$out")" ]; }; then
    echo "エラー: --out には存在しないか空のディレクトリを指定してください: $out" >&2
    exit 1
  else
    mkdir -p "$out"
  fi
  out="$(cd "$out" && pwd)"

  local artifacts count
  artifacts=$(fetch_all "/v1/ciBuildActions/${action_id}/artifacts?limit=200" | jq -c --arg type "$type" --arg name "$name" '
    map(select(($type == "" or .attributes.fileType == $type) and ($name == "" or (.attributes.fileName | contains($name)))))')
  count=$(printf '%s' "$artifacts" | jq 'length')
  if [ "$count" -eq 0 ]; then
    echo "エラー: 条件に合うartifactがありません（artifacts で一覧を確認してください）" >&2
    exit 1
  fi

  printf '%s' "$artifacts" | jq -r '.[] | [.attributes.fileType, .attributes.fileName, .attributes.downloadUrl] | @tsv' |
    while IFS=$'\t' read -r file_type file_name url; do
      # ファイル名はAPIから来る値なので、パス区切りと先頭のドットを潰してから使う
      local safe zip dest
      safe=$(printf '%s' "$file_name" | tr '/' '_' | sed 's/^\.*//')
      zip="${out}/${safe}"
      dest="${out}/${safe%.zip}"

      echo "↓ [${file_type}] ${file_name}"
      curl -sS --fail -L -o "$zip" "$url"

      if zipinfo "$zip" 2>/dev/null | grep -q '^l'; then
        echo "  ⚠ シンボリックリンクを含むため展開しません: $zip" >&2
        continue
      fi
      mkdir "$dest"
      unzip -q "$zip" -d "$dest"
      rm -f "$zip"
      echo "  → $dest"
    done

  echo "保存先: $out"
}

cmd_wait() {
  local target="${1:?<build> を指定してください}"
  local interval=60 timeout=3600
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --interval) interval="$2"; shift 2 ;;
      --timeout) timeout="$2"; shift 2 ;;
      *) echo "エラー: 不明なオプション: $1" >&2; exit 1 ;;
    esac
  done

  local ids deadline id attrs pending results
  ids=$(resolve_build_ids "$target")
  deadline=$(( $(date +%s) + timeout ))

  while true; do
    pending=0
    results=""
    for id in $ids; do
      attrs=$(call GET "/v1/ciBuildRuns/${id}" | jq -r '.data.attributes | "\(.number)\t\(.executionProgress)\t\(.completionStatus // "-")"')
      IFS=$'\t' read -r number progress result <<< "$attrs"
      echo "$(date '+%H:%M:%S') Build #${number}: ${progress} ${result}"
      if [ "$progress" != "COMPLETE" ]; then
        pending=1
      fi
      results="${results}${result}"$'\n'
    done

    if [ "$pending" -eq 0 ]; then
      break
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "打ち切り: ${timeout}秒たっても完了しませんでした" >&2
      exit 124
    fi
    sleep "$interval"
  done

  echo
  for id in $ids; do
    show_build "$id"
  done

  if printf '%s' "$results" | grep -v '^$' | grep -qv '^SUCCEEDED$'; then
    exit 1
  fi
}

xcode_cloud_main() {
  local command="${1:-}"
  if [ -z "$command" ] || [ "$command" = "help" ] || [ "$command" = "-h" ] || [ "$command" = "--help" ]; then
    usage
    [ -n "$command" ] || exit 1
    exit 0
  fi
  shift

  check_requirements

  case "$command" in
    status) cmd_status "$@" ;;
    issues) cmd_issues "$@" ;;
    tests) cmd_tests "$@" ;;
    artifacts) cmd_artifacts "$@" ;;
    download) cmd_download "$@" ;;
    wait) cmd_wait "$@" ;;
    *) usage; exit 1 ;;
  esac
}

xcode_cloud_main "$@"
