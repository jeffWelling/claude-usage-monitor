import SwiftUI
import Charts

struct TokenHistoryGraph: View {
    let dataPoints: [TokenDataPoint]
    let timeWindowHours: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Token Usage (last \(formatTimeWindow()))")
                .font(.caption)
                .foregroundColor(.secondary)

            if dataPoints.isEmpty {
                emptyState
            } else {
                chart
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            Text("No usage data available")
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(height: 60)
    }

    private var chart: some View {
        Chart(dataPoints) { point in
            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Tokens", point.totalTokens)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Tokens", point.totalTokens)
            )
            .foregroundStyle(Color.blue)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text(formatTokenCount(intValue))
                    }
                }
            }
        }
        .frame(height: 80)
    }

    private func formatTimeWindow() -> String {
        if timeWindowHours < 1 {
            return "\(Int(timeWindowHours * 60))m"
        } else if timeWindowHours == 1 {
            return "1h"
        } else if timeWindowHours < 24 {
            return "\(Int(timeWindowHours))h"
        } else if timeWindowHours == 24 {
            return "1d"
        } else {
            let days = Int(timeWindowHours / 24)
            return "\(days)d"
        }
    }

    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.0fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
}
