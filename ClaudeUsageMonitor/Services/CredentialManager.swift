import Foundation
import Security

actor CredentialManager {
    // Singleton ensures all keychain access is serialized through one actor
    static let shared = CredentialManager()

    enum CredentialError: Error, LocalizedError {
        case keychainItemNotFound
        case keychainError(OSStatus)
        case jsonParsingFailed
        case tokenNotFound

        var errorDescription: String? {
            switch self {
            case .keychainItemNotFound:
                return "Claude Code credentials not found. Please ensure Claude Code is installed and logged in."
            case .keychainError(let status):
                let message = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
                return "Keychain error: \(message) (\(status))"
            case .jsonParsingFailed:
                return "Failed to parse credentials JSON."
            case .tokenNotFound:
                return "OAuth token not found in credentials."
            }
        }
    }

    private let serviceName = "Claude Code-credentials"
    private var cachedToken: String?

    private init() {}

    func getAccessToken(forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh, let token = cachedToken {
            return token
        }

        let token = try fetchTokenFromKeychain()
        cachedToken = token
        return token
    }

    private func fetchTokenFromKeychain() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: NSUserName(),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw CredentialError.keychainItemNotFound
        default:
            throw CredentialError.keychainError(status)
        }

        guard let data = result as? Data,
              let jsonString = String(data: data, encoding: .utf8) else {
            throw CredentialError.jsonParsingFailed
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let claudeAiOauth = json["claudeAiOauth"] as? [String: Any],
              let accessToken = claudeAiOauth["accessToken"] as? String else {
            throw CredentialError.tokenNotFound
        }

        return accessToken
    }
}
