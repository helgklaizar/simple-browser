import Foundation

class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()
    @Published var items: [String] = UserDefaults.standard.stringArray(forKey: "orionFavorites_Eng") ?? [] {
        didSet {
            UserDefaults.standard.set(items, forKey: "orionFavorites_Eng")
        }
    }
    
    static func fallbackTitle(for url: String) -> String {
        guard let u = URL(string: url), let host = u.host else { return url }
        let cleanHost = host.replacingOccurrences(of: "www.", with: "")
        if u.path.count > 1 && u.path != "/" {
            let last = u.lastPathComponent.replacingOccurrences(of: ".html", with: "").replacingOccurrences(of: "-", with: " ").capitalized
            return "\(cleanHost) - \(last)"
        }
        return cleanHost
    }
}
