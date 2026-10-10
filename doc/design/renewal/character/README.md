# ほめっと 素材

homeauのイメージキャラクター「ほめっと」の清書素材。方針は [#403](https://github.com/stotic-dev/homete_iOS/issues/403) を参照。

![キャラクターシート](character_sheet.png)

| ディレクトリ | 中身 | 用途 |
|---|---|---|
| `svg/` | 表情・ポーズ9種のSVG（240×256） | 編集・Web |
| `pdf/` | 同じ9種のベクターPDF | `Image.xcassets`に入れる（Preserve Vector Data有効、Single Scale） |
| `png/` | 同じ9種の@3x PNG（透過） | ストア画像・資料 |
| `drafts/` | 不採用になったキャラ案 | 記録用 |

素材は`generate_homette.py`から生成している。形や色を直すときはこのスクリプトを編集して `python3 generate_homette.py` を流し、PDF・PNGは書き出し直す（SVGをChromiumで開いて印刷・スクリーンショット）。手でSVGを直すと次の生成で消える。

## 色

| 部位 | 色 |
|---|---|
| 線 | `#4A3B2C` |
| ロゼット / 影 | `#F6C152` / `#E59F22` |
| 顔 | `#FFF9EC` |
| 若葉・リボン / 影 | `#5DBB84` / `#3E9A66` |
| ほっぺ | `#F4A0B4` |

ライト・ダークどちらのテーマでも同じ色で使う。
