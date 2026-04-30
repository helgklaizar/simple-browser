import SwiftUI

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
