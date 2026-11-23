import Foundation

/// Fast local preference storage for the DeepSeek API key.
/// Uses standard UserDefaults with thread-safe in-memory caching to avoid annoying macOS Keychain OS security dialogs.
public struct KeychainHelper: Sendable {
    private static let userDefaultsKey = "com.lucent.deepeak.stored_api_key"
    private static let lock = NSLock()
    private nonisolated(unsafe) static var cachedKey: String? = nil

    @discardableResult
    public static func saveApiKey(_ apiKey: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        cachedKey = apiKey
        if let data = apiKey.data(using: .utf8) {
            let base64 = data.base64EncodedString()
            UserDefaults.standard.set(base64, forKey: userDefaultsKey)
            return true
        }
        return false
    }

    public static func loadApiKey() -> String? {
        lock.lock()
        defer { lock.unlock() }
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
    public static func deleteApiKey() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        cachedKey = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        return true
    }

    /// Clears the in-memory cache without removing the key from UserDefaults.
    public static func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedKey = nil
    }
}
