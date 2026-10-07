import SwiftUI
import WebKit
import UIKit

/// 把打包在 App 里的教程页面显示出来。页面通过 app://local/ 加载，
/// 这样学习进度（localStorage）能稳定保存，而且完全离线可用。
struct LessonWebView: UIViewRepresentable {
    static let scheme = "app"
    static let startURL = URL(string: "app://local/index.html")!

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.setURLSchemeHandler(BundledFileHandler(), forURLScheme: Self.scheme)

        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "copy")
        controller.add(context.coordinator, name: "haptic")
        controller.add(context.coordinator, name: "save")
        controller.addUserScript(WKUserScript(source: Self.restoreScript(), injectionTime: .atDocumentStart, forMainFrameOnly: true))
        controller.addUserScript(WKUserScript(source: Self.bridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = UIColor(named: "PaperColor")
        webView.scrollView.backgroundColor = UIColor(named: "PaperColor")
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsLinkPreview = false
        // 截图用：启动参数 -startHash l3 可直接打开某一页，平时不生效
        var url = Self.startURL
        if let hash = UserDefaults.standard.string(forKey: "startHash"), !hash.isEmpty,
           let deep = URL(string: "app://local/index.html#\(hash)") {
            url = deep
        }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    /// 学习进度在网页里存在 localStorage，同时镜像到 UserDefaults，
    /// 保证 App 被系统回收或强制退出后进度也不会丢。
    static let storageKey = "claude-xuetang-v1"

    static func restoreScript() -> String {
        let saved = UserDefaults.standard.string(forKey: storageKey)
        let literal: String
        if let saved, let data = try? JSONEncoder().encode(saved), let text = String(data: data, encoding: .utf8) {
            literal = text
        } else {
            literal = "null"
        }
        return """
        (function () {
          var KEY = '\(storageKey)', saved = \(literal), mem = {};
          var post = function (v) { try { window.webkit.messageHandlers.save.postMessage(v == null ? '' : String(v)); } catch (e) {} };
          var store;
          try { localStorage.setItem('__probe', '1'); localStorage.removeItem('__probe'); store = localStorage; } catch (e) { store = null; }
          if (!store) {
            store = {
              getItem: function (k) { return Object.prototype.hasOwnProperty.call(mem, k) ? mem[k] : null; },
              setItem: function (k, v) { mem[k] = String(v); },
              removeItem: function (k) { delete mem[k]; }
            };
            try { Object.defineProperty(window, 'localStorage', { value: store, configurable: true }); } catch (e) {}
          }
          if (saved !== null) { try { store.setItem(KEY, saved); } catch (e) {} }
          var target = (typeof Storage !== 'undefined' && store instanceof Storage) ? Storage.prototype : store;
          var set = target.setItem, del = target.removeItem;
          target.setItem = function (k, v) { set.call(this, k, v); if (this === store && k === KEY) post(v); };
          target.removeItem = function (k) { del.call(this, k); if (this === store && k === KEY) post(null); };
        })();
        """
    }

    /// 让网页里的「复制」和轻提示使用系统剪贴板与触感反馈。
    static let bridgeScript = """
    (function () {
      var post = function (name, value) {
        try { window.webkit.messageHandlers[name].postMessage(String(value)); } catch (e) {}
      };
      var clip = { writeText: function (t) { post('copy', t); return Promise.resolve(); } };
      try { Object.defineProperty(navigator, 'clipboard', { value: clip, configurable: true }); }
      catch (e) { try { navigator.clipboard.writeText = clip.writeText; } catch (e2) {} }
      document.addEventListener('click', function (e) {
        var b = e.target.closest && e.target.closest('button');
        if (b && (b.dataset.ans != null || b.dataset.done != null || b.dataset.fav != null)) post('haptic', 'light');
      }, true);
    })();
    """

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "copy":
                UIPasteboard.general.string = message.body as? String
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case "haptic":
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case "save":
                let value = message.body as? String ?? ""
                if value.isEmpty {
                    UserDefaults.standard.removeObject(forKey: LessonWebView.storageKey)
                } else {
                    UserDefaults.standard.set(value, forKey: LessonWebView.storageKey)
                }
            default:
                break
            }
        }

        /// 站外链接交给 Safari 打开，App 内只显示本地页面。
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else { return decisionHandler(.cancel) }
            if url.scheme == LessonWebView.scheme || url.scheme == "about" {
                decisionHandler(.allow)
            } else {
                if action.navigationType == .linkActivated { UIApplication.shared.open(url) }
                decisionHandler(.cancel)
            }
        }
    }
}

/// 从 App 包里读取网页文件。
final class BundledFileHandler: NSObject, WKURLSchemeHandler {
    private static let types: [String: String] = [
        "html": "text/html; charset=utf-8", "js": "text/javascript; charset=utf-8",
        "css": "text/css; charset=utf-8", "json": "application/json",
        "webmanifest": "application/manifest+json", "png": "image/png", "svg": "image/svg+xml",
        "woff2": "font/woff2",
    ]

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let name = String(path.dropFirst())
        let ext = (name as NSString).pathExtension
        let base = (name as NSString).deletingPathExtension

        let fileURL = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "Web")
            ?? Bundle.main.url(forResource: base, withExtension: ext)
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else {
            let missing = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
            task.didReceive(missing)
            task.didFinish()
            return
        }
        let headers = ["Content-Type": Self.types[ext.lowercased()] ?? "application/octet-stream",
                       "Content-Length": String(data.count)]
        task.didReceive(HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}
