import SwiftUI

struct MenuBarDonutIcon: View {
    let value: Double
    let color: Color

    var body: some View {
        Image(nsImage: renderDonut())
    }

    private func renderDonut() -> NSImage {
        let size: CGFloat = 16
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            let center = NSPoint(x: size / 2, y: size / 2)
            let radius = size / 2 - 2
            let lineWidth: CGFloat = 2.5

            let bgPath = NSBezierPath()
            bgPath.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
            bgPath.lineWidth = lineWidth
            NSColor.systemGray.withAlphaComponent(0.3).setStroke()
            bgPath.stroke()

            let pct = min(max(self.value / 100, 0), 1)
            if pct > 0 {
                let fgPath = NSBezierPath()
                fgPath.appendArc(
                    withCenter: center,
                    radius: radius,
                    startAngle: 90,
                    endAngle: 90 - 360 * pct,
                    clockwise: true
                )
                fgPath.lineWidth = lineWidth
                fgPath.lineCapStyle = .round
                NSColor(self.color).setStroke()
                fgPath.stroke()
            }
            return true
        }
        image.isTemplate = false
        return image
    }
}

struct MenuBarBatteryIcon: View {
    let value: Double
    let color: Color

    var body: some View {
        Image(nsImage: renderBattery())
    }

    private func renderBattery() -> NSImage {
        let imgWidth: CGFloat = 22
        let imgHeight: CGFloat = 14
        let image = NSImage(size: NSSize(width: imgWidth, height: imgHeight), flipped: false) { _ in
            let bodyWidth: CGFloat = 16
            let bodyHeight: CGFloat = 8
            let bodyRect = NSRect(
                x: 0.5,
                y: (imgHeight - bodyHeight) / 2,
                width: bodyWidth,
                height: bodyHeight
            )

            let borderPath = NSBezierPath(roundedRect: bodyRect.insetBy(dx: 0.5, dy: 0.5), xRadius: 1.5, yRadius: 1.5)
            borderPath.lineWidth = 1
            NSColor.systemGray.withAlphaComponent(0.5).setStroke()
            borderPath.stroke()

            let fillPct = min(max(self.value / 100, 0), 1)
            let fillWidth = max(0, (bodyRect.width - 2) * fillPct)
            if fillWidth > 0 {
                let fillRect = NSRect(
                    x: bodyRect.minX + 1,
                    y: bodyRect.minY + 1,
                    width: fillWidth,
                    height: bodyRect.height - 2
                )
                let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 0.5, yRadius: 0.5)
                NSColor(self.color).setFill()
                fillPath.fill()
            }

            let nubRect = NSRect(
                x: bodyRect.maxX + 0.5,
                y: bodyRect.midY - 1.5,
                width: 1.5,
                height: 3
            )
            let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
            NSColor.systemGray.withAlphaComponent(0.4).setFill()
            nubPath.fill()

            return true
        }
        image.isTemplate = false
        return image
    }
}
