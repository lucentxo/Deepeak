import Foundation

/// Fast local preference storage for the DeepSeek API key.
/// Uses standard UserDefaults with in-memory caching to avoid annoying macOS Keychain OS security dialogs.
struct KeychainHelper {
    private static let userDefaultsKey = "com.lucent.deepeak.stored_api_key"
    private static var cachedKey: String? = nil

    @discardableResult
    static func saveApiKey(_ apiKey: String) -> Bool {
        cachedKey = apiKey
        if let data = apiKey.data(using: .utf8) {
            let base64 = data.base64EncodedString()
            UserDefaults.standard.set(base64, forKey: userDefaultsKey)
            return true
        }
        return false
    }

    static func loadApiKey() -> String? {
        if let cached = cachedKey {
            return cached
        }
        guard let base64 = UserDefaults.standard.string(forKey: userDefaultsKey),
              let data = Data(base64Encoded: base64),
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        cachedKey = key
        return key
    }

    @discardableResult
    static func deleteApiKey() -> Bool {
        cachedKey = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        return true
    }
}
