import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screenSize = NSScreen.main?.frame.size ?? NSSize(width: 1440, height: 900)
        let windowWidth: CGFloat = 320
        let windowHeight: CGFloat = 340
        let x = (screenSize.width - windowWidth) / 2
        let y = (screenSize.height - windowHeight) / 2

        window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let userScript = WKUserScript(
            source: """
            window.closeApp = function() {
                window.webkit.messageHandlers.closeApp.postMessage('close');
            };
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        let handler = ScriptHandler(app: self)
        config.userContentController.add(handler, name: "closeApp")

        window.contentView = webView

        let htmlPath = Bundle.main.path(forResource: "dialog", ofType: "html")
            ?? (CommandLine.arguments.count > 0
                ? URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent("dialog.html").path
                : "")

        if FileManager.default.fileExists(atPath: htmlPath) {
            webView.loadFileURL(URL(fileURLWithPath: htmlPath), allowingReadAccessTo: URL(fileURLWithPath: htmlPath).deletingLastPathComponent())
        } else {
            let fallbackDir = ProcessInfo.processInfo.environment["APP_DIR"] ?? FileManager.default.currentDirectoryPath
            let fallbackPath = URL(fileURLWithPath: fallbackDir).appendingPathComponent("dialog.html").path
            if FileManager.default.fileExists(atPath: fallbackPath) {
                webView.loadFileURL(URL(fileURLWithPath: fallbackPath), allowingReadAccessTo: URL(fileURLWithPath: fallbackPath).deletingLastPathComponent())
            } else {
                webView.loadHTMLString(Self.embeddedHTML, baseURL: nil)
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    static let embeddedHTML = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8">
    <style>
    *{margin:0;padding:0;box-sizing:border-box}
    html,body{width:100%;height:100%;background:transparent;overflow:hidden;
      font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text','Helvetica Neue',sans-serif;
      -webkit-font-smoothing:antialiased;user-select:none}
    body{display:flex;align-items:center;justify-content:center}
    .dialog{width:270px;background:rgba(236,236,236,0.92);
      backdrop-filter:blur(40px) saturate(1.8);-webkit-backdrop-filter:blur(40px) saturate(1.8);
      border-radius:14px;box-shadow:0 0 0 0.5px rgba(0,0,0,0.12),0 8px 32px rgba(0,0,0,0.18),0 2px 8px rgba(0,0,0,0.08);
      overflow:hidden}
    .dialog-header{padding:20px 20px 0 20px;text-align:center}
    .dialog-icon{width:48px;height:48px;margin:0 auto 12px auto;display:flex;align-items:center;justify-content:center}
    .dialog-icon svg{width:48px;height:48px}
    .dialog-title{font-size:13px;font-weight:700;color:#1d1d1f;margin-bottom:6px;letter-spacing:-0.01em}
    .dialog-desc{font-size:11px;font-weight:400;color:#3c3c43;line-height:1.4;margin-bottom:16px}
    .dialog-body{padding:0 20px 16px 20px}
    .input-field{width:100%;height:24px;border:0.5px solid rgba(0,0,0,0.18);border-radius:4px;
      background:rgba(255,255,255,0.85);padding:0 8px;font-size:12px;font-family:inherit;
      color:#1d1d1f;outline:none}
    .input-field:focus{border-color:rgba(0,103,244,0.5);box-shadow:0 0 0 2.5px rgba(0,103,244,0.25)}
    .input-field::placeholder{color:rgba(60,60,67,0.4)}
    .dialog-buttons{border-top:0.5px solid rgba(0,0,0,0.12);display:flex;height:44px}
    .dialog-btn{flex:1;height:44px;border:none;background:transparent;font-family:inherit;
      font-size:13px;color:#007AFF;cursor:pointer;display:flex;align-items:center;justify-content:center;
      transition:background 0.1s}
    .dialog-btn:hover{background:rgba(0,0,0,0.04)}
    .dialog-btn:active{background:rgba(0,0,0,0.08)}
    .dialog-btn.cancel{border-right:0.5px solid rgba(0,0,0,0.12)}
    .dialog-btn.ok{font-weight:600}
    @media(prefers-color-scheme:dark){
      .dialog{background:rgba(50,50,50,0.88);box-shadow:0 0 0 0.5px rgba(255,255,255,0.08),0 8px 32px rgba(0,0,0,0.45),0 2px 8px rgba(0,0,0,0.25)}
      .dialog-title{color:#f5f5f7}.dialog-desc{color:rgba(235,235,245,0.6)}
      .input-field{background:rgba(30,30,30,0.7);border-color:rgba(255,255,255,0.15);color:#f5f5f7}
      .input-field:focus{border-color:rgba(10,132,255,0.5);box-shadow:0 0 0 2.5px rgba(10,132,255,0.25)}
      .input-field::placeholder{color:rgba(235,235,245,0.3)}
      .dialog-buttons{border-top-color:rgba(255,255,255,0.1)}
      .dialog-btn{color:#0A84FF}.dialog-btn:hover{background:rgba(255,255,255,0.06)}
      .dialog-btn:active{background:rgba(255,255,255,0.1)}
      .dialog-btn.cancel{border-right-color:rgba(255,255,255,0.1)}
    }
    </style>
    </head>
    <body>
    <div class="dialog">
      <div class="dialog-header">
        <div class="dialog-icon">
          <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="12" y="22" width="24" height="18" rx="4" fill="#8E8E93"/>
            <path d="M16 22V16C16 11.5817 19.5817 8 24 8C28.4183 8 32 11.5817 32 16V22" stroke="#8E8E93" stroke-width="3.5" stroke-linecap="round" fill="none"/>
            <circle cx="24" cy="30" r="2.5" fill="#636366"/>
            <rect x="23" y="31" width="2" height="4" rx="1" fill="#636366"/>
          </svg>
        </div>
        <div class="dialog-title">Sign In</div>
        <div class="dialog-desc">Enter the password for your account.</div>
      </div>
      <div class="dialog-body">
        <input type="password" class="input-field" placeholder="Password" id="pw" autofocus>
      </div>
      <div class="dialog-buttons">
        <button class="dialog-btn cancel" onclick="window.closeApp()">Cancel</button>
        <button class="dialog-btn ok" onclick="window.closeApp()">OK</button>
      </div>
    </div>
    <script>
    document.getElementById('pw').addEventListener('keydown',function(e){
      if(e.key==='Enter'||e.key==='Escape')window.closeApp();
    });
    </script>
    </body>
    </html>
    """
}

class ScriptHandler: NSObject, WKScriptMessageHandler {
    let app: AppDelegate
    init(app: AppDelegate) { self.app = app }
    func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "closeApp" { app.quit() }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
