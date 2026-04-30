import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    @Binding var webView: WKWebView
    @Binding var urlString: String
    @Binding var zoomLevel: CGFloat
    @Binding var isZapperActive: Bool
    
    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.configuration.userContentController.add(context.coordinator, name: "zapComplete")
        
        DispatchQueue.main.async {
            if let scrollView = webView.enclosingScrollView {
                scrollView.autohidesScrollers = true
                scrollView.scrollerStyle = .overlay
                scrollView.hasVerticalScroller = false
                scrollView.hasHorizontalScroller = false
            }
            for subview in webView.subviews {
                if let scrollView = subview as? NSScrollView {
                    scrollView.autohidesScrollers = true
                    scrollView.scrollerStyle = .overlay
                    scrollView.hasVerticalScroller = false
                    scrollView.hasHorizontalScroller = false
                }
            }
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.pageZoom != zoomLevel {
            nsView.pageZoom = zoomLevel
        }
    }
    
    func makeCoordinator() -> WebViewCoordinator { 
        WebViewCoordinator(self) 
    }
}
