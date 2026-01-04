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
            let fillColor = NSColor.labelColor
            let bgColor = NSColor.labelColor.withAlphaComponent(0.25)

            var x: CGFloat = 0
            let pieY = (height - pieSize) / 2

            // Draw first pie (5h)
            drawPie(at: NSPoint(x: x, y: pieY), size: pieSize, percentage: fiveHour, fill: fillColor, bg: bgColor)
            x += pieSize + spacing

            // Draw "5h" text
            let font = NSFont.systemFont(ofSize: fontSize)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: fillColor
            ]
            "5h".draw(at: NSPoint(x: x, y: (height - fontSize) / 2 - 1), withAttributes: attrs)
            x += textWidth5h + groupSpacing

            // Draw second pie (7d)
            drawPie(at: NSPoint(x: x, y: pieY), size: pieSize, percentage: sevenDay, fill: fillColor, bg: bgColor)
            x += pieSize + spacing

            // Draw "7d" text
            "7d".draw(at: NSPoint(x: x, y: (height - fontSize) / 2 - 1), withAttributes: attrs)

            return true
        }

        image.isTemplate = true
        return image
    }

    private func drawPie(at origin: NSPoint, size: CGFloat, percentage: Double, fill: NSColor, bg: NSColor) {
        let rect = NSRect(origin: origin, size: NSSize(width: size, height: size))

        // Background circle
        let bgPath = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
        bg.setFill()
        bgPath.fill()

        // Pie slice
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
    }
}
