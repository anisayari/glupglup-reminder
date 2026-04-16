import AppKit

@main
@MainActor
struct GlupGlupReminderLauncher {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()

        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
