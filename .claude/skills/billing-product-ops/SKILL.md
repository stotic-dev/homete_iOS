---
name: billing-product-ops
description: App Store Connect API（scripts/appstoreconnect.sh）とRevenueCat REST API v2（scripts/revenuecat.sh）を使って、サブスクリプション/App内課金の価格・ローカライズ・審査用スクリーンショット・RevenueCat側のProducts/Entitlements/Offerings設定を操作するスキル。課金プロダクトの追加・価格変更・メタデータ同期を行うときに使う。
---

# 課金プロダクト運用スキル（App Store Connect / RevenueCat）

## 対象タイミング

- App Store Connect側でサブスクリプション/App内課金の価格・ローカライズ（名前・説明文）・審査用スクリーンショットを設定/変更するとき
- RevenueCat側でProducts / Entitlements / Offeringsを作成・更新するとき
- 新しい課金プロダクトを追加し、ASCとRevenueCatの両方に反映する（メタデータ同期する）とき

対象スクリプト:
- `scripts/appstoreconnect.sh` — App Store Connect API
- `scripts/revenuecat.sh` — RevenueCat REST API v2

両スクリプトとも `set -e` で書かれており、`curl` + `jq` に依存する（`appstoreconnect.sh` はJWT署名生成のため `openssl` / `python3` も必要）。

---

## 0. 事前準備（認証情報のセットアップ）

両スクリプトとも実際の認証情報は `scripts/*.env`（gitignore対象、絶対にコミットしない）に置き、`source` してから使う。

```bash
# 初回のみ: テンプレートをコピーして値を埋める
cp scripts/appstoreconnect.env.example scripts/appstoreconnect.env
cp scripts/revenuecat.env.example scripts/revenuecat.env
# エディタで scripts/appstoreconnect.env / scripts/revenuecat.env に実際の値を設定

# 使う直前に読み込む
source scripts/appstoreconnect.env
source scripts/revenuecat.env
```

**worktree運用の慣習:** 実値入りの `.env` ファイルはメインリポジトリ（`/Users/taichisato/work/homete_iOS/scripts/`）にも保管してある。新しいworktreeを作る際はそこから `cp -p` でコピーすればよい（再発行不要）。

```bash
cp -p /Users/taichisato/work/homete_iOS/scripts/appstoreconnect.env scripts/appstoreconnect.env
cp -p /Users/taichisato/work/homete_iOS/scripts/revenuecat.env scripts/revenuecat.env
```

必要な環境変数:
- `appstoreconnect.env`: `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_API_KEY_PATH`（.p8秘密鍵へのパス。fastlane/Fastfileと同名の変数）
- `revenuecat.env`: `REVENUECAT_SECRET_API_KEY`（`sk_`始まり） / `REVENUECAT_PROJECT_ID`

---

## 1. App Store Connect（scripts/appstoreconnect.sh）

### 1-1. 実機確認済みの範囲

スクリプト冒頭コメントに明記されている通り:
- `call` サブコマンド、`subscriptions get/prices/localizations` 系のGET、価格/ローカリゼーション作成、スクリーンショットアップロードは実機確認済み
- `inapp price set-base` は初回のPrice Schedule作成のみ確認済み（既存Schedule更新は未検証）
- それ以外は未検証箇所としてコマンド近くのコメントに明記されているので、実行前に該当箇所のコメントを確認する

### 1-2. 個別コマンド

```bash
# サブスクリプション情報取得
scripts/appstoreconnect.sh subscriptions get <subscription_id>
scripts/appstoreconnect.sh subscriptions availability get <subscription_id>

# 価格
scripts/appstoreconnect.sh subscriptions prices list <subscription_id>
scripts/appstoreconnect.sh subscriptions price-points find <subscription_id> <territory> <amount>
scripts/appstoreconnect.sh subscriptions prices set <subscription_id> <price_point_id> <territory>

# ローカライズ（無ければPOST、あればPATCHのupsert）
scripts/appstoreconnect.sh subscriptions localizations list <subscription_id>
scripts/appstoreconnect.sh subscriptions localizations set <subscription_id> <locale> <name> <description>

# 買い切り商品（App内課金, v2 API）
scripts/appstoreconnect.sh inapp get <in_app_purchase_id>
scripts/appstoreconnect.sh inapp price-points find <in_app_purchase_id> <territory> <amount>
scripts/appstoreconnect.sh inapp price set-base <in_app_purchase_id> <price_point_id> <territory>   # 初回のみ確認済み
scripts/appstoreconnect.sh inapp localizations set <in_app_purchase_id> <locale> <name> <description>

# 審査用スクリーンショット（予約→アップロード→コミットを自動実行）
scripts/appstoreconnect.sh subscriptions screenshot upload <subscription_id> <file_path>
```

価格を「金額から」設定する典型パターン（price-points find でIDを引いてから prices set / price set-base に渡す）:

```bash
price_point=$(scripts/appstoreconnect.sh subscriptions price-points find 6794541936 JPN 450 | jq -r .id)
scripts/appstoreconnect.sh subscriptions prices set 6794541936 "$price_point" JPN
```

### 1-3. 設定ファイルによる一括反映（`apply-prices` / `apply-localizations`）

`scripts/appstoreconnect.products.json` にサブスク/App内課金の `productId` / `subscriptionId` (or `inAppPurchaseId`) / `prices` / `localizations` を一元管理しておき、以下のコマンドで一括反映できる。**プロダクトのメタデータ（価格・名前・説明文）を変更するときは、個別コマンドを都度叩くよりまずこのJSONを更新して一括反映するのが基本フロー。**

```bash
# デフォルトで scripts/appstoreconnect.products.json を読む
scripts/appstoreconnect.sh apply-prices
scripts/appstoreconnect.sh apply-localizations

# 別ファイルを指定する場合
scripts/appstoreconnect.sh apply-prices path/to/other.json
```

`appstoreconnect.products.json` の構造（実例）:

```json
{
  "appId": "6759321417",
  "subscriptionGroupId": "22263200",
  "subscriptions": [
    {
      "productId": "monthly",
      "subscriptionId": "6794541936",
      "displayName": "プレミアムプラン（1ヶ月更新）",
      "prices": [{ "territory": "JPN", "amount": "450" }],
      "localizations": [
        { "locale": "ja", "name": "プレミアムプラン", "description": "..." }
      ]
    }
  ],
  "inAppPurchases": [
    {
      "productId": "onetime_yearly",
      "inAppPurchaseId": "6794541732",
      "displayName": "プレミアムプラン（1年間）",
      "baseTerritory": "JPN",
      "prices": [{ "territory": "JPN", "amount": "3600" }],
      "localizations": [
        { "locale": "ja", "name": "...", "description": "..." }
      ]
    }
  ]
}
```

注意:
- `apply-prices` の `inAppPurchases` は `baseTerritory` 分の初回設定のみ対応（複数territory・Schedule更新後の反映は未対応）
- 新しいsubscription/inAppPurchaseを追加する場合、事前にApp Store Connect側でリソース自体（productId等）を作成し、そのIDをこのJSONに追記してから反映コマンドを叩く

### 1-4. 汎用 `call` コマンド

便利コマンドがカバーしていないエンドポイントは `call` で直接叩ける（公式ドキュメントのリクエストボディをそのまま渡せる）。

```bash
scripts/appstoreconnect.sh call GET /v1/subscriptions/6794541936
scripts/appstoreconnect.sh call GET /v1/subscriptions/6794541936/subscriptionAvailability
scripts/appstoreconnect.sh call PATCH /v1/subscriptionLocalizations/{localization_id} \
  --data '{"data":{"type":"subscriptionLocalizations","id":"{localization_id}","attributes":{"name":"...","description":"..."}}}'
```

Subscription系は `/v1`、InAppPurchase系は `/v2` を使う。配信可否(availability)は `subscriptions` の属性ではなく `/v1/subscriptions/{id}/subscriptionAvailability` という別リソース。

---

## 2. RevenueCat（scripts/revenuecat.sh）

Products / Entitlements / Offerings をREST API v2で操作する。ASCと違い一括反映用の設定ファイルは無いので、`products.json` の内容を見ながら個別コマンドを組み立てる。

```bash
# Products
scripts/revenuecat.sh products list
scripts/revenuecat.sh products create --data '<json>'
scripts/revenuecat.sh products update <product_id> --data '<json>'

# Entitlements
scripts/revenuecat.sh entitlements list
scripts/revenuecat.sh entitlements create --data '<json>'
scripts/revenuecat.sh entitlements update <entitlement_id> --data '<json>'
scripts/revenuecat.sh entitlements list-products <entitlement_id>
scripts/revenuecat.sh entitlements attach-products <entitlement_id> --data '<json>'
scripts/revenuecat.sh entitlements detach-products <entitlement_id> --data '<json>'

# Offerings
scripts/revenuecat.sh offerings list
scripts/revenuecat.sh offerings create --data '<json>'
scripts/revenuecat.sh offerings update <offering_id> --data '<json>'
scripts/revenuecat.sh offerings update-metadata <offering_id> --data '<json (metadataオブジェクト本体)>'
scripts/revenuecat.sh offerings list-packages <offering_id>
scripts/revenuecat.sh offerings create-package <offering_id> --data '<json>'
scripts/revenuecat.sh offerings update-package <offering_id> <package_id> --data '<json>'
scripts/revenuecat.sh offerings attach-products <offering_id> <package_id> --data '<json>'
scripts/revenuecat.sh offerings detach-products <offering_id> <package_id> --data '<json>'
```

`--data '<json>'` の代わりに `--data-file <path>` でファイルから読み込むことも可能（両方とも共通のオプション）。

例（Offeringのpaywallメタデータ更新）:

```bash
scripts/revenuecat.sh offerings update-metadata proj_offering_id \
  --data '{"paywall_title_copy": "Unlock all benefits"}'
```

---

## 3. 典型ワークフロー: 新しい課金プロダクトの追加・同期

1. App Store Connect側でSubscription/In-App Purchaseのリソース自体を作成（Web UIまたは`call`）し、`subscriptionId` / `inAppPurchaseId` を控える
2. `scripts/appstoreconnect.products.json` に `productId` / 対応するASC ID / `prices` / `localizations` を追記
3. `scripts/appstoreconnect.sh apply-prices` と `apply-localizations` で価格・ローカライズを一括反映
4. 審査用スクリーンショットが必要なら `subscriptions screenshot upload` で個別アップロード
5. RevenueCat側で `products create` して同じ `productId`（App Store側のIDと一致させる）を登録
6. 必要なEntitlementに `entitlements attach-products` で紐付け
7. Offeringのpackageに `offerings attach-products` で紐付け、必要なら `offerings update-metadata` でpaywall用メタデータを設定
8. `products list` / `offerings list-packages` 等で反映結果を確認

---

## 4. エラー発生時の対応

- HTTPエラー時はレスポンスのJSON:APIエラーメッセージ（stderrに出力される）を確認し、[App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi) / [RevenueCat API v2](https://www.revenuecat.com/docs/api-v2) のドキュメントと照合する
- `appstoreconnect.sh` で「実機確認済み」と明記されていないコマンドを使う場合は、レスポンスの構造が想定と異なる可能性があるため結果を必ず確認してから次の操作に進む
- `scripts/*.env` に実値を書いた後、`git status` で誤ってステージされていないか確認する習慣を付ける（`.gitignore`で除外済みだが、念のため）
