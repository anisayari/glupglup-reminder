import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: HydrationStore?
    private var reminderScheduler: ReminderScheduler?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = HydrationStore()
        let scheduler = ReminderScheduler()

        scheduler.actionHandler = { [weak store] action in
            guard let store else {
                return
            }

            switch action {
            case .skip:
                break
            case .done:
                store.addGlass()
                WaterSoundPlayer.shared.playDrop()
            }
        }

        store.connectReminderScheduler(scheduler)

        self.store = store
        self.reminderScheduler = scheduler
        self.statusBarController = StatusBarController(store: store)
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.shutdown()
    }
}
