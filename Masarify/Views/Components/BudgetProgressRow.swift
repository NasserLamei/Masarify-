import SwiftUI

struct BudgetProgressRow: View {
    let progress: BudgetProgress

    private var barColor: Color {
        switch progress.level {
        case .ok: return BrandTheme.deepTeal
        case .nearLimit: return Color(hex: 0xB45309)
        case .overBudget: return Color(hex: 0xBE123C)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let category = progress.budget.category {
                    Label(category.labelAr, systemImage: category.systemImage)
                        .font(AppFont.headline())
                        .foregroundStyle(category.tint)
                } else {
                    Label("الإجمالي الشهري", systemImage: "chart.pie.fill")
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.deepTeal)
                }
                Spacer()
                Text("\(CurrencyFormat.egp(progress.spent)) / \(CurrencyFormat.egp(progress.limit))")
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.ink)
            }

            GeometryReader { geo in
                Capsule()
                    .fill(barColor.opacity(0.15))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(barColor)
                            .frame(width: max(6, geo.size.width * CGFloat(min(progress.ratio, 1))))
                    }
            }
            .frame(height: 10)

            HStack {
                Text(statusLabel)
                    .font(AppFont.caption())
                    .foregroundStyle(barColor)
                Spacer()
                Text("متبقي \(CurrencyFormat.egp(progress.remaining))")
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
            }
        }
        .padding(.vertical, 6)
    }

    private var statusLabel: String {
        switch progress.level {
        case .ok: return "ضمن الحد"
        case .nearLimit: return "قرب النهاية (٨٠٪+)"
        case .overBudget: return "فوق الميزانية"
        }
    }
}
