import Combine
import Foundation
import Security

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var sessionKey: String?
    @Published private(set) var username: String?

    private let service = "memor.LastFM.SessionKey"
    private let account = "LastFM"
    private let usernameKey = "lastfm.username"

    var isAuthenticated: Bool {
        sessionKey != nil
    }

    init() {
        sessionKey = Self.readKeychainValue(service: service, account: account)
        username = UserDefaults.standard.string(forKey: usernameKey)
    }

    func signIn(session: LastFMSession) {
        Self.saveKeychainValue(session.key, service: service, account: account)
        UserDefaults.standard.set(session.username, forKey: usernameKey)
        sessionKey = session.key
        username = session.username
    }

    func signOut() {
        Self.deleteKeychainValue(service: service, account: account)
        UserDefaults.standard.removeObject(forKey: usernameKey)
        sessionKey = nil
        username = nil
    }

    private nonisolated static func readKeychainValue(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private nonisolated static func saveKeychainValue(_ value: String, service: String, account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let update: [String: Any] = [kSecValueData as String: data]
        if SecItemUpdate(query as CFDictionary, update as CFDictionary) != errSecSuccess {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    private nonisolated static func deleteKeychainValue(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
