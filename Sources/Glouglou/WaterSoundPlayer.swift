import AppKit

@MainActor
final class WaterSoundPlayer {
    static let shared = WaterSoundPlayer()

    private var sound: NSSound?

    func playDrop() {
        guard let resourceURL = Bundle.main.url(forResource: "water-drop", withExtension: "wav") else {
            NSSound.beep()
            return
        }

        if sound == nil {
            sound = NSSound(contentsOf: resourceURL, byReference: true)
            sound?.volume = 0.65
        }

        sound?.stop()
        sound?.currentTime = 0
        sound?.play()
    }
}
