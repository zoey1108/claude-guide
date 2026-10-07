#!/usr/bin/env python3
"""按 app.html 里用到的字符，下载 Noto Serif SC 标题字体子集到 App 内（改了课程内容后重新运行）。"""
import re, urllib.parse, subprocess, os, glob
base = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
s = open(os.path.join(base, 'app.html'), encoding='utf-8').read()
chars = sorted(set(c for c in s if ord(c) > 127) | set('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%/.,:;!?()-+'))
out = os.path.join(base, 'ios', 'ClaudeXuetang', 'Web')
for f in glob.glob(out + '/NotoSerifSC-*.woff2'): os.remove(f)
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130 Safari/537.36'
chunks = [chars[i:i + 300] for i in range(0, len(chars), 300)]
faces = []
for w in (700, 800):
    for i, ch in enumerate(chunks):
        url = f'https://fonts.googleapis.com/css2?family=Noto+Serif+SC:wght@{w}&text=' + urllib.parse.quote(''.join(ch))
        css = subprocess.run(['curl', '-s', '-m', '40', '-A', UA, url], capture_output=True, text=True).stdout
        srcs = re.findall(r'url\((https://[^)]+)\)', css)
        assert len(srcs) == 1, f'weight {w} chunk {i}: got {len(srcs)} sources'
        data = subprocess.run(['curl', '-s', '-m', '90', '-A', UA, srcs[0]], capture_output=True).stdout
        name = f'NotoSerifSC-{w}-{i}.woff2'
        open(os.path.join(out, name), 'wb').write(data)
        rng = ','.join('U+%04X' % ord(c) for c in ch)
        faces.append(f"@font-face{{font-family:'Noto Serif SC';font-weight:{w};font-display:swap;src:url({name}) format('woff2');unicode-range:{rng}}}")
open(os.path.join(out, 'fonts.css'), 'w').write('\n'.join(faces) + '\n')
print(f'{len(chunks)} chunks x 2 weights written to {out}')
