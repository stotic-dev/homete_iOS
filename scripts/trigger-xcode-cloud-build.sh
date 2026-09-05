#!/bin/bash
#
# App Store Connect API経由でXcode Cloudのビルドを開始するCLI。
# JWT生成・API呼び出しの仕組みはscripts/appstoreconnect.shと同じ実装を踏襲している
# （そちらはSubscription操作で実機確認済み。このスクリプトのciBuildRuns作成部分は
# Apple公式ドキュメントの仕様に基づくが未検証。初回実行時はApp Store Connect側で
# 実際にビルドが開始されるか確認すること）。
#
# 使い方: trigger-xcode-cloud-build.sh <workflow_id> [branch_name]
#   branch_nameを省略した場合は main を対象にする。
#
# 必須環境変数（fastlane/Fastfile の ASC_KEY_ID / ASC_ISSUER_ID / ASC_API_KEY_PATH と同じ命名）:
#   ASC_KEY_ID        App Store Connect APIキーのKey ID
#   ASC_ISSUER_ID     App Store Connect APIキーのIssuer ID
#   ASC_API_KEY_PATH  秘密鍵ファイル(.p8)へのパス

set -e

API_HOST="https://api.appstoreconnect.apple.com"

usage() {
  cat <<'EOS'
Usage: trigger-xcode-cloud-build.sh <workflow_id> [branch_name]

  workflow_id   Xcode CloudワークフローのID（App Store Connect上のワークフロー詳細画面URLに含まれるID）
  branch_name   ビルド対象のgit branch名（省略時は main）

Env:
  ASC_KEY_ID        App Store Connect APIキーのKey ID (必須)
  ASC_ISSUER_ID     App Store Connect APIキーのIssuer ID (必須)
  ASC_API_KEY_PATH  秘密鍵ファイル(.p8)へのパス (必須)
EOS
}

check_requirements() {
  for cmd in curl jq openssl python3; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "エラー: ${cmd} が見つかりません" >&2
      exit 1
    fi
  done
  if [ -z "${ASC_KEY_ID:-}" ]; then
    echo "エラー: 環境変数 ASC_KEY_ID が未設定です" >&2
    exit 1
  fi
  if [ -z "${ASC_ISSUER_ID:-}" ]; then
    echo "エラー: 環境変数 ASC_ISSUER_ID が未設定です" >&2
    exit 1
  fi
  if [ -z "${ASC_API_KEY_PATH:-}" ] || [ ! -f "$ASC_API_KEY_PATH" ]; then
    echo "エラー: 環境変数 ASC_API_KEY_PATH が未設定、またはファイルが存在しません" >&2
    exit 1
  fi
}

base64url() {
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

# ES256でJWTを生成し、変数 JWT にセットする（scripts/appstoreconnect.shと同一実装）
generate_jwt() {
  local now exp header_b64 payload_b64 signing_input der_sig_file sig_b64

  now=$(date +%s)
  exp=$((now + 1190))

  header_b64=$(printf '{"alg":"ES256","kid":"%s","typ":"JWT"}' "$ASC_KEY_ID" | base64url)
  payload_b64=$(printf '{"iss":"%s","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}' "$ASC_ISSUER_ID" "$now" "$exp" | base64url)
  signing_input="${header_b64}.${payload_b64}"

  der_sig_file=$(mktemp "${TMPDIR:-/tmp}/asc_jwt_sig.XXXXXX")
  printf '%s' "$signing_input" | openssl dgst -sha256 -sign "$ASC_API_KEY_PATH" -out "$der_sig_file"

  # ES256のJWT署名はDER(ASN.1)ではなくraw r||s(32byte+32byte)が必要なため変換する
  sig_b64=$(python3 - "$der_sig_file" <<'PY'
import sys, base64

with open(sys.argv[1], "rb") as f:
    der = f.read()


def read_len(data, idx):
    length = data[idx]
    idx += 1
    if length & 0x80:
        n = length & 0x7F
        length = int.from_bytes(data[idx:idx + n], "big")
        idx += n
    return length, idx


def read_int(data, idx):
    assert data[idx] == 0x02
    idx += 1
    length, idx = read_len(data, idx)
    val = data[idx:idx + length]
    idx += length
    return val, idx


idx = 1  # SEQUENCEタグをskip
_, idx = read_len(der, idx)
r, idx = read_int(der, idx)
s, idx = read_int(der, idx)
r = r.lstrip(b"\x00").rjust(32, b"\x00")
s = s.lstrip(b"\x00").rjust(32, b"\x00")
raw = r + s
sys.stdout.write(base64.urlsafe_b64encode(raw).rstrip(b"=").decode())
PY
)
  rm -f "$der_sig_file"

  JWT="${signing_input}.${sig_b64}"
}

# call <METHOD> <path> [BODY]
call() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local url="${API_HOST}${path}"
  local response http_status response_body

  generate_jwt

  if [ -n "$body" ]; then
    response=$(curl -sS -w '\n%{http_code}' \
      -X "$method" "$url" \
      -H "Authorization: Bearer ${JWT}" \
      -H "Content-Type: application/json" \
      -d "$body")
  else
    response=$(curl -sS -w '\n%{http_code}' \
      -X "$method" "$url" \
      -H "Authorization: Bearer ${JWT}")
  fi

  http_status=$(echo "$response" | tail -n1)
  response_body=$(echo "$response" | sed '$d')

  if [ "$http_status" -lt 200 ] || [ "$http_status" -ge 300 ]; then
    if [ -n "$response_body" ]; then
      echo "$response_body" | jq . >&2
    fi
    echo "エラー: HTTP ${http_status}" >&2
    exit 1
  fi

  if [ -n "$response_body" ]; then
    echo "$response_body"
  fi
}

main() {
  local workflow_id="${1:?usage: $0 <workflow_id> [branch_name]}"
  local branch_name="${2:-main}"

  check_requirements

  echo "Resolving repository for workflow ${workflow_id}..." >&2
  local workflow_response repository_id
  workflow_response=$(call GET "/v1/ciWorkflows/${workflow_id}?include=repository")
  repository_id=$(echo "$workflow_response" | jq -r '.data.relationships.repository.data.id // empty')

  if [ -z "$repository_id" ]; then
    echo "エラー: workflow ${workflow_id} に紐づくscmRepositoryが見つかりませんでした" >&2
    exit 1
  fi
  echo "✓ repository_id=${repository_id}" >&2

  echo "Resolving git reference for branch ${branch_name}..." >&2
  local git_refs_response git_reference_id
  git_refs_response=$(call GET "/v1/scmRepositories/${repository_id}/gitReferences?filter[name]=${branch_name}&limit=1")
  git_reference_id=$(echo "$git_refs_response" | jq -r '.data[0].id // empty')

  if [ -z "$git_reference_id" ]; then
    echo "エラー: branch ${branch_name} のgitReferenceが見つかりませんでした" >&2
    exit 1
  fi
  echo "✓ git_reference_id=${git_reference_id}" >&2

  echo "Starting Xcode Cloud build..." >&2
  local body build_response build_id build_number
  body=$(jq -n --arg workflow_id "$workflow_id" --arg ref_id "$git_reference_id" \
    '{data:{type:"ciBuildRuns",relationships:{
      workflow:{data:{type:"ciWorkflows",id:$workflow_id}},
      sourceBranchOrTag:{data:{type:"scmGitReferences",id:$ref_id}}
    }}}')
  build_response=$(call POST "/v2/ciBuildRuns" "$body")
  build_id=$(echo "$build_response" | jq -r '.data.id // empty')
  build_number=$(echo "$build_response" | jq -r '.data.attributes.number // empty')

  if [ -z "$build_id" ]; then
    echo "エラー: ビルド開始のレスポンスにidが含まれていませんでした" >&2
    echo "$build_response" | jq . >&2
    exit 1
  fi

  echo "✓ Xcode Cloud build started: id=${build_id} number=${build_number}"
}

if [ "$#" -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 1
fi

main "$@"
