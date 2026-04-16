import Foundation

struct HydrationSettings: Codable {
    var dailyGoalGlasses: Int = 8
    var reminderIntervalMinutes: Int = 45
    var remindersEnabled: Bool = true
    var history: [String: Int] = [:]
    var language: AppLanguage = .english

    enum CodingKeys: String, CodingKey {
        case dailyGoalGlasses
        case reminderIntervalMinutes
        case remindersEnabled
        case history
        case language
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dailyGoalGlasses = try container.decodeIfPresent(Int.self, forKey: .dailyGoalGlasses) ?? 8
        reminderIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .reminderIntervalMinutes) ?? 45
        remindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? true
        history = try container.decodeIfPresent([String: Int].self, forKey: .history) ?? [:]
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .english
    }
}

struct ReminderSnapshot {
    let remindersEnabled: Bool
    let todayCount: Int
    let dailyGoalGlasses: Int
    let reminderIntervalMinutes: Int
    let title: String
    let body: String
    let skipActionTitle: String
    let doneActionTitle: String
}

struct HydrationHistoryDay: Identifiable {
    let date: Date
    let dayKey: String
    let glasses: Int
    let goal: Int

    var id: String { dayKey }

    var liters: Double {
        Double(glasses * HydrationStore.glassSizeML) / 1_000
    }

    func litersText(using strings: AppStrings) -> String {
        strings.formatLiters(glasses * HydrationStore.glassSizeML)
    }

    var metGoal: Bool {
        glasses >= goal
    }

    var normalizedIntensity: Double {
        min(Double(glasses) / Double(max(goal, 1)), 1.0)
    }

    func shortLabel(using strings: AppStrings) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .locale(strings.locale)
        )
    }

    func weekdayLabel(using strings: AppStrings) -> String {
        date.formatted(
            .dateTime
                .weekday(.narrow)
                .locale(strings.locale)
        )
    }

    func accessibilityLabel(using strings: AppStrings) -> String {
        let dayText = date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .year()
                .locale(strings.locale)
        )
        return "\(dayText): \(strings.glassesCountText(glasses))"
    }
}

@MainActor
final class HydrationStore: ObservableObject {
    nonisolated static let glassSizeML = 250
    private static let storageKey = "glupglup.reminder.settings.v1"
    private static let legacyStorageKey = "glouglou.hydration.settings.v1"
    private static let legacyBundleIdentifier = "com.anisayari.glouglou"
    private static let maxHistoryDays = 120

    @Published private var state: HydrationSettings
    @Published private(set) var currentDayKey: String
    @Published private(set) var notificationsAuthorized = false

    private let defaults = UserDefaults.standard
    private var reminderScheduler: ReminderScheduler?
    private var dayWatcher: Timer?

    init() {
        let dayKey = Self.dayKey(for: Date())
        currentDayKey = dayKey

        let loadedState = Self.loadState(from: defaults)
        var normalizedState = loadedState
        normalizedState.history = Self.prunedHistory(from: loadedState.history)
        normalizedState.history[dayKey] = normalizedState.history[dayKey] ?? 0

        state = normalizedState

        startDayWatcher()
        save()
    }

    deinit {
        dayWatcher?.invalidate()
    }

    var todayCount: Int {
        state.history[currentDayKey] ?? 0
    }

    var dailyGoalGlasses: Int {
        state.dailyGoalGlasses
    }

    var remindersEnabled: Bool {
        state.remindersEnabled
    }

    var reminderIntervalMinutes: Int {
        state.reminderIntervalMinutes
    }

    var language: AppLanguage {
        state.language
    }

    var strings: AppStrings {
        AppStrings(language: language)
    }

    var goalReachedToday: Bool {
        todayCount >= dailyGoalGlasses
    }

    var progress: Double {
        min(Double(todayCount) / Double(max(dailyGoalGlasses, 1)), 1.0)
    }

    var remainingGlasses: Int {
        max(dailyGoalGlasses - todayCount, 0)
    }

    var totalMilliliters: Int {
        todayCount * Self.glassSizeML
    }

    var totalLitersText: String {
        strings.formatLiters(totalMilliliters)
    }

    var goalLitersText: String {
        strings.formatLiters(dailyGoalGlasses * Self.glassSizeML)
    }

    var streakDays: Int {
        var streak = 0
        guard let today = Self.date(from: currentDayKey) else {
            return 0
        }

        var cursor = today
        if !goalReachedToday {
            guard let previousDay = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: today) else {
                return 0
            }
            cursor = previousDay
        }

        while glasses(on: cursor) >= dailyGoalGlasses {
            streak += 1
            guard let previousDay = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }

    var score: Int {
        todayCount * 15 + streakDays * 40 + (goalReachedToday ? 80 : 0)
    }

    var averageGlassesLast14Days: Double {
        averageGlasses(forLast: 14)
    }

    var averageLitersLast14DaysText: String {
        strings.formatLiters(Int((averageGlassesLast14Days * Double(Self.glassSizeML)).rounded()))
    }

    var goalHitsLast30Days: Int {
        history(forLast: 30).filter(\.metGoal).count
    }

    var completionRateLast30Days: Double {
        Double(goalHitsLast30Days) / 30.0
    }

    var totalLitersLast30DaysText: String {
        let milliliters = history(forLast: 30).reduce(0) { partialResult, day in
            partialResult + (day.glasses * Self.glassSizeML)
        }

        return strings.formatLiters(milliliters)
    }

    var bestDayLast30Days: HydrationHistoryDay? {
        history(forLast: 30).max { lhs, rhs in
            if lhs.glasses == rhs.glasses {
                return lhs.date < rhs.date
            }

            return lhs.glasses < rhs.glasses
        }
    }

    var recentChartDays: [HydrationHistoryDay] {
        history(forLast: 14)
    }

    var heatmapDays: [HydrationHistoryDay] {
        history(forLast: 35)
    }

    var recentDailySummary: [HydrationHistoryDay] {
        Array(history(forLast: 10).reversed())
    }

    var statusTitle: String {
        let suffix = goalReachedToday ? "✓" : ""
        return "\(todayCount)/\(dailyGoalGlasses)\(suffix)"
    }

    var headerTitle: String {
        goalReachedToday ? strings.headerTitleDone : strings.headerTitleActive
    }

    var headline: String {
        strings.headline(
            goalReached: goalReachedToday,
            goalLitersText: goalLitersText,
            todayCount: todayCount,
            remainingGlasses: remainingGlasses
        )
    }

    var momentumTitle: String {
        strings.momentumTitle(goalReached: goalReachedToday, streakDays: streakDays, progress: progress)
    }

    var momentumSubtitle: String {
        strings.momentumSubtitle(
            goalReached: goalReachedToday,
            streakDays: streakDays,
            score: score,
            glassSizeML: Self.glassSizeML
        )
    }

    func connectReminderScheduler(_ scheduler: ReminderScheduler) {
        reminderScheduler = scheduler
        scheduler.authorizationDidChange = { [weak self] isAuthorized in
            guard let self else {
                return
            }

            self.notificationsAuthorized = isAuthorized
            self.refreshReminders()
        }

        scheduler.requestAuthorizationIfNeeded()
        refreshReminders()
    }

    func addGlass() {
        mutate { state in
            state.history[currentDayKey, default: 0] += 1
        }
    }

    func removeGlass() {
        mutate { state in
            let updatedValue = max((state.history[currentDayKey] ?? 0) - 1, 0)
            state.history[currentDayKey] = updatedValue
        }
    }

    func resetToday() {
        mutate { state in
            state.history[currentDayKey] = 0
        }
    }

    func setDailyGoal(_ goal: Int) {
        mutate { state in
            state.dailyGoalGlasses = min(max(goal, 4), 20)
        }
    }

    func setReminderInterval(_ minutes: Int) {
        mutate { state in
            state.reminderIntervalMinutes = min(max(minutes, 1), 1_440)
        }
    }

    func setRemindersEnabled(_ enabled: Bool) {
        mutate { state in
            state.remindersEnabled = enabled
        }
    }

    func setLanguage(_ language: AppLanguage) {
        mutate { state in
            state.language = language
        }
    }

    func shutdown() {
        dayWatcher?.invalidate()
        dayWatcher = nil
    }

    private func startDayWatcher() {
        dayWatcher?.invalidate()

        dayWatcher = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePossibleDayChange()
            }
        }

        if let dayWatcher {
            RunLoop.main.add(dayWatcher, forMode: .common)
        }
    }

    private func handlePossibleDayChange() {
        let newDayKey = Self.dayKey(for: Date())
        guard newDayKey != currentDayKey else {
            return
        }

        currentDayKey = newDayKey
        mutate { state in
            state.history[newDayKey] = state.history[newDayKey] ?? 0
        }
    }

    private func mutate(_ mutation: (inout HydrationSettings) -> Void) {
        mutation(&state)
        state.history = Self.prunedHistory(from: state.history)
        state.history[currentDayKey] = state.history[currentDayKey] ?? 0
        save()
        refreshReminders()
    }

    private func refreshReminders() {
        reminderScheduler?.sync(with: reminderSnapshot)
    }

    private func history(forLast dayCount: Int) -> [HydrationHistoryDay] {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: Date())

        return (0..<dayCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(dayCount - 1 - offset), to: today) else {
                return nil
            }

            let dayKey = Self.dayKey(for: date)
            return HydrationHistoryDay(
                date: date,
                dayKey: dayKey,
                glasses: state.history[dayKey] ?? 0,
                goal: dailyGoalGlasses
            )
        }
    }

    private func averageGlasses(forLast dayCount: Int) -> Double {
        let sample = history(forLast: dayCount)
        guard !sample.isEmpty else {
            return 0
        }

        let total = sample.reduce(0) { partialResult, day in
            partialResult + day.glasses
        }

        return Double(total) / Double(sample.count)
    }

    private var reminderSnapshot: ReminderSnapshot {
        ReminderSnapshot(
            remindersEnabled: remindersEnabled,
            todayCount: todayCount,
            dailyGoalGlasses: dailyGoalGlasses,
            reminderIntervalMinutes: reminderIntervalMinutes,
            title: strings.notificationTitle,
            body: strings.notificationBody(todayCount: todayCount, dailyGoalGlasses: dailyGoalGlasses),
            skipActionTitle: strings.notificationSkipActionTitle,
            doneActionTitle: strings.notificationDoneActionTitle
        )
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(state) else {
            return
        }

        defaults.set(encoded, forKey: Self.storageKey)
    }

    private func glasses(on date: Date) -> Int {
        state.history[Self.dayKey(for: date)] ?? 0
    }

    private static func loadState(from defaults: UserDefaults) -> HydrationSettings {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(HydrationSettings.self, from: data)
        else {
            return loadLegacyState(from: defaults)
        }

        return decoded
    }

    private static func loadLegacyState(from defaults: UserDefaults) -> HydrationSettings {
        if
            let data = defaults.data(forKey: legacyStorageKey),
            let decoded = try? JSONDecoder().decode(HydrationSettings.self, from: data)
        {
            return decoded
        }

        if
            let legacyDomain = defaults.persistentDomain(forName: legacyBundleIdentifier),
            let data = legacyDomain[legacyStorageKey] as? Data,
            let decoded = try? JSONDecoder().decode(HydrationSettings.self, from: data)
        {
            return decoded
        }

        return HydrationSettings()
    }

    private static func prunedHistory(from history: [String: Int]) -> [String: Int] {
        let calendar = Calendar.autoupdatingCurrent
        let cutoff = calendar.date(byAdding: .day, value: -maxHistoryDays, to: Date()) ?? Date.distantPast

        return history.filter { day, _ in
            guard let date = Self.date(from: day) else {
                return false
            }

            return date >= cutoff
        }
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.autoupdatingCurrent
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func date(from dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.autoupdatingCurrent
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }

}
