import SwiftUI

struct BudgetAlertBanner: View {
    @EnvironmentObject private var settings: AppSettings
    let progress: BudgetProgress
    @State private var pulse = false

    private var tint: Color {
        switch progress.level {
        case .ok: return BrandTheme.deepTeal
        case .nearLimit: return Color(hex: 0xB45309)
        case .overBudget: return Color(hex: 0xBE123C)
        }
    }

    private var titleLabel: String {
        if let category = progress.category {
            return settings.categoryLabel(category)
        }
        return settings.language == .arabic ? "الإجمالي الشهري" : "Monthly total"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: progress.level == .overBudget ? "exclamationmark.triangle.fill" : "bell.fill")
                .foregroundStyle(tint)
                .font(.system(size: 18, weight: .semibold))
                .scaleEffect(pulse ? 1.08 : 1)
                .animation(
                    .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                    value: pulse
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("\(progress.level.bannerTitle(language: settings.language)) · \(titleLabel)")
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                Text(message)
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(BrandTheme.screenInset)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
                )
        )
        .onAppear { pulse = true }
    }

    private var message: String {
        let pct = Int((progress.ratio * 100).rounded())
        let spent = CurrencyFormat.egp(progress.spent, language: settings.language)
        let limit = CurrencyFormat.egp(progress.limit, language: settings.language)
        switch progress.level {
        case .nearLimit:
            return settings.language == .arabic
                ? "وصلت لـ \(pct)% من حد \(titleLabel) (\(spent) من \(limit))."
                : "You've reached \(pct)% of \(titleLabel) (\(spent) of \(limit))."
        case .overBudget:
            let over = CurrencyFormat.egp(progress.spent - progress.limit, language: settings.language)
            return settings.language == .arabic
                ? "تجاوزت الحد بـ \(over). المصروف \(spent) من أصل \(limit)."
                : "Over by \(over). Spent \(spent) of \(limit)."
        case .ok:
            return ""
        }
    }
}
