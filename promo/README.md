# プロモーション動画

- `homeau_promo_15s.mp4` … SNS向け（縦型 1080×1920・15秒・30fps・無音）
- `homeau_app_preview_886x1920.mp4` … App Storeのアプリプレビュー（886×1920・23秒・30fps・H.264 High 4.0 / 11Mbps・無音のステレオAAC 256kbps）。iPhone 6.9"〜6.1"の枠にそのまま使える
- `app_preview_poster_5s.png` … アプリプレビューの5秒時点（App Store Connectのポスターフレームの初期位置）
- `thumbnail_start.png` … 先頭フレーム（サムネイル用）
- `source/index.html` … SNS版の中身。`render(t)` で t 秒時点の状態を描く
- `source/store.html` … アプリプレビューの中身。画面を393×852ptで組み、886×1920に拡大している
- `source/render.cjs` … SNS版を Playwright で1フレームずつ撮る
- `source/render2.cjs` … 解像度と長さを指定できる版（`node render2.cjs <html> <outDir> <幅> <高さ> video`。長さは html の `DURATION`）
- `source/assets/` … `Image.xcassets` のほめっと（HEIC）をPNGに変換したもの

画面はアプリの色定義とVRTのスナップショットを参考にHTMLで再現したもので、家事名・ユーザー名・ポイントなどは架空のデータ。

> [!WARNING]
> Appleのガイドラインでは、アプリプレビューはアプリから録画した映像で作ることになっている（"App previews must show only content within the app itself"）。アプリプレビューも画面をHTMLで再現しているため、審査で却下されるおそれがある。却下されたら、シミュレータで録画した映像に差し替える。

## 書き出し

```bash
cd promo/source
mkdir -p frames
node render.cjs "$PWD/index.html" "$PWD/frames" video
ffmpeg -framerate 30 -i frames/f%04d.png -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart ../homeau_promo_15s.mp4

# アプリプレビュー（Appleの仕様に合わせて固定ビットレートと無音のステレオ音声を付ける）
mkdir -p sframes
node render2.cjs "$PWD/store.html" "$PWD/sframes" 886 1920 video
ffmpeg -framerate 30 -i sframes/f%04d.png -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 -shortest \
  -c:v libx264 -profile:v high -level:v 4.0 -preset slow -b:v 11M -minrate 11M -maxrate 11M -bufsize 11M \
  -x264-params nal-hrd=cbr:force-cfr=1 -pix_fmt yuv420p -r 30 \
  -c:a aac -b:a 256k -ar 48000 -ac 2 -movflags +faststart ../homeau_app_preview_886x1920.mp4
```

`render.cjs` は Playwright を `/opt/node-tools/node_modules/playwright` から読み込んでいる。環境に合わせて書き換えること。フォント（Zen Maru Gothic）は Google Fonts から読み込む。
