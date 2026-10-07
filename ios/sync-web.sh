#!/bin/sh
# 把网页版同步进 iOS App：重新打包 index.html，字体全部内置，离线可用、无第三方请求
set -e
cd "$(dirname "$0")/.."
./build.sh
OUT=ios/ClaudeXuetang/Web
mkdir -p "$OUT"
# 去掉 Google 字体，换成 App 内置的标题字体子集（由 fetch-fonts.py 生成）
grep -v -E 'fonts\.(googleapis|gstatic)\.com' index.html | sed 's#<title>#<link rel="stylesheet" href="fonts.css"><title>#' > "$OUT/index.html"
cp icon.svg "$OUT/icon.svg"
echo "synced to $OUT"
