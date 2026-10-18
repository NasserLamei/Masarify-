import SwiftUI
import SwiftData

struct PredictiveCashFlowView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]

    private var forecast: PredictiveCashFlowService.Forecast {
        PredictiveCashFlowService.forecast(
            expenses: expenses,
            budgets: budgets,
            categories: categories,
            language: settings.language
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(settings.t(.cashFlowHint))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)

                VStack(alignment: .leading, spacing: 10) {
                    Label(settings.t(.cashFlowSummary), systemImage: "exclamationmark.bubble.fill")
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.deepTeal)
                    Text(forecast.summary)
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if forecast.upcomingTotal > 0 {
                        HStack {
                            Text(settings.t(.cashFlowUpcomingTotal))
                                .font(AppFont.caption())
                                .foregroundStyle(BrandTheme.muted)
                            Spacer()
                            Text(CurrencyFormat.egp(forecast.upcomingTotal, language: settings.language))
                                .font(AppFont.headline())
                                .foregroundStyle(BrandTheme.coral)
                        }
                    }
                    if let free = forecast.freeCash {
                        HStack {
                            Text(settings.t(.cashFlowSurplus))
                                .font(AppFont.caption())
                                .foregroundStyle(BrandTheme.muted)
                            Spacer()
                            Text(CurrencyFormat.egp(free, language: settings.language))
                                .font(AppFont.headline())
                                .foregroundStyle(BrandTheme.lagoon)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .masarifyCard(cornerRadius: 18, accent: BrandTheme.coral, fillOpacity: 0.5)

                if forecast.upcoming.isEmpty {
                    Text(settings.t(.cashFlowEmpty))
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.muted)
                        .padding(.vertical, 12)
                } else {
                    Text(settings.t(.cashFlowList))
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)

                    ForEach(forecast.upcoming) { bill in
                        HStack(spacing: 12) {
                            Image(systemName: bill.systemImage)
                                .foregroundStyle(BrandTheme.ember)
                                .frame(width: 36, height: 36)
                                .background(BrandTheme.ember.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bill.label)
                                    .font(AppFont.headline())
                                    .foregroundStyle(BrandTheme.ink)
                                Text(bill.expectedDate, style: .date)
                                    .font(AppFont.caption())
                                    .foregroundStyle(BrandTheme.muted)
                                    .environment(\.locale, AppLanguage.latinDigitsLocale)
                            }
                            Spacer()
                            Text(CurrencyFormat.egp(bill.amount, language: settings.language))
                                .font(AppFont.headline())
                                .foregroundStyle(BrandTheme.ink)
                        }
                        .padding(14)
                        .masarifyCard(cornerRadius: 16, accent: BrandTheme.ember, fillOpacity: 0.4)
                    }
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 16)
            .padding(.bottom, 100)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.cashFlowTitle))
    }
}
