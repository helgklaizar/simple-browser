import WebKit
import SwiftUI

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    var parent: WebView
    var urlObservation: NSKeyValueObservation?
    var titleObservation: NSKeyValueObservation?
    
    init(_ parent: WebView) { 
        self.parent = parent 
        super.init()
        self.urlObservation = parent.webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
            if let newUrl = webView.url?.absoluteString, newUrl != "about:blank" {
                DispatchQueue.main.async { self?.parent.urlString = newUrl }
            }
        }
        self.titleObservation = parent.webView.observe(\.title, options: [.new]) { webView, _ in
            DispatchQueue.main.async {
                if let newTitle = webView.title, !newTitle.isEmpty {
                    webView.window?.title = newTitle
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString, url != "about:blank" { parent.urlString = url }
        
        for subview in webView.subviews {
            if let scrollView = subview as? NSScrollView {
                scrollView.autohidesScrollers = true
                scrollView.scrollerStyle = .overlay
                scrollView.hasVerticalScroller = false
                scrollView.hasHorizontalScroller = false
            }
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let newWebView = WKWebView(frame: .zero, configuration: configuration)
        newWebView.uiDelegate = self
        
        DispatchQueue.main.async {
            let targetURL = navigationAction.request.url?.absoluteString ?? ""
            WindowFactory.createBorderlessWindow(url: targetURL) { url in
                ContentView(initialUrl: url, preloadedWebView: newWebView)
            }
        }
        
        return newWebView
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "zapComplete" {
            DispatchQueue.main.async { self.parent.isZapperActive = false }
        }
    }
}
