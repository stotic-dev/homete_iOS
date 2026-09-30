# app-ads.txt の設置・更新手順

> 配信先にFirebase Hostingを選んだ背景は [ADR-0028](adr/0028-app-ads-txt-on-firebase-hosting.md) を参照。

AdMobの広告在庫を「認証済み」として扱ってもらうためのファイル。未設置だと認証されていない在庫と見なされ、入札に参加しないバイヤーが出る。

## 構成

| 項目 | 値 |
|---|---|
| ファイル | `firebase/hosting/public/app-ads.txt` |
| 本番の公開URL | https://homete-ios-dev.web.app/app-ads.txt |
| STGの公開URL | https://homete-ios-dev-e3ef7.web.app/app-ads.txt |
| デベロッパーのウェブサイト | `fastlane/metadata/ja/marketing_url.txt`（= `https://homete-ios-dev.web.app/`） |

クローラーはApp Store掲載情報のマーケティングリンクからドメインを特定し、**そのドメインのルート直下**の `/app-ads.txt` だけを見る。サブディレクトリに置いても読まれないので、`docs/`（GitHub Pages）側には置かない。

dev / prod で同じ `public` を配信しているためSTGにも同じ内容が出るが、STGのホストはどのストア掲載情報からも参照されないので実害はない。

## 内容を更新するとき

AdMobコンソールの **［アプリ］→［app-ads.txt］** に表示される行をそのままコピーして貼り替える。手で組み立てない（サードパーティのアドソースを有効にすると `RESELLER` 行が増えるため、コンソールの表示が正）。

行の形式は `<アドエクスチェンジのドメイン>, <パブリッシャーID>, <関係タイプ>, <認証機関ID>` で、`#` 以降はコメント。

## 反映手順

ファイルを更新したら、以下を**両方**実行する。片方だけではクローラーに届かない。

1. **Hostingのデプロイ**
   - STG: `firebase/hosting/**` の変更がmainにマージされた時点で `deploy-hosting.yml` が自動実行される
   - 本番: `deploy-hosting.yml` を `workflow_dispatch` で `environment=prod` を選んで手動実行する
2. **マーケティングリンクの同期**（`marketing_url.txt` を変えた場合のみ）
   - `sync-metadata.yml` を `workflow_dispatch` で対象バージョンを指定して手動実行する
   - App Store Connect側の反映には最大24時間かかる

反映後、AdMobコンソールの **［アプリ］→［app-ads.txt］** で「アップデートを確認」をリクエストする。クロールと検証には最大24時間かかる。

## 確認

```bash
# 200 で text/plain が返り、AdMobコンソールと同じ行が入っていること
curl -i https://homete-ios-dev.web.app/app-ads.txt
```

`Content-Type: text/plain` はFirebase Hostingが拡張子から自動で付けるため、`firebase.json` にヘッダ設定は書いていない。
