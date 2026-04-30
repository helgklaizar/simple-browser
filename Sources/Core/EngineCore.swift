import WebKit

class EngineCore {
    static let sharedProcessPool = WKProcessPool()
    
    static func cleanHeavyCacheData() {
        var typesToClean = WKWebsiteDataStore.allWebsiteDataTypes()
        typesToClean.remove(WKWebsiteDataTypeCookies)
        typesToClean.remove(WKWebsiteDataTypeWebSQLDatabases)
        typesToClean.remove(WKWebsiteDataTypeIndexedDBDatabases)
        typesToClean.remove(WKWebsiteDataTypeLocalStorage)
        typesToClean.remove(WKWebsiteDataTypeSessionStorage)
        
        WKWebsiteDataStore.default().removeData(ofTypes: typesToClean, modifiedSince: Date.distantPast) {
            print("Orion Engine: Cleared unused background cache arrays successfully.")
        }
    }
}
