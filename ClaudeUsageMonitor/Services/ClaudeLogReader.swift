import Foundation

actor ClaudeLogReader {
    static let shared = ClaudeLogReader()

    private let claudeDir: URL
    private let projectsDir: URL
    private let statsCachePath: URL

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.claudeDir = home.appendingPathComponent(".claude")
        self.projectsDir = claudeDir.appendingPathComponent("projects")
        self.statsCachePath = claudeDir.appendingPathComponent("stats-cache.json")
    }

    // MARK: - Public API

    /// Fetch token history for the specified time window
    func fetchHistory(windowHours: Double) async -> [TokenDataPoint] {
        let cutoffDate = Date().addingTimeInterval(-windowHours * 3600)

        // For windows <= 24 hours, use JSONL files for per-message granularity
        if windowHours <= 24 {
            return await fetchFromJSONL(since: cutoffDate)
        } else {
            // For longer windows, use daily aggregates from stats-cache.json
            return await fetchFromStatsCache(since: cutoffDate)
        }
    }

    // MARK: - Stats Cache Parsing

    private func fetchFromStatsCache(since cutoffDate: Date) async -> [TokenDataPoint] {
        guard let data = try? Data(contentsOf: statsCachePath),
              let statsCache = try? JSONDecoder().decode(StatsCacheFile.self, from: data),
              let dailyTokens = statsCache.dailyModelTokens else {
            return []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        var dataPoints: [TokenDataPoint] = []

        for entry in dailyTokens {
            guard let date = dateFormatter.date(from: entry.date),
                  date >= cutoffDate else {
                continue
            }

            // Sum all models for this day
            let totalTokens = entry.tokensByModel.values.reduce(0, +)

            // We only have total tokens from stats-cache, split roughly 40/60 input/output
            let estimatedInput = Int(Double(totalTokens) * 0.4)
            let estimatedOutput = totalTokens - estimatedInput

            dataPoints.append(TokenDataPoint(
                timestamp: date,
                inputTokens: estimatedInput,
                outputTokens: estimatedOutput
            ))
        }

        return dataPoints.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - JSONL Parsing

    private func fetchFromJSONL(since cutoffDate: Date) async -> [TokenDataPoint] {
        var dataPoints: [TokenDataPoint] = []

        // Find all JSONL files in projects directory
        let jsonlFiles = findJSONLFiles()

        for fileURL in jsonlFiles {
            let points = await parseJSONLFile(fileURL, since: cutoffDate)
            dataPoints.append(contentsOf: points)
        }

        // Sort by timestamp and aggregate into time buckets (5-minute intervals)
        return aggregateIntoTimeBuckets(dataPoints, bucketMinutes: 5)
    }

    private func findJSONLFiles() -> [URL] {
        guard FileManager.default.fileExists(atPath: projectsDir.path) else {
            return []
        }

        var jsonlFiles: [URL] = []
        let enumerator = FileManager.default.enumerator(
            at: projectsDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "jsonl" {
                jsonlFiles.append(fileURL)
            }
        }

        return jsonlFiles
    }

    private func parseJSONLFile(_ fileURL: URL, since cutoffDate: Date) async -> [TokenDataPoint] {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }

        var dataPoints: [TokenDataPoint] = []
        let lines = content.components(separatedBy: .newlines)
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for line in lines where !line.isEmpty {
            guard let data = line.data(using: .utf8),
                  let message = try? JSONDecoder().decode(SessionMessage.self, from: data) else {
                continue
            }

            // Only process assistant messages with usage data
            guard message.type == "assistant",
                  let usage = message.message?.usage,
                  let timestampStr = message.timestamp,
                  let timestamp = iso8601Formatter.date(from: timestampStr) else {
                continue
            }

            // Skip if before cutoff
            guard timestamp >= cutoffDate else { continue }

            let inputTokens = usage.input_tokens ?? 0
            let outputTokens = usage.output_tokens ?? 0

            if inputTokens > 0 || outputTokens > 0 {
                dataPoints.append(TokenDataPoint(
                    timestamp: timestamp,
                    inputTokens: inputTokens,
                    outputTokens: outputTokens
                ))
            }
        }

        return dataPoints
    }

    private func aggregateIntoTimeBuckets(_ points: [TokenDataPoint], bucketMinutes: Int) -> [TokenDataPoint] {
        guard !points.isEmpty else { return [] }

        let bucketInterval = TimeInterval(bucketMinutes * 60)
        var buckets: [Date: (input: Int, output: Int)] = [:]

        for point in points {
            let bucketStart = Date(timeIntervalSince1970: floor(point.timestamp.timeIntervalSince1970 / bucketInterval) * bucketInterval)
            let existing = buckets[bucketStart] ?? (0, 0)
            buckets[bucketStart] = (existing.input + point.inputTokens, existing.output + point.outputTokens)
        }

        return buckets.map { (date, tokens) in
            TokenDataPoint(timestamp: date, inputTokens: tokens.input, outputTokens: tokens.output)
        }.sorted { $0.timestamp < $1.timestamp }
    }
}
