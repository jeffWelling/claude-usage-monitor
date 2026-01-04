import SwiftUI
import Combine

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

    private let api = AnthropicAPI()
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 180 // 3 minutes

    init() {
        Task {
            await refresh()
        }
        startTimer()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func refresh() async {
        do {
            let usage = try await api.fetchUsage()
            state = .loaded(usage)
            lastUpdated = Date()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func startTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
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
