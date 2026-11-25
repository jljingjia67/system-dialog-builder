import Cocoa
import WebKit

// Borderless windows return false from canBecomeKey/canBecomeMain by default, so
// their text fields never receive keystrokes. This subclass forces them to true so
// the popup's web view can accept keyboard input.
class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    // Independent borderless popup window + its web view (kept as references so
    // they are not deallocated while shown).
    var popupWindow: NSWindow?
    var popupWebView: WKWebView?
    var pendingPopupConfigJson: String = "{}"

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
        // Belt-and-suspenders: paint the window white so no default gray
        // windowBackgroundColor flashes around the content.
        window.backgroundColor = .white
        window.center()

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // Register native bridge: builder page -> Swift.
        let contentController = config.userContentController
        contentController.add(self, name: "showPopup")
        contentController.add(self, name: "closePopup")
        contentController.add(self, name: "submitPopup")

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
        window.makeFirstResponder(webView)
        NSApp.activate(ignoringOtherApps: true)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Popup window

    func popupHtmlPath() -> String {
        if let bundled = Bundle.main.path(forResource: "popup", ofType: "html") {
            return bundled
        }
        let exeDir = CommandLine.arguments.count > 0
            ? URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
            : URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let sibling = exeDir.appendingPathComponent("popup.html").path
        if FileManager.default.fileExists(atPath: sibling) {
            return sibling
        }
        let fallbackDir = ProcessInfo.processInfo.environment["APP_DIR"] ?? FileManager.default.currentDirectoryPath
        return URL(fileURLWithPath: fallbackDir).appendingPathComponent("popup.html").path
    }

    func showPopup(configJson: String) {
        pendingPopupConfigJson = configJson

        // Reuse an existing popup window if present.
        if let existing = popupWindow, let wv = popupWebView {
            renderPopup(into: wv)
            existing.center()
            existing.makeKeyAndOrderFront(nil)
            existing.makeFirstResponder(wv)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let popupWidth: CGFloat = 320
        let popupHeight: CGFloat = 260

        let win = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: popupWidth, height: popupHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = true
        win.level = .floating
        win.isMovableByWindowBackground = true
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let cfg = WKWebViewConfiguration()
        cfg.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let controller = cfg.userContentController
        controller.add(self, name: "closePopup")
        // The popup web view is where the OK button posts submitPopup from, so the
        // handler must be registered on this content controller too.
        controller.add(self, name: "submitPopup")

        let wv = WKWebView(frame: NSRect(x: 0, y: 0, width: popupWidth, height: popupHeight), configuration: cfg)
        wv.navigationDelegate = self
        // Transparent web view background. The private KVC can silently fail, so we
        // ALSO use the public API and clear the backing layer.
        wv.setValue(false, forKey: "drawsBackground") // fallback
        if #available(macOS 12.0, *) {
            wv.underPageBackgroundColor = NSColor.clear
        }
        wv.wantsLayer = true
        wv.layer?.backgroundColor = NSColor.clear.cgColor

        win.contentView = wv

        let path = popupHtmlPath()
        if FileManager.default.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        win.center()
        win.makeKeyAndOrderFront(nil)
        win.makeFirstResponder(wv)
        NSApp.activate(ignoringOtherApps: true)

        popupWindow = win
        popupWebView = wv
    }

    func renderPopup(into wv: WKWebView) {
        // pendingPopupConfigJson is a JSON string; embed it as a JS string literal.
        let data = pendingPopupConfigJson.data(using: .utf8) ?? Data("{}".utf8)
        if let encoded = try? JSONSerialization.data(withJSONObject: [pendingPopupConfigJson], options: []),
           let arr = String(data: encoded, encoding: .utf8) {
            // arr looks like ["...escaped json..."]; strip the brackets to get a JS string literal.
            let literal = String(arr.dropFirst().dropLast())
            wv.evaluateJavaScript("window.renderDialog(\(literal));", completionHandler: nil)
        } else {
            _ = data
            wv.evaluateJavaScript("window.renderDialog('{}');", completionHandler: nil)
        }
    }

    // Forward the submitted values payload to the builder page, then close the popup.
    func submitPopup(payloadJson: String) {
        // Embed payloadJson (already a JSON string) as a safely escaped JS string literal.
        if let encoded = try? JSONSerialization.data(withJSONObject: [payloadJson], options: []),
           let arr = String(data: encoded, encoding: .utf8) {
            let literal = String(arr.dropFirst().dropLast())
            webView.evaluateJavaScript("if (window.receiveSubmission) { window.receiveSubmission(\(literal)); }", completionHandler: nil)
        }
        closePopup()
    }

    func closePopup() {
        if let win = popupWindow {
            win.orderOut(nil)
            win.close()
        }
        popupWindow = nil
        popupWebView = nil
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
        // Only the builder window has this delegate, so closing it quits the app.
        NSApp.terminate(nil)
    }
}

extension AppDelegate: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        switch message.name {
        case "showPopup":
            let json = (message.body as? String) ?? "{}"
            showPopup(configJson: json)
        case "closePopup":
            closePopup()
        case "submitPopup":
            let json = (message.body as? String) ?? "{}"
            submitPopup(payloadJson: json)
        default:
            break
        }
    }
}

extension AppDelegate: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject the current config into the popup once its page is ready.
        if webView == popupWebView {
            renderPopup(into: webView)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
