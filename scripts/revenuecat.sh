#!/bin/bash
#
# RevenueCat REST API v2 を使ってProducts / Entitlements / Offerings を操作するCLI
#
# 必須環境変数:
#   REVENUECAT_SECRET_API_KEY  RevenueCatのSecret API Key (sk_...)
#   REVENUECAT_PROJECT_ID      RevenueCatのProject ID
#
# 参考: https://www.revenuecat.com/docs/api-v2

set -e

API_BASE_URL="https://api.revenuecat.com/v2"

usage() {
  cat <<'EOS'
Usage: revenuecat.sh <resource> <action> [id...] [--data '<json>' | --data-file <path>]

Resources / Actions:
  products list
  products create                              --data|--data-file <json>
  products update <product_id>                 --data|--data-file <json>

  entitlements list
  entitlements create                          --data|--data-file <json>
  entitlements update <entitlement_id>         --data|--data-file <json>
  entitlements list-products <entitlement_id>
  entitlements attach-products <entitlement_id> --data|--data-file <json>
  entitlements detach-products <entitlement_id> --data|--data-file <json>

  offerings list
  offerings create                             --data|--data-file <json>
  offerings update <offering_id>               --data|--data-file <json>
  offerings update-metadata <offering_id>      --data|--data-file <json (metadataオブジェクト本体)>
  offerings list-packages <offering_id>
  offerings create-package <offering_id>       --data|--data-file <json>
  offerings update-package <offering_id> <package_id>        --data|--data-file <json>
  offerings attach-products <offering_id> <package_id>       --data|--data-file <json>
  offerings detach-products <offering_id> <package_id>       --data|--data-file <json>

Env:
  REVENUECAT_SECRET_API_KEY  RevenueCatのSecret API Key (必須)
  REVENUECAT_PROJECT_ID      RevenueCatのProject ID (必須)

Example:
  REVENUECAT_SECRET_API_KEY=sk_xxx REVENUECAT_PROJECT_ID=proj_xxx \
    scripts/revenuecat.sh offerings update-metadata proj_offering_id \
    --data '{"paywall_title_copy": "Unlock all benefits"}'
EOS
}

check_requirements() {
  if ! command -v curl &> /dev/null; then
    echo "エラー: curl が見つかりません" >&2
    exit 1
  fi
  if ! command -v jq &> /dev/null; then
    echo "エラー: jq が見つかりません（brew install jq）" >&2
    exit 1
  fi
  if [ -z "${REVENUECAT_SECRET_API_KEY:-}" ]; then
    echo "エラー: 環境変数 REVENUECAT_SECRET_API_KEY が未設定です" >&2
    exit 1
  fi
  if [ -z "${REVENUECAT_PROJECT_ID:-}" ]; then
    echo "エラー: 環境変数 REVENUECAT_PROJECT_ID が未設定です" >&2
    exit 1
  fi
}

# 残り引数から --data / --data-file を取り出してBODYに格納する
# 使い方: parse_body_args "$@" ＆ 結果は $BODY に入る
parse_body_args() {
  BODY=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --data)
        BODY="$2"
        shift 2
        ;;
      --data-file)
        BODY="$(cat "$2")"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  if [ -z "$BODY" ]; then
    echo "エラー: --data '<json>' または --data-file <path> でリクエストボディを指定してください" >&2
    exit 1
  fi
}

# HTTPリクエストを実行して結果を整形出力する
# 使い方: call <METHOD> <PATH> [BODY]
call() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local url="${API_BASE_URL}${path}"
  local response
  local http_status

  if [ -n "$body" ]; then
    response=$(curl -sS -w '\n%{http_code}' \
      -X "$method" "$url" \
      -H "Authorization: Bearer ${REVENUECAT_SECRET_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body")
  else
    response=$(curl -sS -w '\n%{http_code}' \
      -X "$method" "$url" \
      -H "Authorization: Bearer ${REVENUECAT_SECRET_API_KEY}")
  fi

  http_status=$(echo "$response" | tail -n1)
  response_body=$(echo "$response" | sed '$d')

  if [ -n "$response_body" ]; then
    echo "$response_body" | jq .
  fi

  if [ "$http_status" -lt 200 ] || [ "$http_status" -ge 300 ]; then
    echo "エラー: HTTP ${http_status}" >&2
    exit 1
  fi
}

main() {
  if [ "$#" -lt 2 ]; then
    usage
    exit 1
  fi

  check_requirements

  local resource="$1"
  local action="$2"
  shift 2

  local project_path="/projects/${REVENUECAT_PROJECT_ID}"

  case "$resource" in
    products)
      case "$action" in
        list)
          call GET "${project_path}/products"
          ;;
        create)
          parse_body_args "$@"
          call POST "${project_path}/products" "$BODY"
          ;;
        update)
          local product_id="$1"
          shift
          parse_body_args "$@"
          call POST "${project_path}/products/${product_id}" "$BODY"
          ;;
        *)
          usage
          exit 1
          ;;
      esac
      ;;

    entitlements)
      case "$action" in
        list)
          call GET "${project_path}/entitlements"
          ;;
        create)
          parse_body_args "$@"
          call POST "${project_path}/entitlements" "$BODY"
          ;;
        update)
          local entitlement_id="$1"
          shift
          parse_body_args "$@"
          call POST "${project_path}/entitlements/${entitlement_id}" "$BODY"
          ;;
        list-products)
          local entitlement_id="$1"
          call GET "${project_path}/entitlements/${entitlement_id}/products"
          ;;
        attach-products)
          local entitlement_id="$1"
          shift
          parse_body_args "$@"
          call POST "${project_path}/entitlements/${entitlement_id}/actions/attach_products" "$BODY"
          ;;
        detach-products)
          local entitlement_id="$1"
          shift
          parse_body_args "$@"
          call POST "${project_path}/entitlements/${entitlement_id}/actions/detach_products" "$BODY"
          ;;
        *)
          usage
          exit 1
          ;;
      esac
      ;;

    offerings)
      case "$action" in
        list)
          call GET "${project_path}/offerings"
          ;;
        create)
          parse_body_args "$@"
          call POST "${project_path}/offerings" "$BODY"
          ;;
        update)
          local offering_id="$1"
          shift
          parse_body_args "$@"
          call POST "${project_path}/offerings/${offering_id}" "$BODY"
          ;;
        update-metadata)
          local offering_id="$1"
          shift
          parse_body_args "$@"
          local metadata_body
          metadata_body=$(jq -n --argjson metadata "$BODY" '{metadata: $metadata}')
          call POST "${project_path}/offerings/${offering_id}" "$metadata_body"
          ;;
        list-packages)
          local offering_id="$1"
          call GET "${project_path}/offerings/${offering_id}/packages"
          ;;
        create-package)
          local offering_id="$1"
          shift
          parse_body_args "$@"
          call POST "${project_path}/offerings/${offering_id}/packages" "$BODY"
          ;;
        update-package)
          local offering_id="$1"
          local package_id="$2"
          shift 2
          parse_body_args "$@"
          call POST "${project_path}/offerings/${offering_id}/packages/${package_id}" "$BODY"
          ;;
        attach-products)
          local offering_id="$1"
          local package_id="$2"
          shift 2
          parse_body_args "$@"
          call POST "${project_path}/offerings/${offering_id}/packages/${package_id}/actions/attach_products" "$BODY"
          ;;
        detach-products)
          local offering_id="$1"
          local package_id="$2"
          shift 2
          parse_body_args "$@"
          call POST "${project_path}/offerings/${offering_id}/packages/${package_id}/actions/detach_products" "$BODY"
          ;;
        *)
          usage
          exit 1
          ;;
      esac
      ;;

    -h|--help|help)
      usage
      ;;

    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
