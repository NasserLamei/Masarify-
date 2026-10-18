import SwiftUI
import SwiftData

struct EmergencyModeView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]

    private var plan: SurvivalPlan {
        SurvivalPlan.build(
            paydayDay: settings.paydayDay,
            expenses: expenses,
            budgets: budgets,
            language: settings.language
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                Toggle(isOn: $settings.emergencyModeEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.t(.emergencyTitle))
                            .font(AppFont.headline())
                            .foregroundStyle(BrandTheme.ink)
                        Text(settings.t(.emergencyHint))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)
                    }
                }
                .tint(BrandTheme.coral)
                .padding(16)
                .masarifyCard(cornerRadius: 18, accent: BrandTheme.deepTeal, fillOpacity: 0.72)

                VStack(alignment: .leading, spacing: 10) {
                    Text(settings.t(.payday))
                        .font(AppFont.title3())
                        .foregroundStyle(BrandTheme.ink)
                    Stepper(value: $settings.paydayDay, in: 1...28) {
                        Text("\(settings.paydayDay)")
                            .font(AppFont.headline())
                            .foregroundStyle(BrandTheme.ink)
                    }
                    .padding(16)
                    .masarifyCard(cornerRadius: 18, accent: BrandTheme.deepTeal, fillOpacity: 0.72)
                }

                if settings.emergencyModeEnabled {
                    survivalCard
                        .masarifyAppear(1)
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 16)
            .padding(.bottom, 100)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.emergency))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lifepreserver.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BrandTheme.coral)
                .padding(.top, 2)
            Text(settings.t(.emergencyHint))
                .font(AppFont.subheadline())
                .foregroundStyle(BrandTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var survivalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(settings.t(.survivalPlan))
                .font(AppFont.title2())
                .foregroundStyle(BrandTheme.ink)

            HStack(spacing: 12) {
                metric(
                    title: "\(plan.daysLeft)",
                    subtitle: settings.t(.daysLeft),
                    tint: BrandTheme.coral
                )
                metric(
                    title: CurrencyFormat.egp(plan.dailyCap, language: settings.language),
                    subtitle: settings.t(.dailyCap),
                    tint: BrandTheme.deepTeal
                )
            }

            ForEach(Array(plan.tips.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(BrandTheme.coral)
                    Text(tip)
                        .font(AppFont.body())
                        .foregroundStyle(BrandTheme.ink)
                }
            }
        }
        .padding(16)
        .masarifyCard(cornerRadius: 20, accent: BrandTheme.deepTeal, fillOpacity: 0.72)
    }

    private func metric(title: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.custom(.bold, size: 18))
                .foregroundStyle(BrandTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
