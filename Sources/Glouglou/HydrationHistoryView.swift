import Charts
import SwiftUI

struct HydrationHistoryView: View {
    @ObservedObject var store: HydrationStore

    private var strings: AppStrings {
        store.strings
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                summaryCards
                chartCard
                heatmapCard
                recentDaysCard
            }
            .padding(24)
        }
        .frame(minWidth: 720, minHeight: 640)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.historyHeroTitle)
                .font(.system(size: 28, weight: .bold))

            Text(strings.historyHeroSubtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 24) {
                HeroMetric(value: store.totalLitersLast30DaysText, label: strings.last30DaysLabel)
                HeroMetric(value: "\(store.goalHitsLast30Days)", label: strings.goalsHitLabel)
                HeroMetric(value: "\(store.streakDays)", label: strings.activeStreakLabel)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.44, blue: 0.87),
                    Color(red: 0.10, green: 0.72, blue: 0.86),
                    Color(red: 0.17, green: 0.85, blue: 0.67)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: strings.averageTitle,
                value: store.averageLitersLast14DaysText,
                caption: strings.averageCaption
            )

            SummaryCard(
                title: strings.consistencyTitle,
                value: "\(Int((store.completionRateLast30Days * 100).rounded())) %",
                caption: strings.consistencyCaption
            )

            SummaryCard(
                title: strings.peakTitle,
                value: bestDayValue,
                caption: bestDayCaption
            )
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(strings.last14DaysTitle)
                .font(.title3.weight(.semibold))

            Text(strings.last14DaysCaption)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(store.recentChartDays) { day in
                BarMark(
                    x: .value(strings.dayAxisLabel, day.date, unit: .day),
                    y: .value(strings.glassesAxisLabel, day.glasses)
                )
                .foregroundStyle(day.metGoal ? Color.accentColor.gradient : Color.accentColor.opacity(0.35).gradient)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                RuleMark(y: .value(strings.goalRuleLabel, store.dailyGoalGlasses))
                    .foregroundStyle(Color.green.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(
                        format: .dateTime
                            .day()
                            .month(.abbreviated)
                            .locale(strings.locale)
                    )
                }
            }
            .frame(height: 220)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.heatmapTitle)
                        .font(.title3.weight(.semibold))

                    Text(strings.heatmapCaption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HeatmapLegend(strings: strings)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(store.heatmapDays) { day in
                    VStack(spacing: 6) {
                        Text(day.weekdayLabel(using: strings))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(heatmapColor(for: day))
                            .frame(height: 42)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(day.metGoal ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                            .overlay {
                                Text("\(day.glasses)")
                                    .font(.headline.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(day.glasses == 0 ? .secondary : .primary)
                            }
                            .help(day.accessibilityLabel(using: strings))

                        Text(day.shortLabel(using: strings))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var recentDaysCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(strings.recentDaysTitle)
                .font(.title3.weight(.semibold))

            ForEach(store.recentDailySummary) { day in
                HStack(spacing: 12) {
                    Circle()
                        .fill(heatmapColor(for: day))
                        .frame(width: 12, height: 12)

                    Text(
                        day.date.formatted(
                            .dateTime
                                .weekday(.wide)
                                .day()
                                .month(.wide)
                                .locale(strings.locale)
                        )
                    )
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(strings.glassesCountText(day.glasses))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    Text(day.litersText(using: strings))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var bestDayValue: String {
        guard let bestDay = store.bestDayLast30Days, bestDay.glasses > 0 else {
            return strings.noBestDayValue
        }

        return strings.glassesCountText(bestDay.glasses)
    }

    private var bestDayCaption: String {
        guard let bestDay = store.bestDayLast30Days, bestDay.glasses > 0 else {
            return strings.noBestDayCaption
        }

        return bestDay.date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .locale(strings.locale)
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private func heatmapColor(for day: HydrationHistoryDay) -> Color {
        if day.glasses == 0 {
            return Color.primary.opacity(0.06)
        }

        switch day.normalizedIntensity {
        case 0..<0.35:
            return Color(red: 0.64, green: 0.87, blue: 0.94)
        case 0.35..<0.7:
            return Color(red: 0.39, green: 0.78, blue: 0.90)
        case 0.7..<1.0:
            return Color(red: 0.19, green: 0.63, blue: 0.92)
        default:
            return Color(red: 0.14, green: 0.78, blue: 0.54)
        }
    }
}

private struct HeroMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(label)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()

            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct HeatmapLegend: View {
    let strings: AppStrings

    var body: some View {
        HStack(spacing: 6) {
            Text(strings.heatmapLowLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(0..<4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color(for: level))
                    .frame(width: 18, height: 12)
            }

            Text(strings.heatmapHighLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0:
            Color(red: 0.64, green: 0.87, blue: 0.94)
        case 1:
            Color(red: 0.39, green: 0.78, blue: 0.90)
        case 2:
            Color(red: 0.19, green: 0.63, blue: 0.92)
        default:
            Color(red: 0.14, green: 0.78, blue: 0.54)
        }
    }
}
