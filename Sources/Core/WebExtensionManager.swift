import WebKit
import Combine

@available(macOS 14.0, *)
@MainActor
class WebExtensionManager: ObservableObject {
    static let shared = WebExtensionManager()
    let controller = WKWebExtensionController()
    
    @Published var loadedExtensions: [String] = []
    
    func loadExtension(from url: URL) {
        Task { @MainActor in
            do {
                let webExtension = try await WKWebExtension(resourceBaseURL: url)
                let context = WKWebExtensionContext(for: webExtension)
                try self.controller.load(context)
                
                let extName = context.webExtension.displayName ?? url.lastPathComponent
                self.loadedExtensions.append(extName)
                print("Extension loaded successfully: \\(extName)")
            } catch {
                print("Failed to load extension: \\(error)")
            }
        }
    }
}
