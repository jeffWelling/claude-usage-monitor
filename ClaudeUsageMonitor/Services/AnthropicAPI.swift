import Foundation

actor AnthropicAPI {
    static let shared = AnthropicAPI()

    private let baseURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private var credentialManager: CredentialManager { CredentialManager.shared }

    private init() {}

    // App identification
    private let appVersion = "1.0.0"
    private let userAgent = "claude-usage-monitor/1.0.0 (+https://github.com/jeffWelling/claude-usage-monitor)"

    // Required beta header for OAuth usage endpoint.
    // This may need updating if Anthropic changes their API requirements.
    // Check Claude Code releases for updates: https://github.com/anthropics/claude-code
    private let oauthBetaHeader = "oauth-2025-04-20"

    // Track if token is known to be expired to avoid repeated keychain prompts
    private var tokenKnownExpired = false

    enum APIError: Error, LocalizedError {
        case invalidResponse
        case httpError(Int)
        case tokenExpired
        case networkError(Error)
        case decodingError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from API."
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .tokenExpired:
                return "Token expired. Start a Claude Code session to refresh."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            }
        }
    }

    /// Reset the expired token flag - call when user manually refreshes
    func resetTokenState() {
        tokenKnownExpired = false
    }

    func fetchUsage() async throws -> UsageResponse {
        // If token is known to be expired, fail immediately without prompting keychain
        if tokenKnownExpired {
            throw APIError.tokenExpired
        }

        // Try with cached token first
        do {
            let result = try await performFetch(forceTokenRefresh: false)
            return result
        } catch APIError.tokenExpired {
            // Token expired - refresh from keychain and retry once
            do {
                let result = try await performFetch(forceTokenRefresh: true)
                return result
            } catch APIError.tokenExpired {
                // Still expired after refresh - mark as known expired to avoid future prompts
                tokenKnownExpired = true
                throw APIError.tokenExpired
            }
        }
    }

    private func performFetch(forceTokenRefresh: Bool) async throws -> UsageResponse {
        let token = try await credentialManager.getAccessToken(forceRefresh: forceTokenRefresh)

        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(oauthBetaHeader, forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            // Success - clear the expired flag in case it was set
            tokenKnownExpired = false
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
            do {
                return try decoder.decode(UsageResponse.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.tokenExpired
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}
