# Claude 学堂

中文 Claude 使用教程 App：22 节课 + 小测、16 个提示词模板、速查表、学习进度。

- 改内容：编辑 `app.html`（课程在 `MODULES`，模板在 `PROMPTS`，速查在 `CHEAT`）
- 打包：`./build.sh` 生成可离线、可安装的 `index.html`
- 本地运行：`python3 -m http.server 4173`，打开 http://localhost:4173
- 手机安装：部署到任意静态托管（如 Vercel、Netlify、GitHub Pages）后，用手机浏览器「添加到主屏幕」

- 设计文稿、Figma 画板、截图与归档：`~/Desktop/claude-guide-design`

## iOS App

- 项目：`ios/ClaudeXuetang.xcodeproj`（SwiftUI + WKWebView，课程内容全部内置、离线可用）
- 同步网页内容：`ios/sync-web.sh`；新增文字后先运行 `ios/fetch-fonts.py` 更新内置标题字体
- 上架资料与步骤：见设计档案 `05-App Store/`
- 隐私政策：https://zoey1108.github.io/claude-guide/privacy.html
