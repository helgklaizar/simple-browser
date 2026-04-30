import SwiftUI

@main
struct AWVApp: App {
    init() {
        EngineCore.cleanHeavyCacheData()
    }
    
    var body: some Scene {
        WindowGroup("AWV") {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
