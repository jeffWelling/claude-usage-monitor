import SwiftUI
import AppKit

struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        switch viewModel.state {
        case .loading:
            Image(systemName: "circle.dashed")

        case .loaded(let usage):
            Image(nsImage: renderCombinedIcon(
                fiveHour: usage.fiveHour.utilization,
                fiveHourResetsAt: usage.fiveHour.resetsAt,
                sevenDay: usage.sevenDay.utilization,
                sevenDayResetsAt: usage.sevenDay.resetsAt
            ))

        case .error:
            Image(systemName: "exclamationmark.circle")
        }
    }

    private func renderCombinedIcon(fiveHour: Double, fiveHourResetsAt: Date?, sevenDay: Double, sevenDayResetsAt: Date?) -> NSImage {
        let pieSize: CGFloat = 16  // Slightly larger to accommodate ring
        let fontSize: CGFloat = 10
        let spacing: CGFloat = 3
        let groupSpacing: CGFloat = 6

        // Calculate total width: [pie][space][5h][groupSpace][pie][space][7d]
        let textWidth5h: CGFloat = 16
        let textWidth7d: CGFloat = 16
        let totalWidth = pieSize + spacing + textWidth5h + groupSpacing + pieSize + spacing + textWidth7d
        let height: CGFloat = 18

        // Calculate time progress for each window
        let fiveHourTimeProgress = timeProgress(resetsAt: fiveHourResetsAt, windowHours: 5)
        let sevenDayTimeProgress = timeProgress(resetsAt: sevenDayResetsAt, windowHours: 24 * 7)

        let image = NSImage(size: NSSize(width: totalWidth, height: height), flipped: false) { rect in
            // Text uses label color (adapts to menu bar appearance)
            let textColor = NSColor.labelColor

            var x: CGFloat = 0
            let pieY = (height - pieSize) / 2

            // Draw first pie (5h) with color based on usage and time ring
            let fiveHourColor = colorForUsage(fiveHour)
            drawPie(at: NSPoint(x: x, y: pieY), size: pieSize, percentage: fiveHour, fill: fiveHourColor, timeProgress: fiveHourTimeProgress)
            x += pieSize + spacing

            // Draw "5h" text
            let font = NSFont.systemFont(ofSize: fontSize)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            "5h".draw(at: NSPoint(x: x, y: (height - fontSize) / 2 - 1), withAttributes: attrs)
            x += textWidth5h + groupSpacing

            // Draw second pie (7d) with color based on usage and time ring
            let sevenDayColor = colorForUsage(sevenDay)
            drawPie(at: NSPoint(x: x, y: pieY), size: pieSize, percentage: sevenDay, fill: sevenDayColor, timeProgress: sevenDayTimeProgress)
            x += pieSize + spacing

            // Draw "7d" text
            "7d".draw(at: NSPoint(x: x, y: (height - fontSize) / 2 - 1), withAttributes: attrs)

            return true
        }

        // Non-template to preserve colors
        image.isTemplate = false
        return image
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

    private func colorForUsage(_ percentage: Double) -> NSColor {
        switch percentage {
        case 0..<50:
            return NSColor.systemGreen
        case 50..<80:
            return NSColor.systemYellow
        default:
            return NSColor.systemRed
        }
    }

    private func drawPie(at origin: NSPoint, size: CGFloat, percentage: Double, fill: NSColor, timeProgress: Double) {
        let rect = NSRect(origin: origin, size: NSSize(width: size, height: size))

        // Leave room for the outer time ring
        let ringWidth: CGFloat = 2
        let pieRect = rect.insetBy(dx: ringWidth, dy: ringWidth)

        // Background circle (unfilled portion) - semi-transparent gray
        let bgPath = NSBezierPath(ovalIn: pieRect)
        NSColor.gray.withAlphaComponent(0.3).setFill()
        bgPath.fill()

        // Pie slice (filled portion)
        let pieCenter = NSPoint(x: pieRect.midX, y: pieRect.midY)
        let pieRadius = pieRect.width / 2
        let startAngle: CGFloat = 90
        let endAngle: CGFloat = 90 - (360 * CGFloat(min(percentage, 100)) / 100)

        let piePath = NSBezierPath()
        piePath.move(to: pieCenter)
        piePath.appendArc(withCenter: pieCenter, radius: pieRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        piePath.close()

        fill.setFill()
        piePath.fill()

        // Circle outline/border using the fill color
        let outlinePath = NSBezierPath(ovalIn: pieRect)
        outlinePath.lineWidth = 0.5
        fill.setStroke()
        outlinePath.stroke()

        // Outer time progress ring (blue arc)
        if timeProgress > 0 {
            let ringCenter = NSPoint(x: rect.midX, y: rect.midY)
            let ringRadius = (size - ringWidth) / 2

            let ringStartAngle: CGFloat = 90
            let ringEndAngle: CGFloat = 90 - (360 * CGFloat(timeProgress))

            let ringPath = NSBezierPath()
            ringPath.appendArc(withCenter: ringCenter, radius: ringRadius, startAngle: ringStartAngle, endAngle: ringEndAngle, clockwise: true)
            ringPath.lineWidth = ringWidth
            ringPath.lineCapStyle = .round

            NSColor.systemBlue.setStroke()
            ringPath.stroke()
        }
    }
}
