import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: HydrationStore?
    private var reminderScheduler: ReminderScheduler?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = HydrationStore()
        let scheduler = ReminderScheduler()

        store.connectReminderScheduler(scheduler)

        self.store = store
        self.reminderScheduler = scheduler
        self.statusBarController = StatusBarController(store: store)
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.shutdown()
    }
}
