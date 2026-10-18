import WidgetKit
import SwiftUI
import AppIntents

struct RemainingBudgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetBudgetSnapshot
    let period: WidgetPeriod
}

struct RemainingBudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RemainingBudgetEntry {
        RemainingBudgetEntry(
            date: .now,
            snapshot: WidgetBudgetSnapshot(
                updatedAt: .now,
                isArabic: true,
                dayLimit: 100,
                daySpent: 35,
                weekLimit: 700,
                weekSpent: 220,
                monthLimit: 3000,
                monthSpent: 1100
            ),
            period: .day
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RemainingBudgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RemainingBudgetEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> RemainingBudgetEntry {
        RemainingBudgetEntry(
            date: .now,
            snapshot: WidgetBudgetStore.load(),
            period: WidgetBudgetStore.preferredPeriod()
        )
    }
}

struct RemainingBudgetWidget: Widget {
    let kind = "RemainingBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemainingBudgetProvider()) { entry in
            RemainingBudgetWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetAtmosphere()
                }
        }
        .configurationDisplayName("المتبقي")
        .description("دائرة الميزانية المتبقية — بتصغر مع كل مصروف، مع مايك وإضافة سريعة.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        // System content margins were clipping chips/buttons — fill the full widget canvas.
        .contentMarginsDisabled()
    }
}

struct VoiceMicWidget: Widget {
    let kind = "VoiceMicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemainingBudgetProvider()) { entry in
            VoiceMicWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        WidgetAtmosphere(intense: true)
                        WidgetBrand.brandGradient.opacity(0.72)
                    }
                }
        }
        .configurationDisplayName("مايك مصاريفي")
        .description("زر مايك واحد — دوس واتكلم من غير ما تدور جوه التطبيق.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

// MARK: - Views

struct RemainingBudgetWidgetView: View {
    var entry: RemainingBudgetEntry
    @Environment(\.widgetFamily) private var family

    private var hasBudget: Bool {
        entry.snapshot.limit(for: entry.period) > 0
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                medium
            case .accessoryCircular:
                accessoryCircle
            case .accessoryRectangular:
                accessoryRect
            default:
                small
            }
        }
        .environment(\.layoutDirection, entry.snapshot.isArabic ? .rightToLeft : .leftToRight)
    }

    private func brandMark(size: CGFloat = 28) -> some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.9), WidgetBrand.lagoon.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            )
            .shadow(color: WidgetBrand.deepTeal.opacity(0.22), radius: 5, y: 2)
            .accessibilityLabel("مصاريفي")
    }

    private var small: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                BudgetRing(
                    ratio: displayRatio,
                    over: entry.snapshot.isOver(for: entry.period),
                    lineWidth: 7,
                    percentFontSize: 12
                )
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Spacer(minLength: 0)
                        brandMark(size: 24)
                    }
                    Text(formattedRemaining)
                        .font(WidgetFont.extraBold(15))
                        .foregroundStyle(WidgetBrand.deepTeal)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(entry.period.shortTitle(isArabic: entry.snapshot.isArabic))
                        .font(WidgetFont.medium(10))
                        .foregroundStyle(WidgetBrand.ink.opacity(0.5))
                }
            }

            HStack(spacing: 6) {
                Button(intent: OpenVoiceIntent()) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(WidgetBrand.brandGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(intent: OpenAddExpenseIntent()) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WidgetBrand.deepTeal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Color.white.opacity(0.75))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(WidgetBrand.cardBorder, lineWidth: 1.1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetCardChrome()
    }

    /// Brand + logo on the copy side; clean ring hero on the opposite side.
    private var medium: some View {
        HStack(alignment: .center, spacing: 0) {
            // Ring hero panel (no logo here)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.72),
                                WidgetBrand.lagoon.opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 58
                        )
                    )
                    .frame(width: 108, height: 108)

                BudgetRing(
                    ratio: displayRatio,
                    over: entry.snapshot.isOver(for: entry.period),
                    lineWidth: 11,
                    percentFontSize: 16
                )
                .frame(width: 82, height: 82)
            }
            .frame(width: 118)

            // Brand / actions panel — logo lives on THIS side
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.snapshot.isArabic ? "مصاريفي" : "Masarify")
                            .font(WidgetFont.extraBold(16))
                            .foregroundStyle(WidgetBrand.deepTeal)
                        Text(headerTitle)
                            .font(WidgetFont.medium(10))
                            .foregroundStyle(WidgetBrand.ink.opacity(0.52))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer(minLength: 4)

                    brandMark(size: 32)

                    Button(intent: ReloadWidgetIntent()) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(WidgetBrand.azure)
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(WidgetBrand.azure.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                Text(formattedRemaining)
                    .font(WidgetFont.extraBold(26))
                    .foregroundStyle(entry.snapshot.isOver(for: entry.period) ? WidgetBrand.coral : WidgetBrand.deepTeal)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                periodChips

                actionRow
            }
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(alignment: .trailing) {
            // Soft brand wash behind the logo/copy side
            LinearGradient(
                colors: [
                    Color.clear,
                    WidgetBrand.deepTeal.opacity(0.07),
                    WidgetBrand.azure.opacity(0.10)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .widgetCardChrome()
    }

    private var periodChips: some View {
        HStack(spacing: 4) {
            ForEach(WidgetPeriod.allCases, id: \.rawValue) { period in
                let selected = period == entry.period
                Button(intent: SetWidgetPeriodIntent(period: period)) {
                    Text(period.shortTitle(isArabic: entry.snapshot.isArabic))
                        .font(WidgetFont.medium(10))
                        .foregroundStyle(selected ? .white : WidgetBrand.deepTeal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            if selected {
                                Capsule().fill(WidgetBrand.brandGradient)
                            } else {
                                Capsule().fill(Color.white.opacity(0.62))
                            }
                        }
                        .overlay(
                            Capsule().strokeBorder(
                                selected ? Color.clear : WidgetBrand.deepTeal.opacity(0.28),
                                lineWidth: 1
                            )
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 6) {
            Button(intent: OpenVoiceIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(entry.snapshot.isArabic ? "مايك" : "Mic")
                        .font(WidgetFont.medium(11))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(WidgetBrand.brandGradient)
                .clipShape(Capsule())
                .shadow(color: WidgetBrand.deepTeal.opacity(0.25), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            Button(intent: OpenAddExpenseIntent()) {
                HStack(spacing: 3) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(entry.snapshot.isArabic ? "مصروف" : "Add")
                        .font(WidgetFont.medium(11))
                }
                .foregroundStyle(WidgetBrand.deepTeal)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.78))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(WidgetBrand.cardBorder, lineWidth: 1.2))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
    }

    private var accessoryCircle: some View {
        Gauge(value: displayRatio) {
            Text(shortRemaining)
        } currentValueLabel: {
            Text(shortRemaining)
                .font(WidgetFont.bold(10))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetURL(WidgetShared.homeURL)
    }

    private var accessoryRect: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.period.title(isArabic: entry.snapshot.isArabic))
                .font(WidgetFont.medium(11))
            Text(formattedRemaining)
                .font(WidgetFont.bold(15))
            Text(spentLabel)
                .font(WidgetFont.regular(10))
                .foregroundStyle(.secondary)
        }
        .widgetURL(WidgetShared.homeURL)
    }

    private var displayRatio: Double {
        guard hasBudget else { return 0 }
        return entry.snapshot.remainingRatio(for: entry.period)
    }

    private var headerTitle: String {
        if !hasBudget {
            return entry.snapshot.isArabic ? "حدّد ميزانية في التطبيق" : "Set a budget in the app"
        }
        return entry.snapshot.isArabic
            ? "متبقي \(entry.period.titleAr)"
            : "Left · \(entry.period.titleEn)"
    }

    private var formattedRemaining: String {
        guard hasBudget else {
            return entry.snapshot.isArabic ? "— ج.م" : "— EGP"
        }
        let value = entry.snapshot.remaining(for: entry.period)
        let number = format(value)
        return entry.snapshot.isArabic ? "\(number) ج.م" : "EGP \(number)"
    }

    private var shortRemaining: String {
        guard hasBudget else { return "—" }
        return format(entry.snapshot.remaining(for: entry.period))
    }

    private var spentLabel: String {
        guard hasBudget else {
            return entry.snapshot.isArabic ? "افتح مصاريفي وعيّن حد شهري" : "Open Masarify and set a monthly limit"
        }
        let spent = format(entry.snapshot.spent(for: entry.period))
        let limit = format(entry.snapshot.limit(for: entry.period))
        // Keep Arabic order stable under RTL.
        if entry.snapshot.isArabic {
            return "اتصرف \(spent) من أصل \(limit)"
        }
        return "Spent \(spent) of \(limit)"
    }

    private func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = entry.snapshot.isArabic
            ? Locale(identifier: "ar_EG")
            : Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value.rounded())) ?? "\(Int(value.rounded()))"
    }
}

struct VoiceMicWidgetView: View {
    var entry: RemainingBudgetEntry

    var body: some View {
        VStack(spacing: 12) {
            Button(intent: OpenVoiceIntent()) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 70, height: 70)
                    Circle()
                        .strokeBorder(.white.opacity(0.65), lineWidth: 1.6)
                        .frame(width: 70, height: 70)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Text(entry.snapshot.isArabic ? "اتكلم دلوقتي" : "Speak now")
                .font(WidgetFont.bold(13))
                .foregroundStyle(.white)

            Text(entry.snapshot.isArabic ? "مصاريفي" : "Masarify")
                .font(WidgetFont.medium(11))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetCardChrome()
    }
}

struct BudgetRing: View {
    var ratio: Double
    var over: Bool
    var lineWidth: CGFloat
    var percentFontSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.55), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, min(1, ratio)))
                .stroke(
                    AngularGradient(
                        colors: over
                            ? [WidgetBrand.coral, WidgetBrand.coral.opacity(0.7)]
                            : [WidgetBrand.deepTeal, WidgetBrand.lagoon, WidgetBrand.azure, WidgetBrand.deepTeal],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: WidgetBrand.deepTeal.opacity(0.18), radius: 4, y: 1)

            Text("\(Int((ratio * 100).rounded()))%")
                .font(WidgetFont.extraBold(percentFontSize))
                .foregroundStyle(over ? WidgetBrand.coral : WidgetBrand.deepTeal)
        }
    }
}

#if DEBUG
#Preview("Remaining medium", as: .systemMedium) {
    RemainingBudgetWidget()
} timeline: {
    RemainingBudgetEntry(
        date: .now,
        snapshot: WidgetBudgetSnapshot(
            updatedAt: .now,
            isArabic: true,
            dayLimit: 100,
            daySpent: 35,
            weekLimit: 700,
            weekSpent: 220,
            monthLimit: 3000,
            monthSpent: 1100
        ),
        period: .day
    )
}

#Preview("Mic small", as: .systemSmall) {
    VoiceMicWidget()
} timeline: {
    RemainingBudgetEntry(
        date: .now,
        snapshot: .empty,
        period: .day
    )
}
#endif
