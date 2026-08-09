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
#   `call` サブコマンドと `subscriptions get/prices/localizations` 系のGET系、
#   価格/ローカリゼーション作成、スクリーンショットアップロードは全て実機確認済みです。
#   それ以外の未検証箇所はコマンドごとのコメントに明記しています。
#   エラー時はレスポンスのJSON:APIエラーメッセージを見ながら
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
  inapp localizations set <in_app_purchase_id> <locale> <name> <description>
    ※ 既存localeがあればPATCH、無ければPOSTで作成（upsert、実機確認済み）
    ※ 初回はinAppPurchaseVersionsが未作成のため自動的に作成してから紐付けます

  例: 月額プランをJPY 450にする
    price_point=$(appstoreconnect.sh subscriptions price-points find 6794541936 JPN 450 | jq -r .id)
    appstoreconnect.sh subscriptions prices set 6794541936 "$price_point" JPN

  例: 買い切り商品をJPY 3600にする（初回のみ）
    price_point=$(appstoreconnect.sh inapp price-points find 6794541732 JPN 3600 | jq -r .id)
    appstoreconnect.sh inapp price set-base 6794541732 "$price_point" JPN

  例: サブスクリプションの日本語ローカライズを設定する
    appstoreconnect.sh subscriptions localizations set 6794541936 ja "プレミアムプラン（月額）" "全機能が使い放題の月額プラン"

設定ファイルによる一括反映（ASC側メタデータの一元管理）:
  共通オプション: [config_path] [--env dev|prd]
    config_path のデフォルトは scripts/appstoreconnect.products.json
    --env を付けると設定ファイルの apps のキーに一致する env のプロダクトだけを対象にします

  apply-all [config_path] [--env dev|prd]
    以下を「販売可能になるために必要な依存順」でまとめて実行し、最後に verify します。
      1. apply-group-localizations
      2. apply-availability
      3. apply-prices
      4. apply-localizations
      5. apply-screenshots
    新しいプロダクトを追加したら、ASC側でリソースを作ってIDをconfigに書き、これを叩けば済みます。

  apply-group-localizations [config_path] [--env ...]
    subscriptionGroups[].localizations を upsert します。
    ※ サブスクグループ名は商品側ローカライズとは別リソースで、ここが未設定だと
      商品の価格・ローカライズを全て埋めても state が MISSING_METADATA のままになります

  apply-availability [config_path] [--env ...]
    subscriptions[].availability を反映します。territories は "all"（ASCの全地域）か
    ["JPN","USA"] のような配列で指定します。
    ※ 新規作成は実機確認済み。既存に地域を追加するケースは未検証

  apply-prices [config_path] [--env ...]
    subscriptions[].prices / inAppPurchases[].prices を反映します。
    subscriptions[].equalizeFrom に基準territoryを指定すると、その価格と等価な価格を
    equalizations API 経由で配信対象の全地域へ展開します。
    既に同じ価格が入っているterritoryはスキップするため再実行しても二重登録されません（冪等）。
    ※ inAppPurchasesはbaseTerritory分の初回設定のみ対応（冪等ではないため再実行に注意）

  apply-localizations [config_path] [--env ...]
    subscriptions[].localizations / inAppPurchases[].localizations を localeごとに upsert します。

  apply-screenshots [config_path] [--env ...]
    subscriptions[].reviewScreenshot（configからの相対パス可）をアップロードします。
    アップロード済みのものと内容が同じ（md5一致）なら何もせず、内容が異なる場合や
    アップロードが途中で止まっている場合は既存アセットを削除してアップロードし直します。

  verify [config_path] [--env ...]
    configの全プロダクトについて state / 配信地域数 / 価格設定済み地域数 / ローカライズ /
    審査用スクショの状態を一覧表示します。販売可能でないものがあれば終了コード1を返します。

スクリーンショットアップロード（予約 → バイナリアップロード → コミットの3ステップを自動実行、実機確認済み）:
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

  if [ "$http_status" -lt 200 ] || [ "$http_status" -ge 300 ]; then
    # 呼び出し元が `call ... > /dev/null` するケースでもエラー内容が見えるようstderrに出す
    if [ -n "$response_body" ]; then
      echo "$response_body" | jq . >&2
    fi
    echo "エラー: HTTP ${http_status}" >&2
    exit 1
  fi

  if [ -n "$response_body" ]; then
    echo "$response_body" | jq .
  fi
}

# links.next を辿りながら全ページにjqフィルタを適用して出力する
# 使い方: get_all_pages <path> <jqフィルタ>
#   例: get_all_pages "/v1/territories?limit=200" '.data[].id'
get_all_pages() {
  local path="$1"
  local filter="$2"
  local result next

  while [ -n "$path" ]; do
    generate_jwt
    result=$(curl -sS "${API_HOST}${path}" -H "Authorization: Bearer ${JWT}")
    echo "$result" | jq -r "$filter"
    next=$(echo "$result" | jq -r '.links.next // empty')
    if [ -z "$next" ]; then
      break
    fi
    path="${next#${API_HOST}}"
  done
}

# GETしてHTTPエラー時は空文字を返す（リソース未作成の404を正常系として扱いたい箇所で使う）
# 使い方: get_or_empty <path>
get_or_empty() {
  local path="$1"
  local response http_status

  generate_jwt
  response=$(curl -sS -w '\n%{http_code}' "${API_HOST}${path}" -H "Authorization: Bearer ${JWT}")
  http_status=$(echo "$response" | tail -n1)

  if [ "$http_status" -lt 200 ] || [ "$http_status" -ge 300 ]; then
    return 0
  fi
  echo "$response" | sed '$d'
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

# locale に一致する既存ローカライズのidを検索する（無ければ空文字）
# 使い方: find_localization_id <ローカライズ一覧のパス> <locale>
find_localization_id() {
  local list_path="$1"
  local locale="$2"
  local result

  generate_jwt
  result=$(curl -sS "${API_HOST}${list_path}" -H "Authorization: Bearer ${JWT}")
  echo "$result" | jq -r --arg locale "$locale" '.data[] | select(.attributes.locale == $locale) | .id' | head -n1
}

# apply-* 系コマンドの引数を解釈して CONFIG_PATH / ENV_FILTER にセットする
# 使い方: parse_apply_args [config_path] [--env dev|prd]
parse_apply_args() {
  CONFIG_PATH=""
  ENV_FILTER=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --env)
        ENV_FILTER="$2"
        shift 2
        ;;
      -*)
        echo "エラー: 不明なオプションです: $1" >&2
        exit 1
        ;;
      *)
        CONFIG_PATH="$1"
        shift
        ;;
    esac
  done

  CONFIG_PATH="${CONFIG_PATH:-$(dirname "$0")/appstoreconnect.products.json}"

  if [ ! -f "$CONFIG_PATH" ]; then
    echo "エラー: 設定ファイルが見つかりません: ${CONFIG_PATH}" >&2
    exit 1
  fi

  if [ -n "$ENV_FILTER" ] && [ "$(jq -r --arg env "$ENV_FILTER" '.apps[$env] // empty' "$CONFIG_PATH")" = "" ]; then
    echo "エラー: 設定ファイルの apps に env=${ENV_FILTER} がありません" >&2
    exit 1
  fi
}

# configのトップレベル配列から対象エントリを1行1JSONで出力する
# ENV_FILTER が指定されていれば env が一致するものだけに絞る
# 使い方: select_entries <トップレベルキー名>
select_entries() {
  jq -c --arg key "$1" --arg env "$ENV_FILTER" \
    '.[$key][]? | select($env == "" or .env == $env)' "$CONFIG_PATH"
}

# 設定ファイルからの相対パスを解決する（reviewScreenshot用）
# 使い方: resolve_config_path <path>
resolve_config_path() {
  local path="$1"

  case "$path" in
    /*) echo "$path" ;;
    *) echo "$(cd "$(dirname "$CONFIG_PATH")" && pwd)/${path}" ;;
  esac
}

# 配信対象territoryのIDを1行1件で出力する
# 使い方: resolve_territories <"all" または JSON配列>
resolve_territories() {
  local spec="$1"

  if [ "$spec" = '"all"' ] || [ "$spec" = "all" ]; then
    get_all_pages "/v1/territories?limit=200" '.data[].id' | sort
  else
    echo "$spec" | jq -r '.[]' | sort
  fi
}

# subscriptionLocalizations を upsert する（実機確認済み）
# 使い方: apply_subscription_localization <subscription_id> <locale> <name> <description>
apply_subscription_localization() {
  local subscription_id="$1"
  local locale="$2"
  local name="$3"
  local description="$4"
  local existing_id body

  existing_id=$(find_localization_id "/v1/subscriptions/${subscription_id}/subscriptionLocalizations" "$locale")

  if [ -n "$existing_id" ]; then
    body=$(jq -n --arg id "$existing_id" --arg name "$name" --arg description "$description" \
      '{data:{type:"subscriptionLocalizations",id:$id,attributes:{name:$name,description:$description}}}')
    call PATCH "/v1/subscriptionLocalizations/${existing_id}" "$body" > /dev/null
  else
    body=$(jq -n --arg sub "$subscription_id" --arg locale "$locale" --arg name "$name" --arg description "$description" \
      '{data:{type:"subscriptionLocalizations",attributes:{locale:$locale,name:$name,description:$description},relationships:{subscription:{data:{type:"subscriptions",id:$sub}}}}}')
    call POST /v1/subscriptionLocalizations "$body" > /dev/null
  fi
}

# subscriptionGroupLocalizations を upsert する（実機確認済み）
# サブスクグループ名（App内課金の「サブスクリプショングループの表示名」）は
# 商品側のローカライズとは別リソースで、ここが未設定だと商品の価格・ローカライズを
# 全て埋めても state が MISSING_METADATA のまま販売可能にならない
# 使い方: apply_group_localization <subscription_group_id> <locale> <name> [custom_app_name]
apply_group_localization() {
  local group_id="$1"
  local locale="$2"
  local name="$3"
  local custom_app_name="${4:-}"
  local existing_id body attributes

  existing_id=$(find_localization_id "/v1/subscriptionGroups/${group_id}/subscriptionGroupLocalizations" "$locale")

  attributes=$(jq -n --arg name "$name" --arg custom "$custom_app_name" \
    '{name:$name} + (if $custom == "" then {} else {customAppName:$custom} end)')

  if [ -n "$existing_id" ]; then
    body=$(jq -n --arg id "$existing_id" --argjson attributes "$attributes" \
      '{data:{type:"subscriptionGroupLocalizations",id:$id,attributes:$attributes}}')
    call PATCH "/v1/subscriptionGroupLocalizations/${existing_id}" "$body" > /dev/null
  else
    body=$(jq -n --arg group "$group_id" --arg locale "$locale" --argjson attributes "$attributes" \
      '{data:{type:"subscriptionGroupLocalizations",attributes:($attributes + {locale:$locale}),relationships:{subscriptionGroup:{data:{type:"subscriptionGroups",id:$group}}}}}')
    call POST /v1/subscriptionGroupLocalizations "$body" > /dev/null
  fi
}

# IAPの inAppPurchaseVersions を取得、無ければ作成してidを返す（実機確認済み）
# inAppPurchaseLocalizations は inAppPurchase に直接ぶら下がらず、
# inAppPurchaseVersions 経由の relationships.version が必須（実機確認で判明）
# 使い方: get_or_create_iap_version <in_app_purchase_id>
get_or_create_iap_version() {
  local in_app_purchase_id="$1"
  local existing_id body

  generate_jwt
  existing_id=$(curl -sS "${API_HOST}/v2/inAppPurchases/${in_app_purchase_id}/versions" \
    -H "Authorization: Bearer ${JWT}" | jq -r '.data[0].id // empty')

  if [ -n "$existing_id" ]; then
    echo "$existing_id"
    return 0
  fi

  body=$(jq -n --arg iap "$in_app_purchase_id" \
    '{data:{type:"inAppPurchaseVersions",relationships:{inAppPurchase:{data:{type:"inAppPurchases",id:$iap}}}}}')
  call POST /v1/inAppPurchaseVersions "$body" | jq -r '.data.id'
}

# inAppPurchaseLocalizations を upsert する（実機確認済み）
# 使い方: apply_iap_localization <in_app_purchase_id> <locale> <name> <description>
apply_iap_localization() {
  local in_app_purchase_id="$1"
  local locale="$2"
  local name="$3"
  local description="$4"
  local existing_id version_id body

  existing_id=$(find_localization_id "/v2/inAppPurchases/${in_app_purchase_id}/inAppPurchaseLocalizations" "$locale")

  if [ -n "$existing_id" ]; then
    body=$(jq -n --arg id "$existing_id" --arg name "$name" --arg description "$description" \
      '{data:{type:"inAppPurchaseLocalizations",id:$id,attributes:{name:$name,description:$description}}}')
    call PATCH "/v2/inAppPurchaseLocalizations/${existing_id}" "$body" > /dev/null
  else
    version_id=$(get_or_create_iap_version "$in_app_purchase_id")
    body=$(jq -n --arg version "$version_id" --arg locale "$locale" --arg name "$name" --arg description "$description" \
      '{data:{type:"inAppPurchaseLocalizations",attributes:{locale:$locale,name:$name,description:$description},relationships:{version:{data:{type:"inAppPurchaseVersions",id:$version}}}}}')
    call POST /v2/inAppPurchaseLocalizations "$body" > /dev/null
  fi
}

# appstoreconnect.products.json を読み込んでローカリゼーションを一括反映する
# 使い方: parse_apply_args 済みの状態で apply_localizations
apply_localizations() {
  local sub product_id subscription_id display_name env_name
  local iap in_app_purchase_id
  local loc locale name description

  while read -r sub; do
    product_id=$(echo "$sub" | jq -r '.productId')
    subscription_id=$(echo "$sub" | jq -r '.subscriptionId')
    display_name=$(echo "$sub" | jq -r '.displayName')
    env_name=$(echo "$sub" | jq -r '.env // "-"')

    while read -r loc; do
      [ -z "$loc" ] && continue
      locale=$(echo "$loc" | jq -r '.locale')
      name=$(echo "$loc" | jq -r '.name')
      description=$(echo "$loc" | jq -r '.description')

      echo "[subscriptions localizations] [${env_name}] ${display_name} (${product_id} / ${subscription_id}): ${locale} を設定中..." >&2
      apply_subscription_localization "$subscription_id" "$locale" "$name" "$description"
      echo "[subscriptions localizations] [${env_name}] ${display_name} (${locale}): 完了" >&2
    done < <(echo "$sub" | jq -c '.localizations[]?')
  done < <(select_entries subscriptions)

  while read -r iap; do
    product_id=$(echo "$iap" | jq -r '.productId')
    in_app_purchase_id=$(echo "$iap" | jq -r '.inAppPurchaseId')
    display_name=$(echo "$iap" | jq -r '.displayName')
    env_name=$(echo "$iap" | jq -r '.env // "-"')

    while read -r loc; do
      [ -z "$loc" ] && continue
      locale=$(echo "$loc" | jq -r '.locale')
      name=$(echo "$loc" | jq -r '.name')
      description=$(echo "$loc" | jq -r '.description')

      echo "[inapp localizations] [${env_name}] ${display_name} (${product_id} / ${in_app_purchase_id}): ${locale} を設定中..." >&2
      apply_iap_localization "$in_app_purchase_id" "$locale" "$name" "$description"
      echo "[inapp localizations] [${env_name}] ${display_name} (${locale}): 完了" >&2
    done < <(echo "$iap" | jq -c '.localizations[]?')
  done < <(select_entries inAppPurchases)
}

# configの subscriptionGroups[].localizations を一括反映する
# 使い方: parse_apply_args 済みの状態で apply_group_localizations
apply_group_localizations() {
  local group group_id env_name loc locale name custom_app_name

  while read -r group; do
    group_id=$(echo "$group" | jq -r '.groupId')
    env_name=$(echo "$group" | jq -r '.env // "-"')

    while read -r loc; do
      [ -z "$loc" ] && continue
      locale=$(echo "$loc" | jq -r '.locale')
      name=$(echo "$loc" | jq -r '.name')
      custom_app_name=$(echo "$loc" | jq -r '.customAppName // ""')

      echo "[group localizations] [${env_name}] group=${group_id}: ${locale} \"${name}\" を設定中..." >&2
      apply_group_localization "$group_id" "$locale" "$name" "$custom_app_name"
      echo "[group localizations] [${env_name}] group=${group_id} (${locale}): 完了" >&2
    done < <(echo "$group" | jq -c '.localizations[]?')
  done < <(select_entries subscriptionGroups)
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

# subscriptions screenshot upload <subscription_id> <file_path>（実機確認済み）
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

# subscriptionの現在の価格を "territory<TAB>pricePointId<TAB>customerPrice" 形式で出力する
# territory は include に明示しないと relationships に含まれないため注意（実機確認済み）
# 使い方: list_subscription_prices <subscription_id>
list_subscription_prices() {
  local subscription_id="$1"

  get_all_pages "/v1/subscriptions/${subscription_id}/prices?include=subscriptionPricePoint,territory&limit=200" \
    '. as $page
     | (($page.included // []) | INDEX(.id)) as $points
     | $page.data[]
     | [ .relationships.territory.data.id,
         .relationships.subscriptionPricePoint.data.id,
         ($points[.relationships.subscriptionPricePoint.data.id].attributes.customerPrice // "") ]
     | @tsv'
}

# subscriptionAvailabilities のidを返す（未作成なら空文字）
# 使い方: find_subscription_availability_id <subscription_id>
find_subscription_availability_id() {
  local subscription_id="$1"

  get_or_empty "/v1/subscriptions/${subscription_id}/subscriptionAvailability" | jq -r '.data.id // empty'
}

# subscriptionの配信対象territoryを1行1件で出力する（未作成なら何も出力しない）
# 使い方: list_available_territories <subscription_id>
list_available_territories() {
  local subscription_id="$1"
  local availability_id

  availability_id=$(find_subscription_availability_id "$subscription_id")
  if [ -z "$availability_id" ]; then
    return 0
  fi
  get_all_pages "/v1/subscriptionAvailabilities/${availability_id}/availableTerritories?limit=200" '.data[].id'
}

# subscriptionPrices を1件POSTする
# 使い方: create_subscription_price <subscription_id> <price_point_id> <territory>
create_subscription_price() {
  local body

  body=$(jq -n --arg sub "$1" --arg pp "$2" --arg territory "$3" \
    '{data:{type:"subscriptionPrices",attributes:{preserveCurrentPrice:false},relationships:{
      subscription:{data:{type:"subscriptions",id:$sub}},
      subscriptionPricePoint:{data:{type:"subscriptionPricePoints",id:$pp}},
      territory:{data:{type:"territories",id:$territory}}
    }}}')
  call POST /v1/subscriptionPrices "$body" > /dev/null
}

# 基準price pointと等価な各国のprice pointを "territory<TAB>pricePointId" 形式で出力する（実機確認済み）
# prices と同じく territory は include に明示しないと relationships に含まれない
# 使い方: list_price_point_equalizations <price_point_id>
list_price_point_equalizations() {
  local price_point_id="$1"

  get_all_pages "/v1/subscriptionPricePoints/${price_point_id}/equalizations?include=territory&limit=200" \
    '.data[] | [ .relationships.territory.data.id, .id ] | @tsv'
}

# 基準territoryの価格と等価な価格を、配信対象の全territoryへ展開する
# 使い方: equalize_subscription_prices <subscription_id> <base_price_point_id> <ラベル>
equalize_subscription_prices() {
  local subscription_id="$1"
  local base_price_point_id="$2"
  local label="$3"
  local available existing equalizations territory price_point_id
  local applied=0 skipped=0 out_of_scope=0

  available=$(list_available_territories "$subscription_id")
  if [ -z "$available" ]; then
    echo "エラー: ${label}: 配信地域(subscriptionAvailability)が未作成のため価格を展開できません。先に apply-availability を実行してください" >&2
    exit 1
  fi

  existing=$(list_subscription_prices "$subscription_id" | cut -f1,2)
  equalizations=$(list_price_point_equalizations "$base_price_point_id")

  while IFS=$'\t' read -r territory price_point_id; do
    if [ -z "$territory" ] || [ -z "$price_point_id" ]; then
      echo "エラー: ${label}: equalizations のレスポンスからterritoryを取得できませんでした（include=territory の指定漏れの可能性）" >&2
      exit 1
    fi

    if ! echo "$available" | grep -qx "$territory"; then
      out_of_scope=$((out_of_scope + 1))
      continue
    fi
    if echo "$existing" | grep -qx "${territory}	${price_point_id}"; then
      skipped=$((skipped + 1))
      continue
    fi

    create_subscription_price "$subscription_id" "$price_point_id" "$territory"
    applied=$((applied + 1))
  done < <(echo "$equalizations")

  echo "[subscriptions prices] ${label}: 等価価格の展開 完了（適用 ${applied} / 設定済み ${skipped} / 配信対象外 ${out_of_scope}）" >&2
}

# appstoreconnect.products.json を読み込んで価格を一括反映する
# 既に同じ価格が設定されているterritoryはスキップするため、何度実行しても安全（冪等）
# 使い方: parse_apply_args 済みの状態で apply_prices
apply_prices() {
  local sub product_id subscription_id display_name env_name label
  local existing price territory amount price_point_id
  local equalize_from base_amount base_price_point_id
  local iap in_app_purchase_id base_territory base_price body

  while read -r sub; do
    product_id=$(echo "$sub" | jq -r '.productId')
    subscription_id=$(echo "$sub" | jq -r '.subscriptionId')
    display_name=$(echo "$sub" | jq -r '.displayName')
    env_name=$(echo "$sub" | jq -r '.env // "-"')
    label="[${env_name}] ${display_name} (${product_id} / ${subscription_id})"

    existing=$(list_subscription_prices "$subscription_id")

    while read -r price; do
      [ -z "$price" ] && continue
      territory=$(echo "$price" | jq -r '.territory')
      amount=$(echo "$price" | jq -r '.amount')

      if echo "$existing" | cut -f1,3 | grep -qx "${territory}	${amount}"; then
        echo "[subscriptions prices] ${label}: ${territory} ${amount} は設定済みのためスキップ" >&2
        continue
      fi

      echo "[subscriptions prices] ${label}: ${territory} ${amount} を設定中..." >&2
      price_point_id=$(find_price_point "/v1/subscriptions/${subscription_id}/pricePoints" "$territory" "$amount" | jq -r '.id')
      create_subscription_price "$subscription_id" "$price_point_id" "$territory"
      echo "[subscriptions prices] ${label}: ${territory} 完了" >&2
    done < <(echo "$sub" | jq -c '.prices[]?')

    equalize_from=$(echo "$sub" | jq -r '.equalizeFrom // ""')
    if [ -n "$equalize_from" ]; then
      base_amount=$(echo "$sub" | jq -r --arg t "$equalize_from" '.prices[] | select(.territory == $t) | .amount')
      if [ -z "$base_amount" ]; then
        echo "エラー: ${label}: equalizeFrom(${equalize_from})に対応するpricesの指定がありません" >&2
        exit 1
      fi

      echo "[subscriptions prices] ${label}: ${equalize_from} ${base_amount} を基準に配信対象の全地域へ展開中..." >&2
      base_price_point_id=$(find_price_point "/v1/subscriptions/${subscription_id}/pricePoints" "$equalize_from" "$base_amount" | jq -r '.id')
      equalize_subscription_prices "$subscription_id" "$base_price_point_id" "$label"
    fi
  done < <(select_entries subscriptions)

  while read -r iap; do
    product_id=$(echo "$iap" | jq -r '.productId')
    in_app_purchase_id=$(echo "$iap" | jq -r '.inAppPurchaseId')
    display_name=$(echo "$iap" | jq -r '.displayName')
    env_name=$(echo "$iap" | jq -r '.env // "-"')
    base_territory=$(echo "$iap" | jq -r '.baseTerritory')

    base_price=$(echo "$iap" | jq -c --arg t "$base_territory" '.prices[] | select(.territory == $t)')
    if [ -z "$base_price" ]; then
      echo "エラー: [inapp] ${display_name}: baseTerritory(${base_territory})に対応するpricesの指定がありません" >&2
      continue
    fi

    amount=$(echo "$base_price" | jq -r '.amount')

    echo "[inapp prices] [${env_name}] ${display_name} (${product_id} / ${in_app_purchase_id}): base=${base_territory} ${amount} を設定中..." >&2
    price_point_id=$(find_price_point "/v2/inAppPurchases/${in_app_purchase_id}/pricePoints" "$base_territory" "$amount" | jq -r '.id')

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
    echo "[inapp prices] [${env_name}] ${display_name}: 完了（baseTerritory分のみ。冪等ではないので再実行に注意）" >&2
  done < <(select_entries inAppPurchases)
}

# configの subscriptions[].availability を反映する
# subscriptionAvailabilities はPATCH不可のため、地域を追加する場合も
# 「既存 + 不足分」を全て含めてPOSTし直す
# ※ 新規作成(未作成 → POST)は実機確認済み。既存への地域追加は未検証
# 使い方: parse_apply_args 済みの状態で apply_availability
apply_availability() {
  local sub product_id subscription_id display_name env_name label
  local spec available_in_new desired availability_id existing missing target body

  while read -r sub; do
    spec=$(echo "$sub" | jq -c '.availability // empty')
    if [ -z "$spec" ]; then
      continue
    fi

    product_id=$(echo "$sub" | jq -r '.productId')
    subscription_id=$(echo "$sub" | jq -r '.subscriptionId')
    display_name=$(echo "$sub" | jq -r '.displayName')
    env_name=$(echo "$sub" | jq -r '.env // "-"')
    label="[${env_name}] ${display_name} (${product_id} / ${subscription_id})"

    available_in_new=$(echo "$spec" | jq -r 'if .availableInNewTerritories == false then "false" else "true" end')
    desired=$(resolve_territories "$(echo "$spec" | jq -c '.territories // "all"')")

    availability_id=$(find_subscription_availability_id "$subscription_id")
    if [ -n "$availability_id" ]; then
      existing=$(get_all_pages "/v1/subscriptionAvailabilities/${availability_id}/availableTerritories?limit=200" '.data[].id' | sort)
      missing=$(comm -23 <(echo "$desired") <(echo "$existing"))
      if [ -z "$missing" ]; then
        echo "[availability] ${label}: 設定済み（$(echo "$existing" | grep -c .)地域）のためスキップ" >&2
        continue
      fi
      echo "[availability] ${label}: $(echo "$missing" | grep -c .)地域を追加中（既存 + 不足分を再POST）..." >&2
      target=$(printf '%s\n%s\n' "$existing" "$missing" | grep . | sort -u)
    else
      echo "[availability] ${label}: 配信地域を新規作成中（$(echo "$desired" | grep -c .)地域）..." >&2
      target="$desired"
    fi

    body=$(echo "$target" | jq -R -s -c --arg sub "$subscription_id" --argjson newTerritories "$available_in_new" \
      'split("\n")
       | map(select(length > 0))
       | {data:{type:"subscriptionAvailabilities",
           attributes:{availableInNewTerritories:$newTerritories},
           relationships:{
             subscription:{data:{type:"subscriptions",id:$sub}},
             availableTerritories:{data: map({type:"territories", id:.})}
           }}}')
    call POST /v1/subscriptionAvailabilities "$body" > /dev/null
    echo "[availability] ${label}: 完了" >&2
  done < <(select_entries subscriptions)
}

# configの subscriptions[].reviewScreenshot を反映する
# 既にCOMPLETEならスキップ、アップロード途中(AWAITING_UPLOAD等)で止まっていれば削除して再実行する
# 使い方: parse_apply_args 済みの状態で apply_screenshots
apply_screenshots() {
  local sub product_id subscription_id display_name env_name label
  local path_spec file_path existing screenshot_id state local_checksum

  while read -r sub; do
    path_spec=$(echo "$sub" | jq -r '.reviewScreenshot // ""')
    if [ -z "$path_spec" ]; then
      continue
    fi

    product_id=$(echo "$sub" | jq -r '.productId')
    subscription_id=$(echo "$sub" | jq -r '.subscriptionId')
    display_name=$(echo "$sub" | jq -r '.displayName')
    env_name=$(echo "$sub" | jq -r '.env // "-"')
    label="[${env_name}] ${display_name} (${product_id} / ${subscription_id})"

    existing=$(get_or_empty "/v1/subscriptions/${subscription_id}/appStoreReviewScreenshot")
    screenshot_id=$(echo "$existing" | jq -r '.data.id // empty')
    state=$(echo "$existing" | jq -r '.data.attributes.assetDeliveryState.state // empty')
    file_path=$(resolve_config_path "$path_spec")

    if [ ! -f "$file_path" ]; then
      echo "エラー: ${label}: reviewScreenshot のファイルが存在しません: ${file_path}" >&2
      exit 1
    fi

    # fileNameはApple側で "SOURCE" に正規化されるため同一性判定には使えない。
    # アップロード時に送ったmd5が sourceFileChecksum に保持されるのでそれで比較する（実機確認済み）
    local_checksum=$(md5 -q "$file_path" 2>/dev/null || md5sum "$file_path" | awk '{print $1}')
    if [ "$state" = "COMPLETE" ] && [ "$(echo "$existing" | jq -r '.data.attributes.sourceFileChecksum // ""')" = "$local_checksum" ]; then
      echo "[screenshot] ${label}: 同一ファイルがアップロード済み(COMPLETE)のためスキップ" >&2
      continue
    fi

    if [ -n "$screenshot_id" ]; then
      if [ "$state" = "COMPLETE" ]; then
        echo "[screenshot] ${label}: アップロード済みのファイルと内容が異なるため差し替えます" >&2
      else
        echo "[screenshot] ${label}: 未完了(${state:-unknown})の既存アセットを削除します" >&2
      fi
      call DELETE "/v1/subscriptionAppStoreReviewScreenshots/${screenshot_id}" > /dev/null
    fi

    echo "[screenshot] ${label}: ${file_path} をアップロード中..." >&2
    upload_screenshot "$subscription_id" "$file_path" > /dev/null
    echo "[screenshot] ${label}: 完了" >&2
  done < <(select_entries subscriptions)
}

# configの全プロダクトについてASC側の状態を確認する
# 販売可能でないもの(MISSING_METADATA等)があれば終了コード1を返す
# 使い方: parse_apply_args 済みの状態で verify
verify() {
  local ng=0
  local group group_id env_name locales
  local sub product_id subscription_id display_name label
  local state territory_count price_count screenshot screenshot_state screenshot_source

  while read -r group; do
    group_id=$(echo "$group" | jq -r '.groupId')
    env_name=$(echo "$group" | jq -r '.env // "-"')
    locales=$(get_or_empty "/v1/subscriptionGroups/${group_id}/subscriptionGroupLocalizations" \
      | jq -r '[.data[].attributes.locale] | join(",")')

    if [ -z "$locales" ]; then
      echo "NG   [${env_name}] subscriptionGroup ${group_id}: グループ名のローカライズが未設定（配下の商品が MISSING_METADATA になります）"
      ng=1
    else
      echo "OK   [${env_name}] subscriptionGroup ${group_id}: ローカライズ ${locales}"
    fi
  done < <(select_entries subscriptionGroups)

  while read -r sub; do
    product_id=$(echo "$sub" | jq -r '.productId')
    subscription_id=$(echo "$sub" | jq -r '.subscriptionId')
    display_name=$(echo "$sub" | jq -r '.displayName')
    env_name=$(echo "$sub" | jq -r '.env // "-"')
    label="[${env_name}] ${product_id} (${display_name})"

    state=$(get_or_empty "/v1/subscriptions/${subscription_id}" | jq -r '.data.attributes.state // "UNKNOWN"')
    territory_count=$(list_available_territories "$subscription_id" | grep -c . || true)
    price_count=$(list_subscription_prices "$subscription_id" | cut -f1 | sort -u | grep -c . || true)
    locales=$(get_or_empty "/v1/subscriptions/${subscription_id}/subscriptionLocalizations" \
      | jq -r '[.data[].attributes.locale] | join(",")')
    screenshot=$(get_or_empty "/v1/subscriptions/${subscription_id}/appStoreReviewScreenshot")
    screenshot_state=$(echo "$screenshot" | jq -r '.data.attributes.assetDeliveryState.state // "なし"')
    screenshot_source=$(echo "$sub" | jq -r '.reviewScreenshot // ""')

    case "$state" in
      MISSING_METADATA|DEVELOPER_ACTION_NEEDED|REJECTED|UNKNOWN)
        echo "NG   ${label}: ${state}"
        ng=1
        ;;
      *)
        echo "OK   ${label}: ${state}"
        ;;
    esac
    echo "       配信地域 ${territory_count} / 価格設定済み ${price_count} 地域 / ローカライズ ${locales:-なし} / 審査用スクショ ${screenshot_state}"

    if [ "$territory_count" -gt 0 ] && [ "$price_count" -lt "$territory_count" ]; then
      echo "       警告: 価格が未設定の配信地域が $((territory_count - price_count)) 件あります（apply-prices の equalizeFrom で展開できます）"
    fi
    case "$screenshot_source" in
      *placeholder*)
        echo "       警告: 審査用スクリーンショットがプレースホルダのままです。審査提出前に実際のペイウォール画面に差し替えてください"
        ;;
    esac
  done < <(select_entries subscriptions)

  return "$ng"
}

# ASC側のメタデータをリソースの依存順にまとめて反映し、最後に状態を確認する
# 使い方: parse_apply_args 済みの状態で apply_all
apply_all() {
  echo "=== 1/5 サブスクリプショングループのローカライズ ===" >&2
  apply_group_localizations
  echo "=== 2/5 配信地域 ===" >&2
  apply_availability
  echo "=== 3/5 価格 ===" >&2
  apply_prices
  echo "=== 4/5 商品のローカライズ ===" >&2
  apply_localizations
  echo "=== 5/5 審査用スクリーンショット ===" >&2
  apply_screenshots
  echo "=== 反映結果の確認 ===" >&2
  verify
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
          case "$1" in
            list)
              call GET "/v1/subscriptions/$2/subscriptionLocalizations"
              ;;
            set)
              # subscriptions localizations set <subscription_id> <locale> <name> <description>  (実機確認済み)
              apply_subscription_localization "$2" "$3" "$4" "$5"
              ;;
            *)
              usage
              exit 1
              ;;
          esac
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
          case "$1" in
            list)
              call GET "/v2/inAppPurchases/$2/inAppPurchaseLocalizations"
              ;;
            set)
              # inapp localizations set <in_app_purchase_id> <locale> <name> <description>  (実機確認済み)
              apply_iap_localization "$2" "$3" "$4" "$5"
              ;;
            *)
              usage
              exit 1
              ;;
          esac
          ;;
        *)
          usage
          exit 1
          ;;
      esac
      ;;

    apply-prices)
      parse_apply_args "$@"
      apply_prices
      ;;

    apply-localizations)
      parse_apply_args "$@"
      apply_localizations
      ;;

    apply-group-localizations)
      parse_apply_args "$@"
      apply_group_localizations
      ;;

    apply-availability)
      parse_apply_args "$@"
      apply_availability
      ;;

    apply-screenshots)
      parse_apply_args "$@"
      apply_screenshots
      ;;

    apply-all)
      parse_apply_args "$@"
      apply_all
      ;;

    verify)
      parse_apply_args "$@"
      verify
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
