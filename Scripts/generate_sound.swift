import Foundation

struct WavWriter {
    static func writeMono16BitPCM(
        samples: [Double],
        sampleRate: Int,
        to url: URL
    ) throws {
        let channels = 1
        let bitsPerSample = 16
        let bytesPerSample = bitsPerSample / 8
        let byteRate = sampleRate * channels * bytesPerSample
        let blockAlign = channels * bytesPerSample
        let dataSize = samples.count * bytesPerSample
        let riffChunkSize = 36 + dataSize

        var data = Data()
        data.appendASCII("RIFF")
        data.appendLittleEndian(UInt32(riffChunkSize))
        data.appendASCII("WAVE")
        data.appendASCII("fmt ")
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt16(channels))
        data.appendLittleEndian(UInt32(sampleRate))
        data.appendLittleEndian(UInt32(byteRate))
        data.appendLittleEndian(UInt16(blockAlign))
        data.appendLittleEndian(UInt16(bitsPerSample))
        data.appendASCII("data")
        data.appendLittleEndian(UInt32(dataSize))

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let intValue = Int16((clamped * Double(Int16.max)).rounded())
            data.appendLittleEndian(UInt16(bitPattern: intValue))
        }

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url)
    }
}

let outputPath = CommandLine.arguments.dropFirst().first ?? "Resources/water-drop.wav"
let outputURL = URL(fileURLWithPath: outputPath)

let sampleRate = 44_100
let duration = 0.38
let sampleCount = Int(Double(sampleRate) * duration)

var samples = Array(repeating: 0.0, count: sampleCount)
var phasePrimary = 0.0
var phaseSecondary = 0.0
var phaseRipple = 0.0

for index in 0..<sampleCount {
    let time = Double(index) / Double(sampleRate)
    let sweepProgress = min(time / 0.18, 1.0)
    let primaryFrequency = 1_500.0 - (950.0 * pow(sweepProgress, 0.72))
    let secondaryFrequency = 760.0 - (310.0 * min(time / 0.22, 1.0))
    let rippleFrequency = 2_200.0 - (1_450.0 * min(time / 0.09, 1.0))

    phasePrimary += (2.0 * .pi * primaryFrequency) / Double(sampleRate)
    phaseSecondary += (2.0 * .pi * secondaryFrequency) / Double(sampleRate)
    phaseRipple += (2.0 * .pi * rippleFrequency) / Double(sampleRate)

    let mainEnvelope = exp(-17.0 * time)
    let tailEnvelope = exp(-26.0 * max(0.0, time - 0.015))
    let rippleEnvelope = exp(-55.0 * time)

    let primary = sin(phasePrimary) * 0.92 * mainEnvelope
    let secondary = sin(phaseSecondary) * 0.24 * tailEnvelope
    let ripple = sin(phaseRipple) * 0.10 * rippleEnvelope

    samples[index] = primary + secondary + ripple
}

let firstDelay = Int(Double(sampleRate) * 0.09)
let secondDelay = Int(Double(sampleRate) * 0.15)

if firstDelay < sampleCount {
    for index in firstDelay..<sampleCount {
        samples[index] += samples[index - firstDelay] * 0.18
    }
}

if secondDelay < sampleCount {
    for index in secondDelay..<sampleCount {
        samples[index] += samples[index - secondDelay] * 0.08
    }
}

let peak = samples.map { abs($0) }.max() ?? 1.0
let gain = peak > 0 ? 0.82 / peak : 1.0
let normalized = samples.enumerated().map { index, sample -> Double in
    let time = Double(index) / Double(sampleRate)
    let fadeIn = min(time / 0.004, 1.0)
    let fadeOutStart = max(duration - 0.05, 0.0)
    let fadeOut = time > fadeOutStart ? max(0.0, 1.0 - ((time - fadeOutStart) / 0.05)) : 1.0
    return sample * gain * fadeIn * fadeOut
}

try WavWriter.writeMono16BitPCM(samples: normalized, sampleRate: sampleRate, to: outputURL)
print("Generated \(outputURL.path)")

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { rawBuffer in
            append(rawBuffer.bindMemory(to: UInt8.self))
        }
    }
}
