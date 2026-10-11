#!/bin/bash
# @3x相当のラスター画像から、HEIC（@2x / @3x、Individual Scales）のimagesetを作る。
# sipsのHEIC書き出しはClaude Codeのサンドボックス内では失敗するため、サンドボックス外で実行すること。
#
# 使い方: make_heic_imageset.sh <元画像（@3xのPNG/JPEG）> <xcassetsのパス> <アセット名>
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "usage: $0 <source@3x.png|jpg> <path/to/Image.xcassets> <asset-name>" >&2
  exit 1
fi

src="$1"
xcassets="$2"
name="$3"
imageset="$xcassets/$name.imageset"

width=$(sips -g pixelWidth "$src" | awk '/pixelWidth/ {print $2}')
height=$(sips -g pixelHeight "$src" | awk '/pixelHeight/ {print $2}')
if [ $((width % 3)) -ne 0 ] || [ $((height % 3)) -ne 0 ]; then
  echo "warning: ${width}x${height} は3で割り切れません。@2xの大きさが端数で丸められます" >&2
fi
long_side_2x=$(( (width > height ? width : height) * 2 / 3 ))

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$imageset"
sips -s format heic "$src" --out "$imageset/$name@3x.heic" >/dev/null
sips -Z "$long_side_2x" "$src" --out "$tmp/$name@2x.png" >/dev/null
sips -s format heic "$tmp/$name@2x.png" --out "$imageset/$name@2x.heic" >/dev/null

cat > "$imageset/Contents.json" <<EOF
{
  "images" : [
    {
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "$name@2x.heic",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "$name@3x.heic",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

sips -g pixelWidth -g pixelHeight -g hasAlpha "$imageset"/*.heic
