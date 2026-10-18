import SwiftUI

struct BudgetProgressRow: View {
    @EnvironmentObject private var settings: AppSettings
    let progress: BudgetProgress

    private var barColor: Color {
        switch progress.level {
        case .ok: return BrandTheme.deepTeal
        case .nearLimit: return Color(hex: 0xB45309)
        case .overBudget: return Color(hex: 0xBE123C)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let category = progress.category {
                    Label(settings.categoryLabel(category), systemImage: category.systemImage)
                        .font(AppFont.headline())
                        .foregroundStyle(category.tint)
                        .symbolEffect(.pulse, options: .nonRepeating, value: progress.level != .ok)
                } else {
                    Label(
                        settings.language == .arabic ? "الإجمالي الشهري" : "Monthly total",
                        systemImage: "chart.pie.fill"
                    )
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.deepTeal)
                }
                Spacer()
                Text("\(CurrencyFormat.egp(progress.spent, language: settings.language)) / \(CurrencyFormat.egp(progress.limit, language: settings.language))")
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.ink)
                    .contentTransition(.numericText())
            }

            AnimatedProgressBar(progress: progress.ratio, tint: barColor)

            HStack {
                Text(statusLabel)
                    .font(AppFont.caption())
                    .foregroundStyle(barColor)
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }

    private var statusLabel: String {
        progress.level.bannerTitle(language: settings.language)
    }
}
