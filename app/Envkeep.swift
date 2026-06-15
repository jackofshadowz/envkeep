// Envkeep — native macOS wrapper around the `envkeep gui` server.
//
// It launches `envkeep gui --no-open`, reads the localhost URL (with its
// one-time auth token) from the server's stdout, and loads it in a native
// WKWebView window. Quitting the app stops the server. No browser involved.
//
// Build: see ../build-app.sh

import Cocoa
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    // JS copies via window.webkit.messageHandlers.{copyText,copySecret}.postMessage(value).
    // copySecret additionally wipes the pasteboard ~45s later (if still unchanged).
    func userContentController(_ controller: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        guard let text = message.body as? String else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        if message.name == "copySecret" {
            let stamp = pb.changeCount
            DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
                // Only clear if the user hasn't copied something else since.
                if pb.changeCount == stamp, pb.string(forType: .string) == text {
                    pb.clearContents()
                }
            }
        }
    }

    var window: NSWindow!
    var webView: WKWebView!
    var server: Process?
    let port = 8782

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()

        let rect = NSRect(x: 0, y: 0, width: 920, height: 740)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "Envkeep"
        window.center()
        window.setFrameAutosaveName("SecretsMainWindow")
        window.minSize = NSSize(width: 560, height: 480)

        let config = WKWebViewConfiguration()
        // Native bridge so the web GUI can copy to the real macOS pasteboard
        // (WKWebView blocks navigator.clipboard / execCommand over http).
        config.userContentController.add(self, name: "copyText")
        config.userContentController.add(self, name: "copySecret")
        webView = WKWebView(frame: rect, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.width, .height]
        window.contentView = webView
        showSplash("Starting secure vault…", color: "#8b93a7")

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        startServer()
    }

    // Find the `envkeep` CLI. A launched .app has a minimal PATH, so probe the
    // usual install locations explicitly (with the legacy `secrets` name as fallback).
    func locateSecrets() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let dirs = ["\(home)/.local/bin", "/usr/local/bin", "/opt/homebrew/bin"]
        for d in dirs {
            for name in ["envkeep", "secrets"] {
                let p = "\(d)/\(name)"
                if FileManager.default.isExecutableFile(atPath: p) { return p }
            }
        }
        return nil
    }

    func startServer() {
        guard let bin = locateSecrets() else {
            showSplash("Couldn't find the `envkeep` CLI.<br>Run ./install.sh first.",
                       color: "#ff5b6e")
            return
        }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let p = Process()
        p.executableURL = URL(fileURLWithPath: bin)
        p.arguments = ["gui", "--no-open", "--port", String(port)]
        // Give the server a real PATH so it can find `age` and `security`.
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:\(home)/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        p.environment = env

        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        let handle = pipe.fileHandleForReading

        var buffer = ""
        handle.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            buffer += chunk
            if let url = self?.extractURL(buffer) {
                handle.readabilityHandler = nil
                DispatchQueue.main.async { self?.webView.load(URLRequest(url: url)) }
            }
        }

        do {
            try p.run()
            server = p
        } catch {
            showSplash("Failed to start the vault server:<br>\(error.localizedDescription)",
                       color: "#ff5b6e")
        }
    }

    func extractURL(_ s: String) -> URL? {
        for line in s.split(whereSeparator: \.isNewline) {
            guard let r = line.range(of: "http://127.0.0.1:") else { continue }
            let str = String(line[r.lowerBound...]).trimmingCharacters(in: .whitespaces)
            if let u = URL(string: str) { return u }
        }
        return nil
    }

    func showSplash(_ html: String, color: String) {
        webView.loadHTMLString(
            """
            <body style='background:#0f1115;color:\(color);margin:0;height:100vh;
            display:flex;align-items:center;justify-content:center;text-align:center;
            padding:40px;font:15px/1.6 -apple-system,BlinkMacSystemFont,sans-serif'>
            <div>\(html)</div></body>
            """, baseURL: nil)
    }

    @objc func reloadPage() { webView.reload() }

    // Full standard macOS menu bar: App (Hide/Quit), Edit, View, Window.
    func setupMenu() {
        let main = NSMenu()

        // ---- App menu ----
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Envkeep",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Envkeep",
                        action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others",
                        action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All",
                        action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Envkeep",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        // ---- Edit menu (so ⌘Z/⌘X/⌘C/⌘V/⌘A work in web fields) ----
        let editItem = NSMenuItem(); main.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All",
                         action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        // ---- View menu ----
        let viewItem = NSMenuItem(); main.addItem(viewItem)
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Reload", action: #selector(reloadPage), keyEquivalent: "r")
        viewItem.submenu = viewMenu

        // ---- Window menu ----
        let winItem = NSMenuItem(); main.addItem(winItem)
        let winMenu = NSMenu(title: "Window")
        winMenu.addItem(withTitle: "Minimize",
                        action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        winMenu.addItem(withTitle: "Zoom",
                        action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        winMenu.addItem(.separator())
        winMenu.addItem(withTitle: "Close",
                        action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        winItem.submenu = winMenu

        NSApp.mainMenu = main
        NSApp.windowsMenu = winMenu
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        server?.terminate()
    }
}

// Native panels for JS alert()/confirm()/prompt(); without these WKWebView
// silently dismisses dialogs (so `confirm()` returns false and Delete is a no-op).
extension AppDelegate: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let a = NSAlert()
        a.messageText = message
        a.addButton(withTitle: "OK")
        a.beginSheetModal(for: window) { _ in completionHandler() }
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let a = NSAlert()
        a.messageText = message
        a.addButton(withTitle: "OK")
        a.addButton(withTitle: "Cancel")
        a.beginSheetModal(for: window) { resp in
            completionHandler(resp == .alertFirstButtonReturn)
        }
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        completionHandler(defaultText)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
