#!/bin/sh
# 把 app.html 包装成可安装、可离线的 index.html
cd "$(dirname "$0")"
{
  echo '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">'
  echo '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
  echo '<meta name="theme-color" content="#1D6A5B"><meta name="apple-mobile-web-app-capable" content="yes">'
  echo '<meta name="apple-mobile-web-app-title" content="Claude 学堂"><link rel="manifest" href="manifest.webmanifest">'
  echo '<link rel="icon" href="icon.svg"><link rel="apple-touch-icon" href="icon.svg">'
  echo '<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style>'
  echo '</head><body>'
  cat app.html
  echo "<script>if('serviceWorker' in navigator&&location.protocol.startsWith('http'))navigator.serviceWorker.register('sw.js').catch(()=>{})</script>"
  echo '</body></html>'
} > index.html
echo "built index.html"
