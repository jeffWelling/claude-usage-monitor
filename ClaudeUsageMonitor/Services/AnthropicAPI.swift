import Foundation

actor AnthropicAPI {
    private let baseURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let credentialManager = CredentialManager()

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
                return "Token expired. Please restart Claude Code."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            }
        }
    }

    func fetchUsage() async throws -> UsageResponse {
        let token = try await credentialManager.getAccessToken()

        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("claude-code/2.0.31", forHTTPHeaderField: "User-Agent")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
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
