import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case english = "en"
    case french = "fr"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .english:
            Locale(identifier: "en_US")
        case .french:
            Locale(identifier: "fr_FR")
        }
    }

    var displayName: String {
        switch self {
        case .english:
            "English"
        case .french:
            "Français"
        }
    }
}

struct AppStrings {
    let language: AppLanguage

    var locale: Locale { language.locale }

    private var isFrench: Bool {
        language == .french
    }

    func formatLiters(_ milliliters: Int) -> String {
        let liters = Double(milliliters) / 1_000
        return liters.formatted(
            .number
                .locale(locale)
                .precision(.fractionLength(1))
        ) + " L"
    }

    func formatClockTime(minutesAfterMidnight: Int) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let clampedMinutes = min(max(minutesAfterMidnight, 0), 1_439)
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = clampedMinutes / 60
        components.minute = clampedMinutes % 60
        components.second = 0

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: calendar.date(from: components) ?? now)
    }

    func glassWord(_ count: Int) -> String {
        if isFrench {
            return count > 1 ? "verres" : "verre"
        }

        return count == 1 ? "glass" : "glasses"
    }

    func dayWord(_ count: Int) -> String {
        if isFrench {
            return count > 1 ? "jours" : "jour"
        }

        return count == 1 ? "day" : "days"
    }

    func glassesCountText(_ count: Int) -> String {
        "\(count) \(glassWord(count))"
    }

    func daysCountText(_ count: Int) -> String {
        "\(count) \(dayWord(count))"
    }

    var historyWindowTitle: String {
        isFrench ? "Historique GlupGlup Reminder" : "GlupGlup Reminder History"
    }

    var headerTitleActive: String {
        isFrench ? "Hydratation du jour" : "Today's hydration"
    }

    var headerTitleDone: String {
        isFrench ? "Objectif validé" : "Goal reached"
    }

    func headline(goalReached: Bool, goalLitersText: String, todayCount: Int, remainingGlasses: Int) -> String {
        if goalReached {
            return isFrench
                ? "Tu as atteint \(goalLitersText) aujourd'hui."
                : "You reached \(goalLitersText) today."
        }

        if todayCount == 0 {
            return isFrench ? "Premiere gorgee en attente." : "First sip is still waiting."
        }

        if remainingGlasses == 1 {
            return isFrench
                ? "Encore un verre pour boucler la journee."
                : "One more glass to close out the day."
        }

        return isFrench
            ? "Plus que \(remainingGlasses) verres pour toucher l'objectif."
            : "\(remainingGlasses) glasses left to hit the goal."
    }

    func momentumTitle(goalReached: Bool, streakDays: Int, progress: Double) -> String {
        if goalReached {
            if isFrench {
                return streakDays > 1 ? "Mode cascade x\(streakDays)" : "Mode cascade"
            }

            return streakDays > 1 ? "Flow mode x\(streakDays)" : "Flow mode"
        }

        switch progress {
        case 0..<0.25:
            return isFrench ? "Premiere goutte" : "First drop"
        case 0.25..<0.6:
            return isFrench ? "Rythme lance" : "In the groove"
        case 0.6..<1.0:
            return isFrench ? "Ca roule" : "Cruising"
        default:
            return isFrench ? "Hydratation max" : "Hydration max"
        }
    }

    func momentumSubtitle(goalReached: Bool, streakDays: Int, score: Int, glassSizeML: Int) -> String {
        if goalReached {
            return isFrench
                ? "Serie active: \(daysCountText(streakDays))."
                : "Active streak: \(daysCountText(streakDays))."
        }

        return isFrench
            ? "\(score) points aujourd'hui. Un clic = \(glassSizeML) ml."
            : "\(score) points today. One click = \(glassSizeML) ml."
    }

    func notificationBody(todayCount: Int, dailyGoalGlasses: Int) -> String {
        if isFrench {
            return "Un verre d'eau maintenant. \(todayCount)/\(dailyGoalGlasses) verres aujourd'hui."
        }

        return "Time for a glass of water. \(todayCount)/\(dailyGoalGlasses) glasses today."
    }

    var notificationTitle: String {
        "GlupGlup Reminder"
    }

    var notificationSkipActionTitle: String {
        isFrench ? "Passer" : "Skip"
    }

    var notificationDoneActionTitle: String {
        isFrench ? "C'est fait !" : "Done!"
    }

    var statusTooltip: String {
        if isFrench {
            return "Clic: +1 verre • Option-clic: -1 verre • Clic droit: stats et config"
        }

        return "Click: +1 glass • Option-click: -1 glass • Right-click: stats and settings"
    }

    func addButtonTitle(glassSizeML: Int) -> String {
        if isFrench {
            return "J'ai bu \(glassSizeML) ml"
        }

        return "I drank \(glassSizeML) ml"
    }

    var resetButtonTitle: String {
        isFrench ? "Reset" : "Reset"
    }

    var todayMetricTitle: String {
        isFrench ? "Aujourd'hui" : "Today"
    }

    var remainingMetricTitle: String {
        isFrench ? "Reste" : "Remaining"
    }

    var streakMetricTitle: String {
        isFrench ? "Serie" : "Streak"
    }

    var scoreMetricTitle: String {
        "Score"
    }

    func scoreMetricCaption(goalReached: Bool) -> String {
        if isFrench {
            return goalReached ? "boost valide" : "points"
        }

        return goalReached ? "goal bonus" : "points"
    }

    func dailyGoalTitle(goal: Int) -> String {
        if isFrench {
            return "Objectif quotidien: \(goal) \(glassWord(goal))"
        }

        return "Daily goal: \(goal) \(glassWord(goal))"
    }

    func approxGoalText(goalLitersText: String) -> String {
        isFrench ? "Environ \(goalLitersText)" : "About \(goalLitersText)"
    }

    var enableRemindersTitle: String {
        isFrench ? "Activer les rappels" : "Enable reminders"
    }

    var reminderIntervalTitle: String {
        isFrench ? "Intervalle" : "Interval"
    }

    var customReminderOptionTitle: String {
        isFrench ? "Personnalise" : "Custom"
    }

    var customReminderValueTitle: String {
        isFrench ? "Minutes personnalisees" : "Custom minutes"
    }

    var launchAtLoginTitle: String {
        isFrench ? "Lancer au demarrage" : "Launch at login"
    }

    var launchAtLoginApprovalText: String {
        if isFrench {
            return "macOS attend encore une validation dans Reglages Systeme > General > Ouverture."
        }

        return "macOS still needs approval in System Settings > General > Login Items."
    }

    var launchAtLoginUnavailableText: String {
        if isFrench {
            return "Place GlupGlup Reminder dans Applications pour activer le lancement au demarrage."
        }

        return "Move GlupGlup Reminder to Applications to enable launch at login."
    }

    var resetTimeTitle: String {
        isFrench ? "Heure de reset" : "Daily reset time"
    }

    func resetTimeDescription(_ resetTimeText: String) -> String {
        if isFrench {
            return "Le compteur repart chaque jour a \(resetTimeText)."
        }

        return "The daily count rolls over every day at \(resetTimeText)."
    }

    var minuteUnitShort: String {
        "min"
    }

    var languageTitle: String {
        isFrench ? "Langue" : "Language"
    }

    var notificationsDisabledText: String {
        if isFrench {
            return "Notifications macOS desactivees. Autorise GlupGlup Reminder dans Reglages Systeme > Notifications."
        }

        return "macOS notifications are off. Allow GlupGlup Reminder in System Settings > Notifications."
    }

    var miniConfigTitle: String {
        isFrench ? "Mini config" : "Mini settings"
    }

    func reminderLabel(_ minutes: Int) -> String {
        "\(minutes) min"
    }

    var clickHelpText: String {
        if isFrench {
            return "Clic barre de menu = +250 ml • Option-clic = -250 ml • Clic droit = stats et config"
        }

        return "Menu bar click = +250 ml • Option-click = -250 ml • Right-click = stats and settings"
    }

    var historyButtonTitle: String {
        isFrench ? "Historique" : "History"
    }

    var quitButtonTitle: String {
        isFrench ? "Quitter" : "Quit"
    }

    var historyHeroTitle: String {
        isFrench ? "Historique" : "History"
    }

    var historyHeroSubtitle: String {
        if isFrench {
            return "Les 30 derniers jours donnent le rythme: moyenne, regularite et journees les plus solides."
        }

        return "The last 30 days show the rhythm: average intake, consistency, and strongest days."
    }

    var last30DaysLabel: String {
        isFrench ? "sur 30 jours" : "over 30 days"
    }

    var goalsHitLabel: String {
        isFrench ? "objectifs atteints" : "goals hit"
    }

    var activeStreakLabel: String {
        isFrench ? "serie active" : "active streak"
    }

    var averageTitle: String {
        isFrench ? "Moyenne" : "Average"
    }

    var averageCaption: String {
        isFrench ? "sur les 14 derniers jours" : "over the last 14 days"
    }

    var consistencyTitle: String {
        isFrench ? "Regularite" : "Consistency"
    }

    var consistencyCaption: String {
        isFrench ? "jours avec objectif touche" : "days with goal hit"
    }

    var peakTitle: String {
        isFrench ? "Pic" : "Peak"
    }

    var noBestDayValue: String {
        isFrench ? "A lancer" : "To kick off"
    }

    var noBestDayCaption: String {
        isFrench ? "pas encore de grosse journee" : "no standout day yet"
    }

    var last14DaysTitle: String {
        isFrench ? "14 derniers jours" : "Last 14 days"
    }

    var last14DaysCaption: String {
        isFrench ? "Vue rapide pour voir quand le rythme monte ou decroche." : "Quick view to see when your rhythm climbs or drops."
    }

    var goalRuleLabel: String {
        isFrench ? "Objectif" : "Goal"
    }

    var dayAxisLabel: String {
        isFrench ? "Jour" : "Day"
    }

    var glassesAxisLabel: String {
        isFrench ? "Verres" : "Glasses"
    }

    var heatmapTitle: String {
        isFrench ? "Heatmap 5 semaines" : "5-week heatmap"
    }

    var heatmapCaption: String {
        if isFrench {
            return "Chaque case represente une journee. Plus la case est dense, plus tu t'es rapproche de l'objectif."
        }

        return "Each tile is one day. The denser the tile, the closer you were to the goal."
    }

    var heatmapLowLabel: String {
        isFrench ? "Faible" : "Low"
    }

    var heatmapHighLabel: String {
        isFrench ? "Fort" : "High"
    }

    var recentDaysTitle: String {
        isFrench ? "Dernieres journees" : "Recent days"
    }
}
