# プロモーション動画

SNS向け（縦型 1080×1920・15秒・30fps・無音）のプロモーション動画。

- `homeau_promo_15s.mp4` … 完成した動画
- `thumbnail_start.png` … 先頭フレーム（サムネイル用）
- `source/index.html` … 動画の中身。`render(t)` で t 秒時点の状態を描く
- `source/render.cjs` … Playwright で1フレームずつ撮る
- `source/assets/` … `Image.xcassets` のほめっと（HEIC）をPNGに変換したもの

画面はアプリの色定義とVRTのスナップショットを参考にHTMLで再現したもので、家事名・ユーザー名・ポイントなどは架空のデータ。

## 書き出し

```bash
cd promo/source
mkdir -p frames
node render.cjs "$PWD/index.html" "$PWD/frames" video
ffmpeg -framerate 30 -i frames/f%04d.png -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart ../homeau_promo_15s.mp4
```

`render.cjs` は Playwright を `/opt/node-tools/node_modules/playwright` から読み込んでいる。環境に合わせて書き換えること。フォント（Zen Maru Gothic）は Google Fonts から読み込む。
