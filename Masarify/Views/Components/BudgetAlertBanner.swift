import SwiftUI

struct BudgetAlertBanner: View {
    let progress: BudgetProgress

    private var tint: Color {
        switch progress.level {
        case .ok: return BrandTheme.deepTeal
        case .nearLimit: return Color(hex: 0xB45309)
        case .overBudget: return Color(hex: 0xBE123C)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: progress.level == .overBudget ? "exclamationmark.triangle.fill" : "bell.fill")
                .foregroundStyle(tint)
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(progress.level.bannerTitle) · \(progress.budget.titleAr)")
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                Text(message)
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
    }

    private var message: String {
        let pct = Int((progress.ratio * 100).rounded())
        switch progress.level {
        case .nearLimit:
            return "وصلت لـ \(pct)% من حد \(progress.budget.titleAr) (\(CurrencyFormat.egp(progress.spent)) من \(CurrencyFormat.egp(progress.limit)))."
        case .overBudget:
            let over = progress.spent - progress.limit
            return "تجاوزت الحد بـ \(CurrencyFormat.egp(over)). المصروف \(CurrencyFormat.egp(progress.spent)) من أصل \(CurrencyFormat.egp(progress.limit))."
        case .ok:
            return ""
        }
    }
}
