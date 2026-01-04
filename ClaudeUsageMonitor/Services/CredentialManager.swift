import Foundation

actor CredentialManager {
    enum CredentialError: Error, LocalizedError {
        case keychainItemNotFound
        case jsonParsingFailed
        case tokenNotFound
        case processError(Int32)

        var errorDescription: String? {
            switch self {
            case .keychainItemNotFound:
                return "Claude Code credentials not found. Please ensure Claude Code is installed and logged in."
            case .jsonParsingFailed:
                return "Failed to parse credentials JSON."
            case .tokenNotFound:
                return "OAuth token not found in credentials."
            case .processError(let code):
                return "Security command failed with code \(code)."
            }
        }
    }

    func getAccessToken() async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = [
            "find-generic-password",
            "-a", NSUserName(),
            "-w",
            "-s", "Claude Code-credentials"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CredentialError.keychainItemNotFound
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let jsonString = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) else {
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
