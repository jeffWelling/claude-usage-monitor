import Foundation

// MARK: - Token Data Point

struct TokenDataPoint: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let inputTokens: Int
    let outputTokens: Int

    var totalTokens: Int {
        inputTokens + outputTokens
    }
}

// MARK: - Claude Log Structures

/// Structure for ~/.claude/stats-cache.json
struct StatsCacheFile: Codable {
    let version: Int?
    let lastComputedDate: String?
    let dailyModelTokens: [DailyModelTokens]?
    let dailyActivity: [DailyActivity]?
}

struct DailyModelTokens: Codable {
    let date: String
    let tokensByModel: [String: Int]
}

struct DailyActivity: Codable {
    let date: String
    let messageCount: Int?
    let sessionCount: Int?
    let toolCallCount: Int?
}

/// Structure for JSONL session files
struct SessionMessage: Codable {
    let type: String?
    let timestamp: String?
    let message: MessageContent?
    let costUSD: Double?
    let durationMs: Int?
}

struct MessageContent: Codable {
    let role: String?
    let usage: TokenUsage?
}

struct TokenUsage: Codable {
    let input_tokens: Int?
    let output_tokens: Int?
    let cache_creation_input_tokens: Int?
    let cache_read_input_tokens: Int?
}
