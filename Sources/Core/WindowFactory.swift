import SwiftUI

class WindowFactory {
    static func createBorderlessWindow<Content: View>(title: String = "AWV Window", url: String = "", root: (String) -> Content) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.collectionBehavior = .fullScreenPrimary
        window.setFrameAutosaveName(title)
        window.isReleasedWhenClosed = true
        window.contentView = NSHostingView(rootView: root(url))
        window.makeKeyAndOrderFront(nil)
    }
}
