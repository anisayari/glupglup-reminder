import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Build/AppIcon.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconEntries: [(points: Int, scale: Int, filename: String)] = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png")
]

for entry in iconEntries {
    let pixelSize = CGFloat(entry.points * entry.scale)
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize), flipped: false) { rect in
        drawIcon(in: rect)
        return true
    }

    try writePNG(image: image, to: outputDirectory.appendingPathComponent(entry.filename))
}

print("Generated iconset at \(outputDirectory.path)")

func drawIcon(in rect: CGRect) {
    NSGraphicsContext.current?.imageInterpolation = .high
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }

    let baseInset = rect.width * 0.055
    let cardRect = rect.insetBy(dx: baseInset, dy: baseInset)
    let radius = rect.width * 0.23

    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: radius, yRadius: radius)
    cardPath.addClip()

    let background = NSGradient(colors: [
        NSColor(calibratedRed: 0.08, green: 0.79, blue: 0.79, alpha: 1.0),
        NSColor(calibratedRed: 0.12, green: 0.54, blue: 0.93, alpha: 1.0),
        NSColor(calibratedRed: 0.13, green: 0.87, blue: 0.67, alpha: 1.0)
    ])!
    background.draw(in: cardRect, angle: -32)

    let waveRect = CGRect(
        x: cardRect.minX - rect.width * 0.02,
        y: cardRect.minY - rect.height * 0.01,
        width: cardRect.width * 1.05,
        height: cardRect.height * 0.34
    )
    let wavePath = NSBezierPath()
    wavePath.move(to: CGPoint(x: waveRect.minX, y: waveRect.minY))
    wavePath.curve(
        to: CGPoint(x: waveRect.maxX, y: waveRect.minY + waveRect.height * 0.35),
        controlPoint1: CGPoint(x: waveRect.minX + waveRect.width * 0.22, y: waveRect.minY + waveRect.height * 0.52),
        controlPoint2: CGPoint(x: waveRect.minX + waveRect.width * 0.72, y: waveRect.minY - waveRect.height * 0.08)
    )
    wavePath.line(to: CGPoint(x: waveRect.maxX, y: waveRect.minY))
    wavePath.close()
    NSColor.white.withAlphaComponent(0.17).setFill()
    wavePath.fill()

    let ringRect = CGRect(
        x: rect.midX - rect.width * 0.26,
        y: rect.midY - rect.height * 0.17,
        width: rect.width * 0.52,
        height: rect.height * 0.18
    )
    let ringPath = NSBezierPath(ovalIn: ringRect)
    ringPath.lineWidth = rect.width * 0.028
    NSColor.white.withAlphaComponent(0.30).setStroke()
    ringPath.stroke()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = rect.width * 0.045
    shadow.shadowOffset = NSSize(width: 0, height: -rect.height * 0.018)
    shadow.set()

    let dropRect = CGRect(
        x: rect.midX - rect.width * 0.16,
        y: rect.midY - rect.height * 0.01,
        width: rect.width * 0.32,
        height: rect.height * 0.41
    )
    let dropPath = makeDropletPath(in: dropRect)
    NSGraphicsContext.saveGraphicsState()
    dropPath.addClip()

    let dropGradient = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.98),
        NSColor(calibratedRed: 0.87, green: 0.98, blue: 1.0, alpha: 1.0),
        NSColor(calibratedRed: 0.58, green: 0.91, blue: 1.0, alpha: 1.0)
    ])!
    dropGradient.draw(in: dropPath, angle: -90)

    let highlightRect = CGRect(
        x: dropRect.minX + dropRect.width * 0.13,
        y: dropRect.minY + dropRect.height * 0.48,
        width: dropRect.width * 0.24,
        height: dropRect.height * 0.28
    )
    let highlightPath = NSBezierPath(ovalIn: highlightRect)
    NSColor.white.withAlphaComponent(0.72).setFill()
    highlightPath.fill()
    NSGraphicsContext.restoreGraphicsState()

    let bubbleOne = NSBezierPath(ovalIn: CGRect(
        x: rect.midX + rect.width * 0.17,
        y: rect.midY + rect.height * 0.11,
        width: rect.width * 0.08,
        height: rect.width * 0.08
    ))
    NSColor.white.withAlphaComponent(0.36).setFill()
    bubbleOne.fill()

    let bubbleTwo = NSBezierPath(ovalIn: CGRect(
        x: rect.midX - rect.width * 0.24,
        y: rect.midY + rect.height * 0.04,
        width: rect.width * 0.05,
        height: rect.width * 0.05
    ))
    NSColor.white.withAlphaComponent(0.26).setFill()
    bubbleTwo.fill()
}

func makeDropletPath(in rect: CGRect) -> NSBezierPath {
    let path = NSBezierPath()
    let top = CGPoint(x: rect.midX, y: rect.maxY)
    let bottom = CGPoint(x: rect.midX, y: rect.minY)

    path.move(to: top)
    path.curve(
        to: CGPoint(x: rect.minX, y: rect.midY),
        controlPoint1: CGPoint(x: rect.midX - rect.width * 0.02, y: rect.maxY - rect.height * 0.14),
        controlPoint2: CGPoint(x: rect.minX - rect.width * 0.08, y: rect.minY + rect.height * 0.54)
    )
    path.curve(
        to: bottom,
        controlPoint1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.14),
        controlPoint2: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.minY - rect.height * 0.02)
    )
    path.curve(
        to: CGPoint(x: rect.maxX, y: rect.midY),
        controlPoint1: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.minY - rect.height * 0.02),
        controlPoint2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.14)
    )
    path.curve(
        to: top,
        controlPoint1: CGPoint(x: rect.maxX + rect.width * 0.08, y: rect.minY + rect.height * 0.54),
        controlPoint2: CGPoint(x: rect.midX + rect.width * 0.02, y: rect.maxY - rect.height * 0.14)
    )
    path.close()
    return path
}

func writePNG(image: NSImage, to url: URL) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG"])
    }

    try pngData.write(to: url)
}
