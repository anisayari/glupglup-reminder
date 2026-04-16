import AppKit

enum DropletStatusIcon {
    private static let baseSymbol: NSImage = {
        let fallback = NSImage(size: NSSize(width: 18, height: 18))
        return NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "GlupGlup Reminder") ?? fallback
    }()

    private static let frameSpecs: [(offsetY: CGFloat, scale: CGFloat, trailOpacity: CGFloat, trailOffsetY: CGFloat)] = [
        (1.0, 0.92, 0.00, 0.0),
        (0.0, 1.00, 0.10, -1.0),
        (-1.0, 1.05, 0.18, -3.0),
        (0.0, 1.00, 0.10, -1.0)
    ]

    static var frameCount: Int {
        frameSpecs.count
    }

    static func image(frameIndex: Int, goalReached: Bool) -> NSImage {
        let frame = frameSpecs[frameIndex % frameSpecs.count]
        let symbol = baseSymbol.withSymbolConfiguration(
            .init(pointSize: 14, weight: goalReached ? .bold : .regular)
        ) ?? baseSymbol

        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            let glyphSize = NSSize(width: symbol.size.width * frame.scale, height: symbol.size.height * frame.scale)
            let glyphRect = CGRect(
                x: (rect.width - glyphSize.width) / 2,
                y: ((rect.height - glyphSize.height) / 2) + frame.offsetY,
                width: glyphSize.width,
                height: glyphSize.height
            )

            symbol.draw(in: glyphRect)

            if frame.trailOpacity > 0 {
                let trailRect = CGRect(
                    x: rect.midX - 1.0,
                    y: rect.midY + frame.trailOffsetY,
                    width: 2.0,
                    height: 3.0
                )

                NSColor.labelColor.withAlphaComponent(frame.trailOpacity).setFill()
                NSBezierPath(roundedRect: trailRect, xRadius: 1, yRadius: 1).fill()
            }

            return true
        }

        image.isTemplate = true
        return image
    }
}
