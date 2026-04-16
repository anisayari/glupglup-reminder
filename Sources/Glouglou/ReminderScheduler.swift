import Foundation
import UserNotifications

final class ReminderScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let notificationIdentifier = "glupglup.reminder.water"
    static let notificationSoundName = UNNotificationSoundName("water-drop.wav")

    var authorizationDidChange: ((Bool) -> Void)?

    private let center = UNUserNotificationCenter.current()
    private(set) var isAuthorized = false

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else {
                return
            }

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    self.updateAuthorization(true)
                }
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        self.updateAuthorization(granted)
                        if !granted {
                            self.cancel()
                        }
                    }
                }
            case .denied:
                DispatchQueue.main.async {
                    self.updateAuthorization(false)
                    self.cancel()
                }
            @unknown default:
                DispatchQueue.main.async {
                    self.updateAuthorization(false)
                    self.cancel()
                }
            }
        }
    }

    func sync(with snapshot: ReminderSnapshot) {
        guard isAuthorized else {
            if !snapshot.remindersEnabled {
                cancel()
            }
            return
        }

        guard snapshot.remindersEnabled, snapshot.todayCount < snapshot.dailyGoalGlasses else {
            cancel()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = snapshot.title
        content.body = snapshot.body
        content.sound = Bundle.main.url(forResource: "water-drop", withExtension: "wav") != nil
            ? UNNotificationSound(named: Self.notificationSoundName)
            : .default
        content.threadIdentifier = "glupglup.reminders"

        let interval = TimeInterval(max(snapshot.reminderIntervalMinutes, 1) * 60)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
        center.add(request)
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func updateAuthorization(_ authorized: Bool) {
        isAuthorized = authorized
        authorizationDidChange?(authorized)
    }
}
