## タイトル: イメージキャラクター「ほめっと」を導入し、色・形・言葉をやさしい方向に作り直す

* **ステータス**: 承認済
* 意思決定者: stotic-dev
* 日付: 2026-10-10
* 関連: [#403](https://github.com/stotic-dev/homete_iOS/issues/403)、[ADR-0019](0019-foreground-color-roles.md)（前景と面のカラーロール。色トークンの名前は本ADRで置き換える）

## 文脈、背景や問題点の説明

homeauは「ほめる」から名付けたアプリで、ストアのサブタイトルも「家事をがんばったら、ほめてもらおう」である。
それなのに今の画面は業務アプリのように見え、toC向けのやわらかさや「ほめてくれる」気配がない。原因は次の4つ。

| 観点 | 現状 |
|---|---|
| 色 | アイコンはクリーム地に茶色のロゼットなのに、画面はネオン寄りの緑（`primary1 #47EB7D`）と白。文字はほぼ黒（`onSurface #0D1C0D`）で硬い |
| 形 | 角丸は8・16の2段階だけ。見出しは`.heavy`で詰まって強く見える。空状態の点線枠が入力欄に見える |
| 絵 | リアルな人物イラストとSF Symbolsが混在し、homeauらしい絵がない。「ほめる」場面に絵がない |
| 言葉 | 見出しが漢語の連結（「今日の家事サマリー」「頑張り度」）で、本文は「〜しましょう！」の指示口調 |

また、色トークンの名前（`primary1`〜`3`、`surface`など）は番号や面の階層で付けられていて、役割が読み取れない。
ADR-0019で前景と面を分けたが、`primary2`が`PointLabel`の地と`HouseworkDateCell`の枠線の両方に使われるなど、名前から用途を判断できない状態が残っている。

## 決定事項

### キャラクター

* イメージキャラクターを「ほめっと」とする。アプリアイコンのロゼット（表彰リボン）に顔がつき、頭に若葉が1枚ある子。名前は「ほめる」＋「ロゼット」
  * アイコンを作り直さずに済み、キャラ自体が「ごほうび」なので、完了やポイントの演出と意味がつながる
* イラストはClaudeが制作する（外部に依頼しない）。素材は`doc/design/renewal/character/`に置き、`generate_homette.py`から生成する
  * 表情・ポーズは9種（`homette_normal` / `praise` / `thanks` / `rest` / `cheer` / `puzzled` / `wave` / `holdHeart` / `point`）
  * アプリには`heic/`のHEICを@2x / @3xで`Image.xcassets`に入れる（Preserve Vector Data無効、Individual Scales、Compressionは既定）。ほめっとは決まった大きさで表示して拡大しないため、ベクターで入れてもビルド時にビットマップが生成されて大きくなるだけになる（理由の詳細は素材のREADME）
* イラストの色はセマンティックトークンに含めず、素材に焼き込む。ライト・ダークで同じ色を使う（値は素材のREADME）
* 出す場所と出さない場所を分ける
  * 出す: 空状態、家事の完了、ありがとうの受信・送信、ログイン、オンボーディング、パートナー登録の完了、ローンチ画面
  * 出さない: 課金、退会・ログアウト・削除の確認、法務画面、家事一覧の行ごと
* ほめっとの決まりごと
  * 人を比べない。ランキングの順位にはコメントしない
  * サボりを責めない、急かさない
  * 家事をしたのは人。ほめっとは見ていて、喜ぶ役

### 色

* 主役の色は緑のまま維持し、トーンだけ落ち着かせる。画面の地はアイコンのクリーム色に寄せる
* ポイント・ごほうびには「はちみつ」、ありがとうには「もも」を割り当て、意味で色を使い分ける
* パレット（色の名前と値）は本ADRにだけ置き、コードには出さない

  | パレット | 色味 | 主な値（ライト） |
  |---|---|---|
  | ミルク | アイコンに寄せたクリーム寄りの白 | `#FBF8F2` |
  | 墨 | 緑みのある墨 | `#263328` / `#66736A` |
  | 若葉 | 主役の緑 | `#2A8454` / `#1F6B44` / `#E3F3E8` |
  | はちみつ | ポイント・ごほうび | `#F2B035` / `#FFF1D2` / `#8A5A00` |
  | もも | ありがとう | `#EC7290` / `#FDE7EC` / `#B23A5A` |
  | 赤 | エラー・削除 | `#C04848` |

* 色トークンはセマンティックな名前にする。名前の形は「種類（`background` / `text` / `fill` / `icon` / `overlay`）＋役割」
  * 既存のトークンはすべて新しい名前に移し、古いトークンは消す

  | トークン | 役割 | ライト | ダーク | 置き換える既存 |
  |---|---|---|---|---|
  | `backgroundScreen` | 画面の地 | `#FBF8F2` | `#161A17` | `surface` `groupedBackground` |
  | `backgroundCard` | カード・シート | `#FFFFFF` | `#222823` | `subSurface` |
  | `textPrimary` | 本文 | `#263328` | `#EEF2EC` | `onSurface` `onSubSurface` |
  | `textSecondary` | 補助文字 | `#66736A` | `#A9B5AC` | `onSurfaceVariant` `onPrimary3` |
  | `textAccent` | 強調の文字・リンク（地の上で6.1:1） | `#1F6B44` | `#6CCF97` | `accent`（文字の用途） |
  | `textOnAccent` | `fillAccent`の上の文字 | `#FFFFFF` | `#10261A` | `onPrimary1` `onPrimary2` |
  | `fillAccent` | 主ボタン・完了チェック・tint・選択中（白文字で4.6:1） | `#2A8454` | `#6CCF97` | `primary1`、`accent`（文字以外の用途） |
  | `fillAccentSubtle` | 副ボタン・未選択のチップ・選択可の日付 | `#E3F3E8` | `#23392B` | `primary3` |
  | `fillReward` | ポイント・達成のバーや装飾 | `#F2B035` | `#F4C15F` | なし（新規） |
  | `fillRewardSubtle` | ポイントのチップの地 | `#FFF1D2` | `#3A3120` | `primary2`（`PointLabel`） |
  | `textReward` | ポイントのチップの文字 | `#8A5A00` | `#F4C15F` | `onPrimary2`（`PointLabel`） |
  | `fillThanks` | ハート | `#EC7290` | `#F49BB0` | `thanksHeart` |
  | `fillThanksSubtle` | ありがとうボタンの地 | `#FDE7EC` | `#3D2A2F` | なし（新規） |
  | `textThanks` | ありがとうボタンの文字 | `#B23A5A` | `#F49BB0` | なし（新規） |
  | `fillDestructive` | 削除ボタンの地・エラーの枠線やアイコン | `#C04848` | `#E07A7A` | `alert` `destructive`（文字以外の用途） |
  | `textDestructive` | エラーメッセージ・文字数オーバー・削除の文字（地の上で4.65:1、ダークは6.1:1） | `#C04848` | `#E07A7A` | `alert` `destructive`（文字の用途） |
  | `textOnDestructive` | 削除ボタンの文字 | `#FFFFFF` | `#2A0F0F` | `onDestructive` |
  | `iconDecorative` | 大きな装飾アイコン、オンボーディングの未到達ドット | `#4E8A63` | `#8CC9A3` | `decorativeIcon` |
  | `overlayLoading` | ローディングの膜 | 白30% | 白30% | `loadingBg` |

* 命名のルール
  * `primary` / `secondary`は単独では使わない。SwiftUIの`Color.primary` / `.secondary`とぶつかるため、`textPrimary`のように種類を前に付ける
  * 既存の`surface`などの名前は再利用しない。名前を全部変えれば、移し忘れがビルドエラーで見つかる
  * トークン同士で値が重なってもよい（例: ダークの`textAccent`と`fillAccent`）。asset catalogは別名を参照できないので、値の出どころはパレット表で追う
* 今の色で状態を見分けている箇所は、まとめると見分けがつかなくなるため個別に割り当てる
  * `HouseworkDateCell`: 選択中＝`fillAccent`＋`textOnAccent`、選択可＝`fillAccentSubtle`＋`textPrimary`、選択不可＝`backgroundScreen`＋`textSecondary`。選択中の枠線はなくす
  * `PointLabel`: `fillRewardSubtle`＋`textReward`
  * `WeekdayLabel` / `FrequentHouseworkChip` / `FrequentHouseworkPicker`: 選択中＝`fillAccent`＋`textOnAccent`、未選択＝`fillAccentSubtle`＋`textPrimary`
* アプリの`AccentColor`（`homete/Assets.xcassets`）を`fillAccent`と同じ値にする。コードでは`Color.accentColor`を使わず`fillAccent`を使う（VRTのホストアプリには`AccentColor`がなく、スナップショットだけ青になるため）
* ADR-0019の原則（面の色を前景に使わない、透過で弱さを表現しない、文字はAA以上）は引き継ぐ。`fill*`が面、`text*` / `icon*`が前景にあたる

### 形

* 角丸は`radius8`→`radius12`、`radius16`→`radius20`に置き換える
  * `radius12`: バナー・チップ・入力欄
  * `radius20`: カード・ボタン
  * `radius28`は今は作らない。シートや大きいカードで必要になったときに足す
* ボタンはすべてカプセル型で、高さ48pt以上。主ボタンには下に少し厚みを付け、押すと沈むようにする
* ボタンのバリエーションはprimary / subPrimary / thanks / ghost / destructive
* 点線枠と区切り線はやめ、余白とカードで区切る
* SF Symbolsは続投する。`.fill`版に統一し、`fillAccentSubtle`の丸い台座に載せる
* 完了時の弾むアニメーションと「+pt」の演出は、視差効果を減らす設定では止める

### 文字

* フォントはOS標準（SF Pro・ヒラギノ）のまま変えない。丸ゴシックの同梱やSF Rounded（`.fontDesign(.rounded)`）は使わない。やわらかさは色・角丸・キャラクター・言葉で出す
* `headLineL` / `headLineM`はheavyからboldにする。ポイント・件数用に`number`（`.title2` bold + `monospacedDigit()`）を足す

### ライティング

* `.claude/rules/ux-writing.md`（敬体・結果ベース・漢語の連結を避ける）を土台に、見出し・ラベル・キャラのセリフまで広げる
  * ねぎらう: 完了したら必ず一言ねぎらう
  * 押しつけない: 「〜しましょう！」をやめ、「〜すると、〜できます」と結果を伝える。感嘆符は1画面に1つまで
  * ふつうの言葉: サマリー・貢献度・頑張り度のような言葉を見出しに使わない
  * アプリとキャラを分ける: アプリの文言は敬体。くだけた口調はほめっとの吹き出しの中だけ
* ストアの文言も同じ方針で書き換える（案は`doc/design/renewal/store_copy.md`）

### 進め方

* VRTスナップショットが多いため、色・角丸・文字・ボタンとカード・文言・キャラの配置・ストアの順にPRを分け、差分を確認しながら進める（段取りは#403）

## 考慮した選択肢

* キャラクター
  * ほめっと（採用）
  * おうちさん（家そのものが住人を見守る）: 家のモチーフは家事アプリで多く埋もれやすく、「ほめる」とのつながりが弱い
  * ことりん（ありがとうを運ぶ鳥）: アイコンと関係がなく、アイコンの作り直しが必要
* イラストの制作
  * Claudeが制作する（採用）: 生成スクリプトで形と色を管理でき、表情の追加や色の調整をリポジトリの中で続けられる
  * 外部のイラストレーターに依頼する: 費用と、追加・修正のたびのやり取りが発生する
* 主役の色
  * 緑を維持してトーンを落ち着かせる（採用）
  * アイコンに寄せた「はちみつ色」にする: 既存ユーザーの見慣れた印象が大きく変わる。はちみつはポイントの意味に割り当てる
* 色トークンの名前
  * 「種類＋役割」のセマンティックな名前（採用）
  * 既存の名前（`primary1`など）を残して値だけ変える: 中身が同じなのに名前が違うトークンが残る。番号だけでは役割が読み取れない
  * 色の名前（`milk` / `leaf` / `honey`など）: 色を変えると名前が嘘になり、呼び出し側の書き換えが再び必要になる。役割から選べず、使い分けの注意書きが要る
* キャラクター素材の形式
  * HEIC（@2x / @3x、Individual Scales）（採用）
  * PDF・SVG（Preserve Vector Data、Single Scale）: ビルド時に1x〜3xのビットマップが生成されてAssets.carに入るため、元ファイルが小さくてもアプリは大きくなる。拡大しない絵ではベクターの利点もない
  * PNG（@2x / @3x）: HEICよりApp Thinning後のサイズが大きい
* フォント
  * OS標準のまま（採用）
  * 日本語の丸ゴシック（Zen Maru Gothic）を同梱する: アプリサイズが増え、Dynamic Typeや字形の調整を自前で持つことになる
  * SF Rounded: 欧文と数字だけが丸くなり、和文のヒラギノと混ざって不揃いになる

## 決定結果

### 決定にあたり考慮したメリット

* アイコンと画面の印象がそろい、「ほめてくれる」アプリであることが絵と言葉で伝わる
* 色を変えるときは`Colors.xcassets`の値を変えるだけで済み、トークンの名前と呼び出し側は変えずに済む
* トークンの名前から用途が読めるので、新しい画面で色を選ぶときに迷いにくい。`PointLabel`の地と日付の枠線のように、1つのトークンが別の役割を兼ねることがなくなる
* フォントを変えないので、Dynamic Typeやアプリサイズへの影響がない

### 決定にあたり考慮したデメリット

* ほぼ全画面の見た目が変わり、VRTの参照スナップショットの再記録と目視の確認が段階ごとに必要になる
* 既存トークンをすべて改名するため、色のPRの変更箇所が多い
* asset catalogは別名を参照できないので、同じ値を複数のトークンに書く。パレットの値を変えるときは、そのパレットを使うトークンを表から探して全部直す必要がある
* イラストは生成スクリプトが正なので、SVGを手で直すと次の生成で消える。修正は必ずスクリプトで行う

## 参考

* 素材と提案書: `doc/design/renewal/`（`proposal.html`のトークン名は色名で命名していた時点のもの。名前は本ADRが正）
* 素材の生成手順とアプリに入れる形式: [`doc/design/renewal/character/README.md`](../design/renewal/character/README.md)
* 上ちょ「今どきの画像アセット入稿：たった1枚の画像でアプリサイズが50MB増えた失敗から学ぶ最適化方法」（iOSDC Japan 2026 パンフレット）
* WCAG 2.2 — 1.4.3 Contrast (Minimum) / 1.4.11 Non-text Contrast
