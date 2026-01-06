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
                return "Creds not found, please login"
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
    private var lastKeychainAccess: Date?
    private let keychainThrottleSeconds: TimeInterval = 30  // Minimum time between keychain prompts

    private init() {}

    /// Clear the cached token - forces next fetch to go to keychain
    func clearCache() {
        cachedToken = nil
    }

    /// Reset throttle to allow immediate keychain access (for manual refresh)
    func resetThrottle() {
        lastKeychainAccess = nil
    }

    func getAccessToken(forceRefresh: Bool = false) async throws -> String {
        // Return cached token if available and not forcing refresh
        if !forceRefresh, let token = cachedToken {
            return token
        }

        // Throttle keychain access to prevent continuous prompting
        if let lastAccess = lastKeychainAccess {
            let elapsed = Date().timeIntervalSince(lastAccess)
            if elapsed < keychainThrottleSeconds {
                // Too soon - throw error instead of prompting again
                throw CredentialError.keychainItemNotFound
            }
        }

        lastKeychainAccess = Date()
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

        // Try JSON parsing first
        if let jsonData = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let claudeAiOauth = json["claudeAiOauth"] as? [String: Any],
           let accessToken = claudeAiOauth["accessToken"] as? String {
            return accessToken
        }

        // JSON parsing failed (possibly truncated) - extract token via regex
        // Pattern: "claudeAiOauth":{"accessToken":"<token>"
        if let token = extractTokenViaRegex(from: jsonString) {
            return token
        }

        throw CredentialError.tokenNotFound
    }

    /// Extract OAuth token from potentially truncated JSON using regex
    /// Handles cases where the JSON is truncated due to many MCP servers
    private func extractTokenViaRegex(from jsonString: String) -> String? {
        // Match: "claudeAiOauth":{"accessToken":"<captured_token>"
        // The token continues until the next unescaped quote
        let pattern = #""claudeAiOauth"\s*:\s*\{\s*"accessToken"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)""#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: jsonString, options: [], range: NSRange(jsonString.startIndex..., in: jsonString)),
              let tokenRange = Range(match.range(at: 1), in: jsonString) else {
            return nil
        }

        let token = String(jsonString[tokenRange])

        // Unescape any escaped characters in the token
        return token.replacingOccurrences(of: "\\\"", with: "\"")
                    .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
