import SwiftUI

struct PieChartView: View {
    let percentage: Double
    let color: Color
    let size: CGFloat
    var timeProgress: Double
    var timeRingColor: Color
    var outlineColor: Color

    init(
        percentage: Double,
        color: Color,
        size: CGFloat = 16,
        timeProgress: Double = 0,
        timeRingColor: Color = .blue,
        outlineColor: Color = Color.gray.opacity(0.3)
    ) {
        self.percentage = percentage
        self.color = color
        self.size = size
        self.timeProgress = timeProgress
        self.timeRingColor = timeRingColor
        self.outlineColor = outlineColor
    }

    private var ringWidth: CGFloat {
        size > 30 ? 3 : 2
    }

    private var pieInset: CGFloat {
        timeProgress > 0 ? ringWidth + 1 : 0
    }

    var body: some View {
        ZStack {
            // Outer time progress ring (if enabled)
            if timeProgress > 0 {
                TimeProgressRing(progress: timeProgress)
                    .stroke(timeRingColor, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
            }

            // Background circle for pie
            Circle()
                .fill(Color.gray.opacity(0.2))
                .padding(pieInset)

            // Filled pie slice
            PieSlice(percentage: min(percentage, 100))
                .fill(color)
                .padding(pieInset)

            // Border around pie
            Circle()
                .stroke(outlineColor, lineWidth: 1)
                .padding(pieInset)
        }
        .frame(width: size, height: size)
    }
}

struct PieSlice: Shape {
    let percentage: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Start from top (12 o'clock position)
        let startAngle = Angle(degrees: -90)
        let endAngle = Angle(degrees: -90 + (360 * percentage / 100))

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

struct TimeProgressRing: Shape {
    let progress: Double  // 0.0 to 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Start from top (12 o'clock position), go clockwise
        let startAngle = Angle(degrees: -90)
        let endAngle = Angle(degrees: -90 + (360 * min(progress, 1.0)))

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}
