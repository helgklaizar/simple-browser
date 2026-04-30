import SwiftUI
import WebKit

struct ContentView: View {
    @State private var urlString: String
    @State private var zoomLevel: CGFloat = 1.0
    @ObservedObject private var store = FavoritesStore.shared
    
    @State private var webView: WKWebView
    @State private var isBlockersEnabled: Bool = true
    @State private var isZapperActive: Bool = false
    @State private var zapperScriptInjected = false
    @State private var isMouseInsideWindow: Bool = true
    
    init(initialUrl: String = "", preloadedWebView: WKWebView? = nil) {
        _urlString = State(initialValue: initialUrl)
        
        if let preloaded = preloadedWebView {
            _webView = State(initialValue: preloaded)
        } else {
            let prefs = WKPreferences()
            prefs.isFraudulentWebsiteWarningEnabled = false
            prefs.javaScriptCanOpenWindowsAutomatically = true

            let config = WKWebViewConfiguration()
            config.processPool = EngineCore.sharedProcessPool
            config.preferences = prefs
            config.mediaTypesRequiringUserActionForPlayback = []
            config.allowsAirPlayForMediaPlayback = true
            
            if #available(macOS 14.0, *) {
                config.webExtensionController = WebExtensionManager.shared.controller
            }
            
            let wv = WKWebView(frame: .zero, configuration: config)
            wv.allowsBackForwardNavigationGestures = true
            wv.allowsMagnification = true
            wv.setValue(false, forKey: "drawsBackground")
            _webView = State(initialValue: wv)
        }
    }
    
    var isFavorite: Bool {
        store.items.contains(urlString) || store.items.contains(urlString + "/")
    }
    
    let memSweepTimer = Timer.publish(every: 600, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            if isMouseInsideWindow {
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
                            
                            Button(action: { 
                                if #available(macOS 14.0, *) {
                                    let panel = NSOpenPanel()
                                    panel.canChooseFiles = false
                                    panel.canChooseDirectories = true
                                    panel.allowsMultipleSelection = false
                                    panel.message = "Select the Extension Folder (must contain manifest.json)"
                                    if panel.runModal() == .OK, let url = panel.url {
                                        WebExtensionManager.shared.loadExtension(from: url)
                                    }
                                }
                            }) {
                                Image(systemName: "puzzlepiece.extension")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Load Web Extension")
                            
                            Button(action: { toggleZapper() }) {
                                Image(systemName: isZapperActive ? "viewfinder.circle.fill" : "viewfinder.circle")
                                    .foregroundColor(isZapperActive ? .red : .primary)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Block Element (Manual Zap)")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(width: 350)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(6)
                        
                        Divider().frame(height: 14)
                        
                        HStack(spacing: 12) {
                            ForEach(store.items, id: \.self) { favUrl in
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
                                        WindowFactory.createBorderlessWindow(url: favUrl) { url in ContentView(initialUrl: url) }
                                    })
                                }
                                .frame(width: 20, height: 20)
                                .help("\(FavoritesStore.fallbackTitle(for: favUrl)) (Middle-click for New Window)")
                                .contextMenu {
                                    Button("Remove") {
                                        store.items.removeAll { $0 == favUrl }
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 10)
                    }
                    .padding(.vertical, 8)
                    .background(VisualEffectBlur(material: .headerView, blendingMode: .withinWindow))
                    
                    Divider()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            ZStack {
                WebView(webView: $webView, urlString: $urlString, zoomLevel: $zoomLevel, isZapperActive: $isZapperActive)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                
                if urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    FavoritesGridView(favorites: $store.items) { url in
                        urlString = url
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
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.25)) {
                isMouseInsideWindow = hovering
            }
        }
        .onAppear {
            setupAdBlocker {
                loadURL()
            }
        }
        .onReceive(memSweepTimer) { _ in
            EngineCore.cleanHeavyCacheData()
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
    
    func toggleFavorite() {
        if isFavorite {
            store.items.removeAll { $0 == urlString || $0 == urlString + "/" }
        } else {
            store.items.append(urlString)
        }
    }
    
    func toggleZapper() {
        isZapperActive.toggle()
        if !zapperScriptInjected {
            webView.evaluateJavaScript(JSInjectionCore.zapperScript)
            zapperScriptInjected = true
        }
        webView.evaluateJavaScript("window._isZapping = \(isZapperActive ? "true" : "false");")
    }
    
    func setupAdBlocker(completion: @escaping () -> Void) {
        self.webView.configuration.userContentController.removeAllContentRuleLists()
        self.webView.configuration.userContentController.removeAllUserScripts()
        
        if !isBlockersEnabled {
            completion()
            return
        }
        
        var ruleList = "[]"
        if let path = Bundle.main.path(forResource: "adblock_rules", ofType: "json"),
           let content = try? String(contentsOfFile: path) {
            ruleList = content
            print("Orion Engine: Successfully loaded \\(content.count) bytes of DNR rules.")
        } else {
            print("Orion Engine: Warning - adblock_rules.json not found in Bundle, using internal fallback.")
            ruleList = """
            [
                { "trigger": { "url-filter": ".*(google-analytics|yandex|1xbet|popunder|kinopub).*" }, "action": { "type": "block" } }
            ]
            """
        }
        
        let ruleId = "SniperAdBlock-\(UUID().uuidString)"
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: ruleId, encodedContentRuleList: ruleList) { rules, error in
            if let error = error { print("Orion Engine Error compiling rules: \\(error)") }
            DispatchQueue.main.async { 
                if let rules = rules {
                    self.webView.configuration.userContentController.add(rules) 
                }
                
                let script = WKUserScript(source: JSInjectionCore.scriptletsCore, injectionTime: .atDocumentStart, forMainFrameOnly: false)
                self.webView.configuration.userContentController.removeAllUserScripts()
                self.webView.configuration.userContentController.addUserScript(script)
                
                completion()
            }
        }
    }
}
