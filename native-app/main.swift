import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowWidth: CGFloat = 1000
        let windowHeight: CGFloat = 800

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "System Dialog Builder"
        window.minSize = NSSize(width: 720, height: 600)
        window.center()

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), configuration: config)

        window.contentView = webView
        window.delegate = self

        let htmlPath = Bundle.main.path(forResource: "builder", ofType: "html")
            ?? (CommandLine.arguments.count > 0
                ? URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().appendingPathComponent("builder.html").path
                : "")

        if FileManager.default.fileExists(atPath: htmlPath) {
            webView.loadFileURL(URL(fileURLWithPath: htmlPath), allowingReadAccessTo: URL(fileURLWithPath: htmlPath).deletingLastPathComponent())
        } else {
            let fallbackDir = ProcessInfo.processInfo.environment["APP_DIR"] ?? FileManager.default.currentDirectoryPath
            let fallbackPath = URL(fileURLWithPath: fallbackDir).appendingPathComponent("builder.html").path
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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    static let embeddedHTML = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8">
    <style>
    html,body{height:100%;margin:0;display:flex;align-items:center;justify-content:center;
      font-family:-apple-system,BlinkMacSystemFont,sans-serif;color:#1d1d1f}
    @media(prefers-color-scheme:dark){html,body{background:#1e1e1e;color:#f5f5f7}}
    </style>
    </head>
    <body>
    <p>Builder UI not found.</p>
    </body>
    </html>
    """
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
