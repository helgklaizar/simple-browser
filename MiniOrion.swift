import SwiftUI
import WebKit

// --- ENGINE SUPERSTRUCTURE ---
// Singleton for centralized engine operations to reduce memory load
class EngineCore {
    static let sharedProcessPool = WKProcessPool()
    
    static func cleanHeavyCacheData() {
        // We purge aggressive caches like media, network requests, disk blobs
        // but strictly KEEP cookies and local storage so user doesn't lose logins.
        var typesToClean = WKWebsiteDataStore.allWebsiteDataTypes()
        typesToClean.remove(WKWebsiteDataTypeCookies)
        // Keep databases if sites like Twitch rely on them for persistence
        typesToClean.remove(WKWebsiteDataTypeWebSQLDatabases)
        typesToClean.remove(WKWebsiteDataTypeIndexedDBDatabases)
        typesToClean.remove(WKWebsiteDataTypeLocalStorage)
        typesToClean.remove(WKWebsiteDataTypeSessionStorage)
        
        WKWebsiteDataStore.default().removeData(ofTypes: typesToClean, modifiedSince: Date.distantPast) {
            print("Orion Engine: Cleared unused background cache arrays successfully.")
        }
    }
}

@main
struct MiniOrionApp: App {
    init() {
        // Trigger cache purging immediately on process start
        EngineCore.cleanHeavyCacheData()
    }
    
    var body: some Scene {
        WindowGroup("Mini Orion") {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

struct ContentView: View {
    @State private var urlString: String
    @State private var zoomLevel: CGFloat = 1.0
    
    init(initialUrl: String = "") {
        _urlString = State(initialValue: initialUrl)
    }
    
    @State private var webView: WKWebView = {
        let prefs = WKPreferences()
        prefs.isFraudulentWebsiteWarningEnabled = false
        prefs.javaScriptCanOpenWindowsAutomatically = false
        prefs.setValue(true, forKey: "acceleratedCompositingEnabled")
        prefs.setValue(true, forKey: "webGLEnabled")

        let config = WKWebViewConfiguration()
        config.preferences = prefs
        // Block autoplay per user request, but safely intercept play() errors in JS so sites don't crash
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.allowsAirPlayForMediaPlayback = true
        // Assign global process pool to drastically reduce total macOS RAM utilized across IFrames
        config.processPool = EngineCore.sharedProcessPool
        
        let wv = WKWebView(frame: .zero, configuration: config)
        // Standard user agent to prevent compatibility shims or redirects
        wv.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        wv.allowsBackForwardNavigationGestures = true
        wv.allowsMagnification = true
        wv.setValue(false, forKey: "drawsBackground")
        return wv
    }()
    
    // Changed key to act as a database reset - your old favorites are wiped from the UI completely!
    @State private var favorites: [String] = UserDefaults.standard.stringArray(forKey: "orionFavorites_Eng") ?? []

    var isFavorite: Bool {
        favorites.contains(urlString)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Spacer().frame(width: 90)
                
                HStack(spacing: 16) {
                    Button(action: { webView.goBack() }) { Image(systemName: "chevron.left.circle").font(.system(size: 16, weight: .medium)) }.buttonStyle(PlainButtonStyle())
                    Button(action: { webView.reload() }) { Image(systemName: "arrow.clockwise").font(.system(size: 16, weight: .medium)) }.buttonStyle(PlainButtonStyle())
                    Button(action: { webView.goForward() }) { Image(systemName: "chevron.right.circle").font(.system(size: 16, weight: .medium)) }.buttonStyle(PlainButtonStyle())
                }
                
                Divider().frame(height: 14)
                
                HStack(spacing: 4) {
                    TextField("Search or enter address...", text: $urlString, onCommit: { loadURL() })
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                    
                    Button(action: { toggleFavorite() }) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(isFavorite ? .yellow : .primary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isFavorite ? "Remove from Favorites" : "Add to Favorites")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(width: 350)
                .background(Color.black.opacity(0.15))
                .cornerRadius(6)
                
                Divider().frame(height: 14)
                
                HStack(spacing: 12) {
                    ForEach(favorites, id: \.self) { favUrl in
                        ZStack {
                            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=64&domain_url=\(favUrl)")) { image in
                                image.resizable()
                            } placeholder: { Color.gray.opacity(0.3) }
                            .frame(width: 16, height: 16)
                            .cornerRadius(4)
                            
                            MiddleClickLayer(onLeftClick: {
                                urlString = favUrl
                                loadURL()
                            }, onMiddleClick: {
                                openNewWindow(url: favUrl)
                            })
                        }
                        .frame(width: 20, height: 20)
                        .help("Open \(favUrl) (Middle-click for New Window)")
                        .contextMenu {
                            Button("Remove") {
                                favorites.removeAll { $0 == favUrl }
                                UserDefaults.standard.set(favorites, forKey: "orionFavorites_Eng")
                            }
                        }
                    }
                }
                Spacer(minLength: 10)
            }
            .padding(.vertical, 8)
            .background(VisualEffectBlur(material: .headerView, blendingMode: .withinWindow))
            
            Divider()
            
            ZStack {
                WebView(webView: $webView, urlString: $urlString, zoomLevel: $zoomLevel, favorites: $favorites)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                if urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    FavoritesGridView(favorites: $favorites) { selectedUrl in
                        urlString = selectedUrl
                        loadURL()
                    }
                }

                Button("") { zoomLevel += 0.15 }.keyboardShortcut("+", modifiers: .command).opacity(0)
                Button("") { zoomLevel -= 0.15 }.keyboardShortcut("-", modifiers: .command).opacity(0)
                Button("") { zoomLevel = 1.0 }.keyboardShortcut("0", modifiers: .command).opacity(0)
                Button("") { webView.reload() }.keyboardShortcut("r", modifiers: .command).opacity(0)
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .onAppear {
            setupAdBlocker {
                loadURL()
            }
        }
    }

    func loadURL() {
        var str = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.isEmpty {
            webView.loadHTMLString("<html><body style='background-color: #1a1a1a;'></body></html>", baseURL: nil)
            return
        }
        if !str.hasPrefix("http://") && !str.hasPrefix("https://") { str = "https://" + str }
        if let url = URL(string: str) {
            webView.load(URLRequest(url: url))
        }
    }
    
    func openNewWindow(url: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView(initialUrl: url))
        window.makeKeyAndOrderFront(nil)
    }
    
    func toggleFavorite() {
        if isFavorite {
            favorites.removeAll { $0 == urlString }
        } else {
            favorites.append(urlString)
        }
        UserDefaults.standard.set(favorites, forKey: "orionFavorites_Eng")
    }
    
    func setupAdBlocker(completion: @escaping () -> Void) {
        // Extended Rule List: Mutes trackers and memory sapping telemetry scripts at the network layer itself!
        let ruleList = """
        [
            { 
                "trigger": { 
                    "url-filter": ".*(google-analytics|googletagmanager|amplitude|hotjar|mixpanel|sentry|yandex\\\\.ru/metrika|facebook\\\\.com/tr|mc\\\\.yandex|doubleclick|adservices|googlesyndication|criteo|yandex\\\\.ru/ads|adriver|relap|tns-counter|top-fwz1|traffic|adocean|pubmatic).*",
                    "unless-domain": ["twitch.tv", "ttvnw.net", "jtvnw.net", "rezka.ag", "hdrezka.ag", "voidboost.net"]
                }, 
                "action": { "type": "block" } 
            }
        ]
        """
        
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "SniperAdBlock", encodedContentRuleList: ruleList) { rules, error in
            DispatchQueue.main.async { 
                if let rules = rules {
                    self.webView.configuration.userContentController.add(rules) 
                }
                
                let scriptSource = """
                    // Safe Autoplay Blocker: prevent modern SPAs (Twitch) from panicking when WebKit blocks autoplay
                    const _origPlay = HTMLMediaElement.prototype.play;
                    HTMLMediaElement.prototype.play = function() {
                        const promise = _origPlay.apply(this, arguments);
                        if (promise !== undefined) {
                            promise.catch(err => {
                                if (err.name === 'NotAllowedError') {
                                    // Soft-swallow Safari's autoplay rejection to stop 'Unhandled Promise Rejection' crashes
                                    console.log('Orion: Autoplay halted safely.');
                                }
                            });
                        }
                        return promise;
                    };

                    if (window.location.hostname.includes('rezka.ag') || window.location.hostname.includes('hdrezka')) {
                        var style = document.createElement('style');
                        style.innerHTML = `
                            /* Strip banners on Rezka */
                            html, body {
                                background-image: none !important; 
                                background-color: #1a1a1a !important; 
                                padding-top: 0 !important; 
                                margin-top: 0 !important;
                            }
                            .b-wrapper, .b-container, #main { 
                                padding-top: 0 !important; 
                                margin-top: 0 !important; 
                            }
                            /* Kill primary banners */
                            .b-top-banner, .b-post__promoblock, .promoblock { 
                                display: none !important; 
                            }
                            a[href*="1xbet"], a[href*="casino"], a[href*="bet"] { 
                                display: none !important; pointer-events: none !important; opacity: 0 !important; 
                            }
                        `;
                        if (document.documentElement) {
                            document.documentElement.appendChild(style);
                        }
                        
                        // Extremely optimal DOM Popup Killer built on Passive MutationObservers (0 CPU when Idle)
                        const checkNode = (el) => {
                            if (el.nodeType !== 1) return;
                            const st = window.getComputedStyle(el);
                            if (st.position === 'fixed' && (st.zIndex == '2147483647' || parseInt(st.bottom) <= 50)) {
                                if (st.height !== '100%' && el.offsetHeight < 200) {
                                    el.style.display = 'none';
                                }
                            }
                        };
                        
                        // First sweep on page load
                        document.querySelectorAll('div, a').forEach(checkNode);
                        
                        // Passive watcher for newly injected ad-nodes
                        const observer = new MutationObserver((mutations) => {
                            mutations.forEach(m => {
                                m.addedNodes.forEach(node => {
                                    if (node.nodeType === 1) { // ELEMENT_NODE
                                        if (node.tagName === 'DIV' || node.tagName === 'A') checkNode(node);
                                        // Sweep nested items if it's a giant container
                                        node.querySelectorAll('div, a').forEach(checkNode);
                                    }
                                });
                            });
                        });
                        if (document.body) observer.observe(document.body, { childList: true, subtree: true });
                    }
                    
                    // --- TWITCH NATIVE INJECTION ---
                    if (window.location.hostname.includes('twitch.tv')) {
                        const style = document.createElement('style');
                        style.innerHTML = `
                            /* Hide Twitch More (3-dots) globally */
                            [data-a-target="top-nav-more-button"],
                            button[aria-label="More"],
                            button[aria-label="Больше"],
                            button[aria-label="Más"] {
                                display: none !important;
                            }
                            
                            .orion-star-btn {
                                z-index: 1000;
                                cursor: pointer;
                                font-size: 16px;
                                padding: 0 4px;
                                margin-left: 2px;
                                margin-right: 4px;
                                transition: 0.2s;
                                color: #ccc;
                                display: flex;
                                align-items: center;
                                justify-content: center;
                            }
                            .orion-star-btn:hover { color: #F5C518; transform: scale(1.2); }
                        `;
                        if (document.documentElement) document.documentElement.appendChild(style);
                        
                        const twObserver = new MutationObserver(() => {
                            // Find Sidebar items
                            document.querySelectorAll('a[data-a-target="side-nav-card-link"], a[data-test-selector="followed-channel"]').forEach(link => {
                                if (link.dataset.orionUi) return;
                                link.dataset.orionUi = 'true';
                                
                                const btn = document.createElement('div');
                                btn.className = 'orion-star-btn';
                                btn.innerText = '☆';
                                btn.title = 'Add to Orion Favorites';
                                btn.onclick = (e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    if (window.webkit && window.webkit.messageHandlers.orionInterop) {
                                        window.webkit.messageHandlers.orionInterop.postMessage({action: 'toggleFavorite', url: link.href});
                                    }
                                    btn.innerText = '⭐'; 
                                    btn.style.transform = 'scale(1.4)';
                                    setTimeout(() => btn.style.transform = 'scale(1)', 200);
                                };
                                // Prepend places it cleanly on the very left via flex layout without absolute position overlaps!
                                link.prepend(btn);
                            });
                            
                            // Rename Twitch's 'For You' header
                            document.querySelectorAll('.tw-title, h2, h5').forEach(h => {
                                if (h.innerText.includes('For You') || h.innerText.includes('Рекомендуемые')) {
                                    h.innerText = 'Orion Favorites';
                                    h.style.color = '#F5C518';
                                }
                            });
                        });
                        if (document.body) twObserver.observe(document.body, { childList: true, subtree: true });
                    }
                """
                let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                self.webView.configuration.userContentController.removeAllUserScripts()
                self.webView.configuration.userContentController.addUserScript(script)
                
                completion()
            }
        }
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct WebView: NSViewRepresentable {
    @Binding var webView: WKWebView
    @Binding var urlString: String
    @Binding var zoomLevel: CGFloat
    @Binding var favorites: [String]
    
    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.configuration.userContentController.add(context.coordinator, name: "orionInterop")
        return webView
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.pageZoom != zoomLevel {
            nsView.pageZoom = zoomLevel
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView
        var urlObservation: NSKeyValueObservation?
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "orionInterop",
                  let dict = message.body as? [String: String],
                  let action = dict["action"],
                  var urlStr = dict["url"] else { return }
            
            if action == "toggleFavorite" {
                if !urlStr.hasPrefix("http") { urlStr = "https://www.twitch.tv" + urlStr }
                DispatchQueue.main.async {
                    if let idx = self.parent.favorites.firstIndex(of: urlStr) {
                        self.parent.favorites.remove(at: idx)
                    } else {
                        self.parent.favorites.append(urlStr)
                    }
                    UserDefaults.standard.set(self.parent.favorites, forKey: "orionFavorites_Eng")
                }
            }
        }
        
        init(_ parent: WebView) { 
            self.parent = parent 
            super.init()
            self.urlObservation = parent.webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                if let newUrl = webView.url?.absoluteString, newUrl != "about:blank" {
                    DispatchQueue.main.async { self?.parent.urlString = newUrl }
                }
            }
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url?.absoluteString, url != "about:blank" { parent.urlString = url }
        }
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Only open link-activated popups to prevent auto-redirects from hidden iframe initializations.
            if let url = navigationAction.request.url {
                 if navigationAction.navigationType == .linkActivated {
                    webView.load(URLRequest(url: url))
                 }
            }
            return nil
        }
    }
}

struct MiddleClickLayer: NSViewRepresentable {
    var onLeftClick: () -> Void
    var onMiddleClick: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = MouseTrackingView()
        view.onLeftClick = onLeftClick
        view.onMiddleClick = onMiddleClick
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class MouseTrackingView: NSView {
    var onLeftClick: (() -> Void)?
    var onMiddleClick: (() -> Void)?
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Intercept clicks directly
        return self.bounds.contains(point) ? self : nil
    }
    
    override func mouseUp(with event: NSEvent) {
        onLeftClick?()
    }
    
    override func otherMouseUp(with event: NSEvent) {
        if event.buttonNumber == 2 {
            onMiddleClick?()
        } else {
            super.otherMouseUp(with: event)
        }
    }
}

struct FavoritesGridView: View {
    @Binding var favorites: [String]
    var onSelect: (String) -> Void
    
    let columns = [GridItem(.adaptive(minimum: 140, maximum: 160), spacing: 20)]
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.1).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 30) {
                    Text("Favorites")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 60)
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(favorites, id: \.self) { favUrl in
                            Button(action: { onSelect(favUrl) }) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.08))
                                            .frame(width: 80, height: 80)
                                        
                                        AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=128&domain_url=\(favUrl)")) { image in
                                            image.resizable().aspectRatio(contentMode: .fit)
                                        } placeholder: { Color.gray.opacity(0.3) }
                                        .frame(width: 48, height: 48)
                                        .cornerRadius(8)
                                    }
                                    
                                    VStack(spacing: 2) {
                                        Text(URL(string: favUrl)?.host?.replacingOccurrences(of: "www.", with: "") ?? favUrl)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(1)
                                        
                                        if let path = URL(string: favUrl)?.path, path.count > 1 {
                                            Text(path)
                                                .font(.system(size: 11))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
    }
}
