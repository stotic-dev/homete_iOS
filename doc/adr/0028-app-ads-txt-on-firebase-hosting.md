## タイトル: app-ads.txt をFirebase Hostingのルートで配信する

* **承認済**
* 意思決定者: stotic-dev
* 日付: 2026-09-30
* 技術的背景: [#325](https://github.com/stotic-dev/homete_iOS/issues/325)

## 文脈、背景や問題点の説明

AdMobの広告在庫を認証済みとして扱ってもらうには、IAB Tech Labの app-ads.txt を「アプリストア掲載情報に書いたデベロッパーのウェブサイトのドメインのルート直下」に置く必要がある。未設置のままだと認証されていない在庫として扱われ、入札に参加しないバイヤーが出て広告収益が目減りする。

homeauが公開しているWebは2つあり、どちらをデベロッパーのウェブサイトにするかで置き場所が変わる。加えてApp Store側のマーケティングURLは空だったため、そのままではクローラーがドメインを特定できない状態だった。

## 決定事項

* app-ads.txt は `firebase/hosting/public/app-ads.txt` に置き、Firebase Hostingのデフォルトドメインのルートで配信する
  * 本番: `https://homete-ios-dev.web.app/app-ads.txt`
  * STG: `https://homete-ios-dev-e3ef7.web.app/app-ads.txt`（dev/prodで同じ `public` を配信しているため両方に出る。STG側はどこからも参照されないが無害なので分岐はしない）
* App Storeのマーケティングリンク（`fastlane/metadata/ja/marketing_url.txt`）に本番Hostingのルート `https://homete-ios-dev.web.app/` を設定する
* これまで404だったHostingのルートに、アプリ紹介ページ `firebase/hosting/public/index.html` を新設する
* パブリッシャーIDはAdMobコンソールが生成する行をそのまま書く。app-ads.txt は公開前提のファイルなので、`Secret.xcconfig` のようなgitignore扱いにはせずリポジトリにコミットする

## 考慮した選択肢

* **選択肢1: Firebase Hostingのルート（採用）**
  リポジトリに `firebase/hosting/` とデプロイワークフロー（`deploy-hosting.yml`）が既にあり、AASA・招待リンクの着地ページを配信している。`web.app` はPublic Suffix Listに載っているため `homete-ios-dev.web.app` 自体がルートドメインとして扱われ、`/app-ads.txt` がそのまま要件を満たす。
* **選択肢2: 既存のGitHub Pages（`https://stotic-dev.github.io/homete_iOS/`）**
  利用規約・プライバシーポリシーを配信しているが、プロジェクトサイトなのでサブディレクトリ配下にしか置けない。`github.io` もPublic Suffixなのでルートは `stotic-dev.github.io` になり、app-ads.txt を置くには別途 `stotic-dev.github.io` リポジトリ（ユーザーサイト）を作る必要がある。homete_iOSリポジトリの外に管理対象が増える。
* **選択肢3: 独自ドメインを取得してHostingにカスタムドメインを紐付ける**
  マーケティングURLとしての見栄えは最も良いが、ドメイン取得費用とDNS設定・更新管理が新たに発生する。広告認証のためだけに導入するには重い。

## 決定結果

### 決定にあたり考慮したメリット

* 配信基盤・デプロイ導線・レビューフローが既存のものをそのまま使えるので、追加で運用するものが増えない
* app-ads.txt がアプリのリポジトリ内でバージョン管理され、変更がPRのレビュー対象になる
* ルートに紹介ページができたことで、App Storeのデベロッパーサイトリンクがユーザーにとっても意味のある着地点になった

### 決定にあたり考慮したデメリット

* マーケティングURLが `homete-ios-dev.web.app` になる。プロジェクトIDの命名上、本番なのにホスト名が開発環境のように見える（[ADR-0014](0014-firebase-multi-project-deploy.md) と同じ紛らわしさを引きずる）
* 独自ドメインに移行する場合、app-ads.txt とマーケティングURLを移し替えたうえでAdMobの再クロールを待つ必要がある
* 反映経路が2つに分かれる。Hostingは `deploy-hosting.yml` の `environment=prod` 手動実行、マーケティングURLは `sync-metadata.yml` の手動実行で、どちらも忘れるとクローラーに届かない

## 参考

* [app-ads.txt でアプリの広告枠を宣言する（AdMob ヘルプ）](https://support.google.com/admob/answer/9363762?hl=ja)
* [doc/app_ads_txt.md](../app_ads_txt.md) — 設置・更新の手順
* [ADR-0014](0014-firebase-multi-project-deploy.md) — Firebaseプロジェクトとエイリアスの対応
