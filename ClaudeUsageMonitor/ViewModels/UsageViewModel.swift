import SwiftUI

@MainActor
class UsageViewModel: ObservableObject {
    enum State {
        case loading
        case loaded(UsageResponse)
        case error(String)

        var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
    }

    @Published var state: State = .loading
    @Published var lastUpdated: Date?
    @Published var tokenHistory: [TokenDataPoint] = []

    private var api: AnthropicAPI { AnthropicAPI.shared }
    private var logReader: ClaudeLogReader { ClaudeLogReader.shared }
    private var scriptRunner: ScriptRunner { ScriptRunner.shared }
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 180 // 3 minutes
    private var isRefreshing = false  // Guard against concurrent refreshes

    // Reference to settings for automation checks
    private var settingsManager: SettingsManager { SettingsManager.shared }

    init() {
        Task {
            await refresh()
        }
        startTimer()
    }

    // Timer cleanup handled by system when object is deallocated

    func refresh() async {
        // Prevent concurrent refreshes which could cause multiple keychain prompts
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let usage = try await api.fetchUsage()
            state = .loaded(usage)
            lastUpdated = Date()

            // Refresh token history
            await refreshTokenHistory()

            // Check automation trigger
            await checkAutomationTrigger(usage: usage)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Manual refresh - resets token state to allow retry after token expiry
    func manualRefresh() async {
        await api.resetTokenState()
        await CredentialManager.shared.clearCache()
        await CredentialManager.shared.resetThrottle()
        await refresh()
    }

    func startTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    /// Refresh token history from Claude logs
    private func refreshTokenHistory() async {
        let windowHours = settingsManager.settings.graph.timeWindowHours
        let history = await logReader.fetchHistory(windowHours: windowHours)
        tokenHistory = history
    }

    /// Check if automation conditions are met and trigger script
    private func checkAutomationTrigger(usage: UsageResponse) async {
        let settings = settingsManager.settings.automation

        await scriptRunner.executeIfNeeded(
            fiveHourUsage: usage.fiveHour.utilization,
            sevenDayUsage: usage.sevenDay.utilization,
            settings: settings
        )
    }

    // Helper computed properties for easy access
    var fiveHourUtilization: Double? {
        if case .loaded(let usage) = state {
            return usage.fiveHour.utilization
        }
        return nil
    }

    var sevenDayUtilization: Double? {
        if case .loaded(let usage) = state {
            return usage.sevenDay.utilization
        }
        return nil
    }

    var opusUtilization: Double? {
        if case .loaded(let usage) = state {
            return usage.sevenDayOpus?.utilization
        }
        return nil
    }

    var sonnetUtilization: Double? {
        if case .loaded(let usage) = state {
            return usage.sevenDaySonnet?.utilization
        }
        return nil
    }

    var fiveHourResetTime: Date? {
        if case .loaded(let usage) = state {
            return usage.fiveHour.resetsAt
        }
        return nil
    }

    var sevenDayResetTime: Date? {
        if case .loaded(let usage) = state {
            return usage.sevenDay.resetsAt
        }
        return nil
    }

    var menuBarText: String {
        switch state {
        case .loading:
            return "..."
        case .loaded(let usage):
            let fiveHour = Int(usage.fiveHour.utilization)
            let sevenDay = Int(usage.sevenDay.utilization)
            return "5h: \(fiveHour)% | 7d: \(sevenDay)%"
        case .error:
            return "⚠️"
        }
    }
}
