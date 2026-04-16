import SwiftUI

struct HydrationPopoverView: View {
    private enum ReminderSelection: Hashable {
        case preset(Int)
        case custom
    }

    @ObservedObject var store: HydrationStore

    let onOpenHistory: () -> Void
    let onQuit: () -> Void

    @State private var showConfig = true
    @State private var reminderSelection: ReminderSelection = .preset(45)
    @State private var customReminderText = ""

    private let reminderOptions = [15, 30, 45, 60, 90, 120, 180, 240]

    private var strings: AppStrings {
        store.strings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            actionRow
            metricsGrid
            configSection
            footer
        }
        .padding(18)
        .frame(width: 360)
        .onAppear(perform: syncReminderSelectionFromStore)
        .onChange(of: store.reminderIntervalMinutes) { _, _ in
            syncReminderSelectionFromStore()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ProgressRingView(progress: store.progress, goalReached: store.goalReachedToday)

            VStack(alignment: .leading, spacing: 6) {
                Text(store.headerTitle)
                    .font(.title3.weight(.semibold))

                Text("\(strings.glassesCountText(store.todayCount)) • \(store.totalLitersText)")
                    .font(.headline)
                    .monospacedDigit()

                Text(store.headline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(store.momentumTitle)
                    .font(.callout.weight(.semibold))

                Text(store.momentumSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                WaterSoundPlayer.shared.playDrop()
                store.addGlass()
            } label: {
                Label(strings.addButtonTitle(glassSizeML: HydrationStore.glassSizeML), systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                WaterSoundPlayer.shared.playDrop()
                store.removeGlass()
            } label: {
                Label("-1", systemImage: "minus")
                    .frame(minWidth: 64)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button(strings.resetButtonTitle) {
                store.resetToday()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(store.todayCount == 0)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            MetricTile(
                label: strings.todayMetricTitle,
                value: store.totalLitersText,
                caption: strings.glassesCountText(store.todayCount)
            )

            MetricTile(
                label: strings.remainingMetricTitle,
                value: "\(store.remainingGlasses)",
                caption: strings.glassWord(store.remainingGlasses)
            )

            MetricTile(
                label: strings.streakMetricTitle,
                value: "\(store.streakDays)",
                caption: strings.dayWord(store.streakDays)
            )

            MetricTile(
                label: strings.scoreMetricTitle,
                value: "\(store.score)",
                caption: strings.scoreMetricCaption(goalReached: store.goalReachedToday)
            )
        }
    }

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            DisclosureGroup(isExpanded: $showConfig) {
                VStack(alignment: .leading, spacing: 12) {
                    Stepper(value: dailyGoalBinding, in: 4...20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strings.dailyGoalTitle(goal: store.dailyGoalGlasses))
                            Text(strings.approxGoalText(goalLitersText: store.goalLitersText))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(strings.enableRemindersTitle, isOn: remindersBinding)

                    Picker(strings.reminderIntervalTitle, selection: reminderSelectionBinding) {
                        ForEach(reminderOptions, id: \.self) { minutes in
                            Text(strings.reminderLabel(minutes))
                                .tag(ReminderSelection.preset(minutes))
                        }
                        Text(strings.customReminderOptionTitle).tag(ReminderSelection.custom)
                    }
                    .pickerStyle(.menu)
                    .disabled(!store.remindersEnabled)

                    if reminderSelection == .custom {
                        HStack(spacing: 10) {
                            Text(strings.customReminderValueTitle)
                                .foregroundStyle(.secondary)

                            TextField("", text: customReminderTextBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 72)
                                .multilineTextAlignment(.trailing)
                                .monospacedDigit()

                            Text(strings.minuteUnitShort)
                                .foregroundStyle(.secondary)

                            Stepper("", value: customReminderStepperBinding, in: 1...1_440)
                                .labelsHidden()
                        }
                    }

                    Picker(strings.languageTitle, selection: languageBinding) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)

                    if store.remindersEnabled && !store.notificationsAuthorized {
                        Text(strings.notificationsDisabledText)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Label(strings.miniConfigTitle, systemImage: "slider.horizontal.3")
                    Spacer()
                    Text("\(store.dailyGoalGlasses) \(strings.glassWord(store.dailyGoalGlasses)) • \(strings.reminderLabel(store.reminderIntervalMinutes))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            Text(strings.clickHelpText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button(strings.historyButtonTitle) {
                    onOpenHistory()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(strings.quitButtonTitle) {
                    onQuit()
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var dailyGoalBinding: Binding<Int> {
        Binding(
            get: { store.dailyGoalGlasses },
            set: { store.setDailyGoal($0) }
        )
    }

    private var remindersBinding: Binding<Bool> {
        Binding(
            get: { store.remindersEnabled },
            set: { store.setRemindersEnabled($0) }
        )
    }

    private var reminderSelectionBinding: Binding<ReminderSelection> {
        Binding(
            get: { reminderSelection },
            set: { selection in
                reminderSelection = selection

                switch selection {
                case .preset(let minutes):
                    store.setReminderInterval(minutes)
                    customReminderText = "\(minutes)"
                case .custom:
                    if customReminderText.isEmpty {
                        customReminderText = "\(store.reminderIntervalMinutes)"
                    }
                }
            }
        )
    }

    private var customReminderTextBinding: Binding<String> {
        Binding(
            get: { customReminderText },
            set: { newValue in
                let digitsOnly = newValue.filter(\.isNumber)
                if digitsOnly != newValue {
                    customReminderText = digitsOnly
                    return
                }

                customReminderText = digitsOnly
                applyCustomReminderIfPossible()
            }
        )
    }

    private var customReminderStepperBinding: Binding<Int> {
        Binding(
            get: { min(max(Int(customReminderText) ?? store.reminderIntervalMinutes, 1), 1_440) },
            set: { newValue in
                let clamped = min(max(newValue, 1), 1_440)
                customReminderText = "\(clamped)"
                store.setReminderInterval(clamped)
            }
        )
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { store.language },
            set: { store.setLanguage($0) }
        )
    }

    private func syncReminderSelectionFromStore() {
        if reminderOptions.contains(store.reminderIntervalMinutes) {
            reminderSelection = .preset(store.reminderIntervalMinutes)
        } else {
            reminderSelection = .custom
        }

        customReminderText = "\(store.reminderIntervalMinutes)"
    }

    private func applyCustomReminderIfPossible() {
        guard reminderSelection == .custom else {
            return
        }

        guard let value = Int(customReminderText), !customReminderText.isEmpty else {
            return
        }

        let clamped = min(max(value, 1), 1_440)
        if clamped != value {
            customReminderText = "\(clamped)"
        }

        if store.reminderIntervalMinutes != clamped {
            store.setReminderInterval(clamped)
        }
    }
}

private struct ProgressRingView: View {
    let progress: Double
    let goalReached: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 10)

            Circle()
                .trim(from: 0, to: max(progress, 0.03))
                .stroke(
                    goalReached ? Color.green : Color.accentColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: goalReached ? "drop.fill" : "drop")
                .font(.system(size: 24, weight: .semibold))
        }
        .frame(width: 84, height: 84)
        .animation(.easeOut(duration: 0.2), value: progress)
    }
}

private struct MetricTile: View {
    let label: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()

            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
