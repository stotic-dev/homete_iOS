---
name: image-asset-import
description: 画像（イラスト・写真・アイコン・キャラクターなど）を`Image.xcassets`に追加・差し替えるときに、アプリサイズが膨らまない形式と設定（HEICかSVGか、Scales、Preserve Vector Data、Compression）を判断して入れる。素材がPNG・JPEG・SVG・PDFのどれで届いても、拡大して表示するかどうかで形式を決め、HEICへの変換と`Contents.json`の作成まで行う。「画像を追加して」「イラストをアセットに入れて」「ほめっとの画像を入れて」「imagesetを作って」「この画像をアプリで使いたい」と言われたとき、`HometeResources/Resources/Image.xcassets`に`.imageset`を足す・中身を差し替えるとき、デザイナーやClaudeが作った素材をアプリに取り込むときに必ず使う。色（`Colors.xcassets`）やアプリアイコン（`AppIcon.appiconset`）の変更には使わない。
---

# 画像アセットの入稿

`Image.xcassets`に入れた画像は、そのままアプリに入るわけではない。ビルド時に`actool`が形式や設定に合わせて変換し、`Assets.car`を作る。
そのため**元ファイルの大きさとアプリに入る大きさは一致しない**。特にベクター（SVG・PDF）は、Preserve Vector Dataの有無に関係なくビルド時に1x〜3xのビットマップが生成されて`Assets.car`に入る。
元ファイルが2MBのSVGでアプリが50MB増えた事例もある。

このスキルは、素材ごとに「拡大して表示するか」を見極めて、アプリサイズが最も小さくなる形式で入れるためのもの。

根拠: 上ちょ「今どきの画像アセット入稿：たった1枚の画像でアプリサイズが50MB増えた失敗から学ぶ最適化方法」（iOSDC Japan 2026 パンフレット pp.176-179、Xcode 26.6で検証）。経緯は[ADR-0041](../../../doc/adr/0041-homette-character-and-design-renewal.md)。

## 1. 形式を決める

配信先はiPhone・iPad（macOSなし。`SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO`）なので、1xは要らない。判断は次の表だけで済む。

| 素材 | 表示のされ方 | 形式 | Scales | Preserve Vector Data |
|---|---|---|---|---|
| ラスター（写真・PNGのイラスト）を含む | どれでも | HEIC | Individual（2x・3x） | 無効 |
| ベクターのみ | 決まった大きさで表示し、拡大しない（キャラ・空状態のイラストなど） | HEIC | Individual（2x・3x） | 無効 |
| ベクターのみ | 拡大・縮小して表示する（Dynamic Typeに追従するアイコン、大きさの違う複数箇所で使う単純なアイコン） | SVG | Single | 有効 |

- **Compressionは常に既定（Inherited）のまま**にする。GPU Best / GPU Smallestにすると再エンコードされた画像が追加され、かえって大きくなる
- **迷ったらHEIC**にする。HEICはApp Thinning後のサイズが最も小さい。ベクターが活きるのは「単純な形を、実際に拡大して使う」場合だけで、複雑なイラストほどベクターで入れたときの膨らみが大きい
- **SF Symbolsで足りるならアセットを足さない**。アイコンはまずSF Symbolsを探す
- **WebPは使わない**。`actool`が対応していない

## 2. 表示サイズ（1倍のpt）を決める

HEICにする場合は、画面で表示する最大の大きさを1倍（pt）として決め、その2倍・3倍のピクセルで書き出す。

- 素材のSVGに`viewBox`や`width` / `height`があれば、それが1倍の基準になることが多い（例: ほめっとは240×256pt → @2x 480×512、@3x 720×768）
- 実際の表示より大きく書き出すと、そのぶんだけアプリが大きくなる。画面のデザインやコードの`.frame`を見て、使う最大の大きさに合わせる
- 小さく表示する場所しかないなら、元の素材が大きくても縮めて書き出す

## 3. 変換してimagesetを作る

### HEIC

元になるラスター画像（@3x相当のPNG・JPEG）があれば、同梱スクリプトでimagesetを作れる。@3xから@2xを縮小で作り、両方をHEICにして`Contents.json`を書く。

```bash
.claude/skills/image-asset-import/scripts/make_heic_imageset.sh \
  <元画像（@3xのPNG/JPEG）> \
  LocalPackage/Sources/HometeResources/Resources/Image.xcassets \
  <アセット名>
```

- **`sips`のHEIC書き出しはサンドボックス内で失敗する**（`Error 13: an unknown error occurred`。HEVCのエンコーダを使えないため）。このスクリプトは`dangerouslyDisableSandbox: true`で実行する。失敗した理由がサンドボックスだとユーザーに一言伝える
- 元画像がSVGしかない場合、このMacには`rsvg-convert`などの変換ツールがない。SVGをブラウザ（Chromium）で開いて3倍のPNGを書き出してもらうか、素材側の生成手順（例: `doc/design/renewal/character/README.md`）に従う
- 元画像が@3xの大きさに足りない場合は拡大しない。ぼけるだけなので、大きい素材をもらい直す
- 透過は保たれる。変換後に`sips -g pixelWidth -g pixelHeight -g hasAlpha`で大きさと透過を確認し、1枚をPNGに戻して（`sips -s format png`）見た目も確かめる

### SVG（拡大して使うベクターだけ）

`<アセット名>.imageset/`にSVGを置き、`Contents.json`を次の形にする。

```json
{
  "images" : [
    { "filename" : "<アセット名>.svg", "idiom" : "universal" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "preserves-vector-representation" : true }
}
```

SVGはラスター画像や外部参照を含まない、純粋なベクターであること。ラスターが埋め込まれたSVGは、拡大しても荒れるうえに大きいので、HEICにする。

## 4. コードから使う

- `Image.xcassets`はSwiftGenのビルドプラグインが読み、`Assets.swift`を自動生成する。手で生成コードを書かない
- アセット名は`camelCase`か、既存のimagesetの命名に合わせる（例: `homette_normal`）。生成される識別子はアセット名から決まるので、決めたら変えない
- 追加後は`make build-local-package`でビルドし、生成された識別子で参照できることを確かめる

## 5. 確認すること

- [ ] 形式・Scales・Preserve Vector Data・Compressionが「1.」の表どおり
- [ ] HEICは@2x・@3xの2枚で、1xを入れていない。ピクセル数が表示サイズの2倍・3倍になっている
- [ ] `Contents.json`の`properties`に`compression-type`を書いていない（既定のまま）
- [ ] 元ファイル（PNG・PDFなど）をimagesetの中に残していない。imagesetの中にある画像はすべて`Assets.car`に入る

既存のimagesetを差し替えるときも同じ判断をする。今`Image.xcassets`にあるPDF（`preserves-vector-representation: true`）のimagesetは、この方針より前に入れたもの。触る機会があれば、上の表で形式を見直す。
