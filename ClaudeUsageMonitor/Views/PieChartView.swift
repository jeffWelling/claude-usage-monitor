import SwiftUI

struct PieChartView: View {
    let percentage: Double
    let color: Color
    let size: CGFloat

    init(percentage: Double, color: Color, size: CGFloat = 16) {
        self.percentage = percentage
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.gray.opacity(0.2))

            // Filled pie slice
            PieSlice(percentage: min(percentage, 100))
                .fill(color)

            // Border
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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

// Ring/donut style alternative
struct RingChartView: View {
    let percentage: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    init(percentage: Double, color: Color, size: CGFloat = 16, lineWidth: CGFloat = 3) {
        self.percentage = percentage
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Filled arc
            Circle()
                .trim(from: 0, to: min(percentage, 100) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        VStack {
            PieChartView(percentage: 25, color: .green)
            Text("25%")
        }
        VStack {
            PieChartView(percentage: 50, color: .yellow)
            Text("50%")
        }
        VStack {
            PieChartView(percentage: 75, color: .orange)
            Text("75%")
        }
        VStack {
            PieChartView(percentage: 100, color: .red)
            Text("100%")
        }
    }
    .padding()
}
