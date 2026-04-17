import SwiftUI
import WebKit

@main
struct MiniOrionApp: App {
    var body: some Scene {
        WindowGroup("Mini Orion") {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

struct ContentView: View {
    @State private var urlString: String = ""
    @State private var zoomLevel: CGFloat = 1.0
    
    @State private var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
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
                
                HStack(spacing: 10) {
                    ForEach(favorites, id: \.self) { favUrl in
                        Button(action: { urlString = favUrl; loadURL() }) {
                            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=64&domain_url=\(favUrl)")) { image in
                                image.resizable()
                            } placeholder: { Color.gray.opacity(0.3) }
                            .frame(width: 16, height: 16)
                            .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Open \(favUrl)")
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
                WebView(webView: $webView, urlString: $urlString, zoomLevel: $zoomLevel)
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
    
    func toggleFavorite() {
        if isFavorite {
            favorites.removeAll { $0 == urlString }
        } else {
            favorites.append(urlString)
        }
        UserDefaults.standard.set(favorites, forKey: "orionFavorites_Eng")
    }
    
    func setupAdBlocker(completion: @escaping () -> Void) {
        let ruleList = """
        [
            { 
                "trigger": { 
                    "url-filter": ".*(doubleclick|adservices|googlesyndication|criteo|yandex\\\\.ru/ads|mc\\\\.yandex|adriver|relap|tns-counter|top-fwz1|traffic|adocean|pubmatic).*",
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
                        
                        setInterval(() => {
                            // Kill popups
                            document.querySelectorAll('div, a').forEach(el => {
                                const st = window.getComputedStyle(el);
                                if (st.position === 'fixed' && (st.zIndex == '2147483647' || parseInt(st.bottom) <= 50)) {
                                    if (st.height !== '100%' && el.offsetHeight < 200) {
                                        el.style.display = 'none';
                                    }
                                }
                            });
                        }, 1000);
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
    
    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        let prefs = WKPreferences()
        prefs.isFraudulentWebsiteWarningEnabled = false
        prefs.javaScriptCanOpenWindowsAutomatically = false
        webView.configuration.preferences = prefs
        return webView
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.pageZoom != zoomLevel {
            nsView.pageZoom = zoomLevel
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        var urlObservation: NSKeyValueObservation?
        
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
