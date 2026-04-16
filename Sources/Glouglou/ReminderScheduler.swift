import Foundation
import UserNotifications

enum ReminderAction {
    case skip
    case done
}

final class ReminderScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let notificationIdentifier = "glupglup.reminder.water"
    static let notificationCategoryIdentifier = "glupglup.reminder.actions"
    static let skipActionIdentifier = "glupglup.reminder.skip"
    static let doneActionIdentifier = "glupglup.reminder.done"
    static let notificationSoundName = UNNotificationSoundName("water-drop.wav")

    var authorizationDidChange: ((Bool) -> Void)?
    var actionHandler: ((ReminderAction) -> Void)?

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
        content.categoryIdentifier = Self.notificationCategoryIdentifier
        content.threadIdentifier = "glupglup.reminders"

        registerActions(using: snapshot)

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
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case Self.skipActionIdentifier:
            DispatchQueue.main.async {
                self.actionHandler?(.skip)
                completionHandler()
            }
        case Self.doneActionIdentifier:
            DispatchQueue.main.async {
                self.actionHandler?(.done)
                completionHandler()
            }
        default:
            completionHandler()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func registerActions(using snapshot: ReminderSnapshot) {
        let skipAction = UNNotificationAction(
            identifier: Self.skipActionIdentifier,
            title: snapshot.skipActionTitle
        )
        let doneAction = UNNotificationAction(
            identifier: Self.doneActionIdentifier,
            title: snapshot.doneActionTitle
        )
        let category = UNNotificationCategory(
            identifier: Self.notificationCategoryIdentifier,
            actions: [skipAction, doneAction],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    private func updateAuthorization(_ authorized: Bool) {
        isAuthorized = authorized
        authorizationDidChange?(authorized)
    }
}
