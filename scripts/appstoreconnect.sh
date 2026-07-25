#!/bin/bash
#
# App Store Connect API を使ってSubscriptionの配信可否・価格・ローカリゼーション・
# 審査用スクリーンショットを操作するCLI
#
# 必須環境変数（fastlane/Fastfile の ASC_KEY_ID / ASC_ISSUER_ID / ASC_API_KEY_PATH と同じ命名）:
#   ASC_KEY_ID        App Store Connect APIキーのKey ID
#   ASC_ISSUER_ID     App Store Connect APIキーのIssuer ID
#   ASC_API_KEY_PATH  秘密鍵ファイル(.p8)へのパス
#
# 注意:
#   `call` サブコマンドと `subscriptions get/prices/localizations` 系のGET系は
#   JSON:API仕様上とても安定しているため信頼度が高いですが、
#   価格/ローカリゼーション作成やスクリーンショットアップロードのリクエストボディ形式は
#   Apple公式ドキュメント（SPAでスクレイピング困難だったため今回未実機検証）を基にした
#   ベストエフォート実装です。エラー時はレスポンスのJSON:APIエラーメッセージを見ながら
#   https://developer.apple.com/documentation/appstoreconnectapi と照合してください。

set -e

API_HOST="https://api.appstoreconnect.apple.com"

usage() {
  cat <<'EOS'
Usage: appstoreconnect.sh <command> [args...]

汎用コマンド（どのエンドポイントにも使える。Apple公式ドキュメントのリクエストボディをそのまま渡せます）:
  call <METHOD> <path> [--data '<json>' | --data-file <path>]
    ※ pathには /v1/... または /v2/... とバージョンを含めてください
       （Subscription系は/v1、InAppPurchase(v2)系は/v2、で実機確認済み）
    例: appstoreconnect.sh call GET /v1/subscriptions/6794541936
        appstoreconnect.sh call GET /v1/subscriptions/6794541936/subscriptionAvailability
        appstoreconnect.sh call PATCH /v1/subscriptionLocalizations/{localization_id} \
          --data '{"data":{"type":"subscriptionLocalizations","id":"{localization_id}","attributes":{"name":"...","description":"..."}}}'
        appstoreconnect.sh call GET /v2/inAppPurchases/6794541732/pricePoints

  ※ 配信可否(availability)は subscriptions の属性ではなく、
    /v1/subscriptions/{id}/subscriptionAvailability という別リソース(subscriptionAvailabilities)経由です。
    実データで確認したところ attributes.availableInNewTerritories と
    relationships.availableTerritories で構成されています（実機確認済み）。

便利コマンド（実機確認済み）:
  subscriptions get <subscription_id>
  subscriptions availability get <subscription_id>
  subscriptions prices list <subscription_id>
  subscriptions prices set <subscription_id> <price_point_id> <territory>
  subscriptions price-points list <subscription_id>
  subscriptions price-points find <subscription_id> <territory> <amount>
  subscriptions localizations list <subscription_id>

  inapp get <in_app_purchase_id>                    (買い切り商品。v2 API)
  inapp price-points list <in_app_purchase_id>
  inapp price-points find <in_app_purchase_id> <territory> <amount>
  inapp price set-base <in_app_purchase_id> <price_point_id> <territory>
    ※ 初回のPrice Schedule作成のみ確認済み。既存Schedule更新は未検証
  inapp localizations list <in_app_purchase_id>

  例: 月額プランをJPY 450にする
    price_point=$(appstoreconnect.sh subscriptions price-points find 6794541936 JPN 450 | jq -r .id)
    appstoreconnect.sh subscriptions prices set 6794541936 "$price_point" JPN

  例: 買い切り商品をJPY 3600にする（初回のみ）
    price_point=$(appstoreconnect.sh inapp price-points find 6794541732 JPN 3600 | jq -r .id)
    appstoreconnect.sh inapp price set-base 6794541732 "$price_point" JPN

設定ファイルによる一括反映（価格の一元管理）:
  apply-prices [config_path]
    デフォルト: scripts/appstoreconnect.products.json
    ファイル内の subscriptions[].prices / inAppPurchases[].prices を読み込み、
    price-points find → prices set (またはinapp price set-base) を自動実行します。
    ※ inAppPurchasesはbaseTerritory分の初回設定のみ対応（複数territory・Schedule更新後の反映は未対応）

スクリーンショットアップロード（予約 → バイナリアップロード → コミットの3ステップを自動実行）:
  subscriptions screenshot upload <subscription_id> <file_path>

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

# ES256でJWTを生成し、変数 JWT にセットする
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

  if [ -n "$response_body" ]; then
    echo "$response_body" | jq .
  fi

  if [ "$http_status" -lt 200 ] || [ "$http_status" -ge 300 ]; then
    echo "エラー: HTTP ${http_status}" >&2
    exit 1
  fi
}

# price_point_id を territory + customerPrice の完全一致で検索する（ページング対応）
# 使い方: find_price_point <pricePointsのパス> <territory> <amount>
find_price_point() {
  local base_path="$1"
  local territory="$2"
  local amount="$3"
  local path="${base_path}?filter%5Bterritory%5D=${territory}&limit=200"
  local result match next

  while [ -n "$path" ]; do
    generate_jwt
    result=$(curl -sS "${API_HOST}${path}" -H "Authorization: Bearer ${JWT}")
    match=$(echo "$result" | jq -c --arg amount "$amount" '.data[] | select(.attributes.customerPrice == $amount)')
    if [ -n "$match" ]; then
      echo "$match" | jq .
      return 0
    fi
    next=$(echo "$result" | jq -r '.links.next // empty')
    if [ -z "$next" ]; then
      echo "エラー: territory=${territory} amount=${amount} に一致する価格ポイントが見つかりませんでした" >&2
      return 1
    fi
    path="${next#${API_HOST}}"
  done
}

# 残り引数から --data / --data-file を取り出してBODYに格納する
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

# subscriptions screenshot upload <subscription_id> <file_path>
upload_screenshot() {
  local subscription_id="$1"
  local file_path="$2"

  if [ ! -f "$file_path" ]; then
    echo "エラー: ファイルが存在しません: ${file_path}" >&2
    exit 1
  fi

  local file_name file_size reserve_body reserve_response
  file_name=$(basename "$file_path")
  file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path")

  reserve_body=$(jq -n \
    --arg fileName "$file_name" \
    --argjson fileSize "$file_size" \
    --arg subscriptionId "$subscription_id" \
    '{
      data: {
        type: "subscriptionAppStoreReviewScreenshots",
        attributes: { fileName: $fileName, fileSize: $fileSize },
        relationships: { subscription: { data: { type: "subscriptions", id: $subscriptionId } } }
      }
    }')

  echo "1/3: アセットを予約中..." >&2
  generate_jwt
  reserve_response=$(curl -sS -w '\n%{http_code}' \
    -X POST "${API_HOST}/v1/subscriptionAppStoreReviewScreenshots" \
    -H "Authorization: Bearer ${JWT}" \
    -H "Content-Type: application/json" \
    -d "$reserve_body")

  local http_status reserve_body_json
  http_status=$(echo "$reserve_response" | tail -n1)
  reserve_body_json=$(echo "$reserve_response" | sed '$d')

  if [ "$http_status" -lt 200 ] || [ "$http_status" -ge 300 ]; then
    echo "$reserve_body_json" | jq .
    echo "エラー: アセット予約に失敗しました (HTTP ${http_status})" >&2
    exit 1
  fi

  local screenshot_id
  screenshot_id=$(echo "$reserve_body_json" | jq -r '.data.id')

  echo "2/3: バイナリをアップロード中..." >&2
  echo "$reserve_body_json" | jq -c '.data.attributes.uploadOperations[]' | while read -r op; do
    local op_method op_url op_offset op_length header_args header_line chunk_file
    op_method=$(echo "$op" | jq -r '.method')
    op_url=$(echo "$op" | jq -r '.url')
    op_offset=$(echo "$op" | jq -r '.offset')
    op_length=$(echo "$op" | jq -r '.length')

    header_args=()
    while IFS= read -r header_line; do
      header_args+=(-H "$header_line")
    done < <(echo "$op" | jq -r '.requestHeaders[] | "\(.name): \(.value)"')

    chunk_file=$(mktemp "${TMPDIR:-/tmp}/asc_screenshot_chunk.XXXXXX")
    dd if="$file_path" of="$chunk_file" bs=1 skip="$op_offset" count="$op_length" 2>/dev/null

    curl -sS -X "$op_method" "$op_url" "${header_args[@]}" --data-binary "@${chunk_file}" -o /dev/null
    rm -f "$chunk_file"
  done

  local checksum commit_body
  checksum=$(md5 -q "$file_path" 2>/dev/null || md5sum "$file_path" | awk '{print $1}')

  commit_body=$(jq -n \
    --arg id "$screenshot_id" \
    --arg checksum "$checksum" \
    '{
      data: {
        type: "subscriptionAppStoreReviewScreenshots",
        id: $id,
        attributes: { uploaded: true, sourceFileChecksum: $checksum }
      }
    }')

  echo "3/3: アップロードをコミット中..." >&2
  call PATCH "/v1/subscriptionAppStoreReviewScreenshots/${screenshot_id}" "$commit_body"
}

# appstoreconnect.products.json を読み込んで価格を一括反映する
# 使い方: apply_prices [config_path]
apply_prices() {
  local config_path="${1:-$(dirname "$0")/appstoreconnect.products.json}"

  if [ ! -f "$config_path" ]; then
    echo "エラー: 設定ファイルが見つかりません: ${config_path}" >&2
    exit 1
  fi

  local sub product_id subscription_id display_name
  jq -c '.subscriptions[]' "$config_path" | while read -r sub; do
    product_id=$(echo "$sub" | jq -r '.productId')
    subscription_id=$(echo "$sub" | jq -r '.subscriptionId')
    display_name=$(echo "$sub" | jq -r '.displayName')

    echo "$sub" | jq -c '.prices[]' | while read -r price; do
      local territory amount price_point_id
      territory=$(echo "$price" | jq -r '.territory')
      amount=$(echo "$price" | jq -r '.amount')

      echo "[subscriptions] ${display_name} (${product_id} / ${subscription_id}): ${territory} ${amount}円 を設定中..." >&2
      price_point_id=$(find_price_point "/v1/subscriptions/${subscription_id}/pricePoints" "$territory" "$amount" | jq -r '.id')

      local body
      body=$(jq -n --arg sub "$subscription_id" --arg pp "$price_point_id" --arg territory "$territory" \
        '{data:{type:"subscriptionPrices",attributes:{preserveCurrentPrice:false},relationships:{
          subscription:{data:{type:"subscriptions",id:$sub}},
          subscriptionPricePoint:{data:{type:"subscriptionPricePoints",id:$pp}},
          territory:{data:{type:"territories",id:$territory}}
        }}}')
      call POST /v1/subscriptionPrices "$body" > /dev/null
      echo "[subscriptions] ${display_name}: 完了" >&2
    done
  done

  local iap in_app_purchase_id base_territory
  jq -c '.inAppPurchases[]' "$config_path" | while read -r iap; do
    product_id=$(echo "$iap" | jq -r '.productId')
    in_app_purchase_id=$(echo "$iap" | jq -r '.inAppPurchaseId')
    display_name=$(echo "$iap" | jq -r '.displayName')
    base_territory=$(echo "$iap" | jq -r '.baseTerritory')

    local base_price
    base_price=$(echo "$iap" | jq -c --arg t "$base_territory" '.prices[] | select(.territory == $t)')
    if [ -z "$base_price" ]; then
      echo "エラー: [inapp] ${display_name}: baseTerritory(${base_territory})に対応するpricesの指定がありません" >&2
      continue
    fi

    local amount price_point_id
    amount=$(echo "$base_price" | jq -r '.amount')

    echo "[inapp] ${display_name} (${product_id} / ${in_app_purchase_id}): base=${base_territory} ${amount}円 を設定中..." >&2
    price_point_id=$(find_price_point "/v2/inAppPurchases/${in_app_purchase_id}/pricePoints" "$base_territory" "$amount" | jq -r '.id')

    local body
    body=$(jq -n --arg iap "$in_app_purchase_id" --arg pp "$price_point_id" --arg territory "$base_territory" \
      '{data:{type:"inAppPurchasePriceSchedules",relationships:{
        inAppPurchase:{data:{type:"inAppPurchases",id:$iap}},
        baseTerritory:{data:{type:"territories",id:$territory}},
        manualPrices:{data:[{type:"inAppPurchasePrices",id:"${temp-price-1}"}]}
      }},included:[{
        type:"inAppPurchasePrices",
        id:"${temp-price-1}",
        attributes:{startDate:null},
        relationships:{inAppPurchasePricePoint:{data:{type:"inAppPurchasePricePoints",id:$pp}}}
      }]}')
    call POST /v1/inAppPurchasePriceSchedules "$body" > /dev/null
    echo "[inapp] ${display_name}: 完了（baseTerritory分のみ。複数territory指定分の反映は未対応）" >&2
  done
}

main() {
  if [ "$#" -lt 1 ]; then
    usage
    exit 1
  fi

  check_requirements

  local command="$1"
  shift

  case "$command" in
    call)
      local method="$1"
      local path="$2"
      shift 2
      if [ "$method" = "GET" ] || [ "$method" = "DELETE" ]; then
        call "$method" "$path"
      else
        parse_body_args "$@"
        call "$method" "$path" "$BODY"
      fi
      ;;

    subscriptions)
      local action="$1"
      shift
      case "$action" in
        get)
          call GET "/v1/subscriptions/$1"
          ;;
        availability)
          if [ "$1" = "get" ]; then
            call GET "/v1/subscriptions/$2/subscriptionAvailability"
          else
            usage
            exit 1
          fi
          ;;
        prices)
          case "$1" in
            list)
              call GET "/v1/subscriptions/$2/prices"
              ;;
            set)
              # subscriptions prices set <subscription_id> <price_point_id> <territory>  (実機確認済み)
              local body
              body=$(jq -n --arg sub "$2" --arg pp "$3" --arg territory "$4" \
                '{data:{type:"subscriptionPrices",attributes:{preserveCurrentPrice:false},relationships:{
                  subscription:{data:{type:"subscriptions",id:$sub}},
                  subscriptionPricePoint:{data:{type:"subscriptionPricePoints",id:$pp}},
                  territory:{data:{type:"territories",id:$territory}}
                }}}')
              call POST /v1/subscriptionPrices "$body"
              ;;
            *)
              usage
              exit 1
              ;;
          esac
          ;;
        price-points)
          case "$1" in
            list)
              call GET "/v1/subscriptions/$2/pricePoints"
              ;;
            find)
              # subscriptions price-points find <subscription_id> <territory> <amount>  (実機確認済み)
              find_price_point "/v1/subscriptions/$2/pricePoints" "$3" "$4"
              ;;
            *)
              usage
              exit 1
              ;;
          esac
          ;;
        localizations)
          if [ "$1" = "list" ]; then
            call GET "/v1/subscriptions/$2/subscriptionLocalizations"
          else
            usage
            exit 1
          fi
          ;;
        screenshot)
          if [ "$1" = "upload" ]; then
            upload_screenshot "$2" "$3"
          else
            usage
            exit 1
          fi
          ;;
        *)
          usage
          exit 1
          ;;
      esac
      ;;

    inapp)
      local action="$1"
      shift
      case "$action" in
        get)
          call GET "/v2/inAppPurchases/$1"
          ;;
        price-points)
          case "$1" in
            list)
              call GET "/v2/inAppPurchases/$2/pricePoints"
              ;;
            find)
              # inapp price-points find <in_app_purchase_id> <territory> <amount>  (実機確認済み)
              find_price_point "/v2/inAppPurchases/$2/pricePoints" "$3" "$4"
              ;;
            *)
              usage
              exit 1
              ;;
          esac
          ;;
        price)
          if [ "$1" = "set-base" ]; then
            # inapp price set-base <in_app_purchase_id> <price_point_id> <territory>  (実機確認済み)
            # 注意: 初回のPrice Schedule作成のみ動作確認済みです。
            # 既にSchedule作成済みの商品に価格を追加/変更する場合はPATCHが必要になる可能性がありますが未検証です。
            local body
            body=$(jq -n --arg iap "$2" --arg pp "$3" --arg territory "$4" \
              '{data:{type:"inAppPurchasePriceSchedules",relationships:{
                inAppPurchase:{data:{type:"inAppPurchases",id:$iap}},
                baseTerritory:{data:{type:"territories",id:$territory}},
                manualPrices:{data:[{type:"inAppPurchasePrices",id:"${temp-price-1}"}]}
              }},included:[{
                type:"inAppPurchasePrices",
                id:"${temp-price-1}",
                attributes:{startDate:null},
                relationships:{inAppPurchasePricePoint:{data:{type:"inAppPurchasePricePoints",id:$pp}}}
              }]}')
            call POST /v1/inAppPurchasePriceSchedules "$body"
          else
            usage
            exit 1
          fi
          ;;
        localizations)
          if [ "$1" = "list" ]; then
            call GET "/v2/inAppPurchases/$2/inAppPurchaseLocalizations"
          else
            usage
            exit 1
          fi
          ;;
        *)
          usage
          exit 1
          ;;
      esac
      ;;

    apply-prices)
      apply_prices "$1"
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
