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
                sevenDay: usage.sevenDay.utilization
            ))

        case .error:
            Image(systemName: "exclamationmark.circle")
        }
    }

    private func renderCombinedIcon(fiveHour: Double, sevenDay: Double) -> NSImage {
        let pieSize: CGFloat = 14
        let fontSize: CGFloat = 10
        let spacing: CGFloat = 3
        let groupSpacing: CGFloat = 6

        // Calculate total width: [pie][space][5h][groupSpace][pie][space][7d]
        let textWidth5h: CGFloat = 16
        let textWidth7d: CGFloat = 16
        let totalWidth = pieSize + spacing + textWidth5h + groupSpacing + pieSize + spacing + textWidth7d
        let height: CGFloat = 18

        let image = NSImage(size: NSSize(width: totalWidth, height: height), flipped: false) { rect in
            // Text uses label color (adapts to menu bar appearance)
            let textColor = NSColor.labelColor

            var x: CGFloat = 0
            let pieY = (height - pieSize) / 2

            // Draw first pie (5h) with color based on usage
            let fiveHourColor = colorForUsage(fiveHour)
            drawPie(at: NSPoint(x: x, y: pieY), size: pieSize, percentage: fiveHour, fill: fiveHourColor)
            x += pieSize + spacing

            // Draw "5h" text
            let font = NSFont.systemFont(ofSize: fontSize)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            "5h".draw(at: NSPoint(x: x, y: (height - fontSize) / 2 - 1), withAttributes: attrs)
            x += textWidth5h + groupSpacing

            // Draw second pie (7d) with color based on usage
            let sevenDayColor = colorForUsage(sevenDay)
            drawPie(at: NSPoint(x: x, y: pieY), size: pieSize, percentage: sevenDay, fill: sevenDayColor)
            x += pieSize + spacing

            // Draw "7d" text
            "7d".draw(at: NSPoint(x: x, y: (height - fontSize) / 2 - 1), withAttributes: attrs)

            return true
        }

        // Non-template to preserve colors
        image.isTemplate = false
        return image
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

    private func drawPie(at origin: NSPoint, size: CGFloat, percentage: Double, fill: NSColor) {
        let rect = NSRect(origin: origin, size: NSSize(width: size, height: size))
        let insetRect = rect.insetBy(dx: 1, dy: 1)

        // Background circle (unfilled portion) - semi-transparent gray
        let bgPath = NSBezierPath(ovalIn: insetRect)
        NSColor.gray.withAlphaComponent(0.3).setFill()
        bgPath.fill()

        // Pie slice (filled portion)
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = (size - 2) / 2
        let startAngle: CGFloat = 90
        let endAngle: CGFloat = 90 - (360 * CGFloat(min(percentage, 100)) / 100)

        let piePath = NSBezierPath()
        piePath.move(to: center)
        piePath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        piePath.close()

        fill.setFill()
        piePath.fill()

        // Circle outline/border using the fill color
        let outlinePath = NSBezierPath(ovalIn: insetRect)
        outlinePath.lineWidth = 1.0
        fill.setStroke()
        outlinePath.stroke()
    }
}
