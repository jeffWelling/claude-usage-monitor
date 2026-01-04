import SwiftUI

struct UsageDetailView: View {
    @ObservedObject var viewModel: UsageViewModel

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
                    color: colorForUtilization(usage.fiveHour.utilization)
                )

                Divider()

                UsageRowView(
                    title: "7-Day Usage",
                    utilization: usage.sevenDay.utilization,
                    resetTime: usage.sevenDay.resetsAt,
                    color: colorForUtilization(usage.sevenDay.utilization)
                )

                if let sonnet = usage.sevenDaySonnet, (sonnet.utilization > 0 || sonnet.resetsAt != nil) {
                    Divider()
                    UsageRowView(
                        title: "Sonnet (7-Day)",
                        utilization: sonnet.utilization,
                        resetTime: sonnet.resetsAt,
                        color: colorForUtilization(sonnet.utilization)
                    )
                }

                if let opus = usage.sevenDayOpus, (opus.utilization > 0 || opus.resetsAt != nil) {
                    Divider()
                    UsageRowView(
                        title: "Opus (7-Day)",
                        utilization: opus.utilization,
                        resetTime: opus.resetsAt,
                        color: colorForUtilization(opus.utilization)
                    )
                }

            case .error(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Divider()

            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Button(action: {
                Task {
                    await viewModel.refresh()
                }
            }) {
                Label("Refresh Now", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.state.isLoading)
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
        .frame(width: 280)
    }

    private func colorForUtilization(_ value: Double) -> Color {
        switch value {
        case 0..<50:
            return .green
        case 50..<80:
            return .yellow
        default:
            return .red
        }
    }
}

struct UsageRowView: View {
    let title: String
    let utilization: Double
    let resetTime: Date?
    let color: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Pie chart
            PieChartView(
                percentage: utilization,
                color: color,
                size: 40
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
                        .foregroundColor(color)
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
