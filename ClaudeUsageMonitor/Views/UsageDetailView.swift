import SwiftUI

struct UsageDetailView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var settingsManager: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch viewModel.state {
            case .loading:
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
                .padding()

            case .loaded(let usage):
                UsageRowView(
                    title: "5-Hour Usage",
                    utilization: usage.fiveHour.utilization,
                    resetTime: usage.fiveHour.resetsAt,
                    color: settingsManager.settings.colorForUtilization(usage.fiveHour.utilization, metric: .fiveHour),
                    textColor: settingsManager.settings.colors.percentText?.color,
                    timeProgress: timeProgress(resetsAt: usage.fiveHour.resetsAt, windowHours: 5),
                    timeRingColor: settingsManager.settings.colors.timeRing.color,
                    outlineColor: settingsManager.settings.colors.outline.color
                )

                Divider()

                UsageRowView(
                    title: "7-Day Usage",
                    utilization: usage.sevenDay.utilization,
                    resetTime: usage.sevenDay.resetsAt,
                    color: settingsManager.settings.colorForUtilization(usage.sevenDay.utilization, metric: .sevenDay),
                    textColor: settingsManager.settings.colors.percentText?.color,
                    timeProgress: timeProgress(resetsAt: usage.sevenDay.resetsAt, windowHours: 24 * 7),
                    timeRingColor: settingsManager.settings.colors.timeRing.color,
                    outlineColor: settingsManager.settings.colors.outline.color
                )

                if let sonnet = usage.sevenDaySonnet, (sonnet.utilization > 0 || sonnet.resetsAt != nil) {
                    Divider()
                    UsageRowView(
                        title: "Sonnet (7-Day)",
                        utilization: sonnet.utilization,
                        resetTime: sonnet.resetsAt,
                        color: settingsManager.settings.colorForUtilization(sonnet.utilization, metric: .sevenDay),
                        textColor: settingsManager.settings.colors.percentText?.color,
                        timeProgress: timeProgress(resetsAt: sonnet.resetsAt, windowHours: 24 * 7),
                        timeRingColor: settingsManager.settings.colors.timeRing.color,
                        outlineColor: settingsManager.settings.colors.outline.color
                    )
                }

                if let opus = usage.sevenDayOpus, (opus.utilization > 0 || opus.resetsAt != nil) {
                    Divider()
                    UsageRowView(
                        title: "Opus (7-Day)",
                        utilization: opus.utilization,
                        resetTime: opus.resetsAt,
                        color: settingsManager.settings.colorForUtilization(opus.utilization, metric: .sevenDay),
                        textColor: settingsManager.settings.colors.percentText?.color,
                        timeProgress: timeProgress(resetsAt: opus.resetsAt, windowHours: 24 * 7),
                        timeRingColor: settingsManager.settings.colors.timeRing.color,
                        outlineColor: settingsManager.settings.colors.outline.color
                    )
                }

            case .error(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }

            Divider()

            // Token History Graph
            TokenHistoryGraph(
                dataPoints: viewModel.tokenHistory,
                timeWindowHours: settingsManager.settings.graph.timeWindowHours
            )
            .padding(.horizontal)

            Divider()

            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Button(action: {
                Task {
                    await viewModel.manualRefresh()
                }
            }) {
                Label("Refresh Now", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.state.isLoading)
            .padding(.horizontal)

            Divider()

            // Settings Section
            SettingsView(settingsManager: settingsManager)
                .padding(.horizontal)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 12)
        .frame(width: 300)
    }

    /// Calculate how far through the time window we are (0.0 to 1.0)
    private func timeProgress(resetsAt: Date?, windowHours: Int) -> Double {
        guard let resetsAt = resetsAt else { return 0 }

        let now = Date()
        let timeUntilReset = resetsAt.timeIntervalSince(now)
        let windowSeconds = Double(windowHours * 3600)

        // Time elapsed = window - time remaining
        let timeElapsed = windowSeconds - timeUntilReset

        // Clamp to 0-1 range
        return max(0, min(1, timeElapsed / windowSeconds))
    }
}

struct UsageRowView: View {
    let title: String
    let utilization: Double
    let resetTime: Date?
    let color: Color
    var textColor: Color?  // nil = use pie chart color
    var timeProgress: Double = 0
    var timeRingColor: Color = .blue
    var outlineColor: Color = Color.gray.opacity(0.3)

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Pie chart with time progress ring
            PieChartView(
                percentage: utilization,
                color: color,
                size: 44,
                timeProgress: timeProgress,
                timeRingColor: timeRingColor,
                outlineColor: outlineColor
            )

            // Text info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Text("\(Int(utilization))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundColor(textColor ?? color)
                }

                if let resetTime = resetTime {
                    Text("Resets \(resetTime, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No usage recorded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}
