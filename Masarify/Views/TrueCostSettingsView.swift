import SwiftUI

struct TrueCostSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var incomeText = ""
    @State private var hoursText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(settings.t(.trueCostHint))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $settings.trueCostEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.t(.trueCostTitle))
                                .font(AppFont.headline())
                                .foregroundStyle(BrandTheme.ink)
                            Text(settings.t(.trueCostHint))
                                .font(AppFont.caption())
                                .foregroundStyle(BrandTheme.muted)
                        }
                    }
                    .tint(BrandTheme.coral)

                    if settings.trueCostEnabled {
                        Text(settings.t(.trueCostIncome))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)
                        MasarifyAmountField(placeholder: "8000", text: $incomeText)
                            .onChange(of: incomeText) { _, value in
                                let normalized = value.replacingOccurrences(of: ",", with: ".")
                                if let income = Double(normalized), income > 0 {
                                    settings.monthlyIncome = income
                                }
                            }

                        Text(settings.t(.trueCostHours))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)
                        MasarifyAmountField(placeholder: "176", text: $hoursText)
                            .onChange(of: hoursText) { _, value in
                                let normalized = value.replacingOccurrences(of: ",", with: ".")
                                if let hours = Double(normalized), hours > 0 {
                                    settings.workHoursPerMonth = hours
                                }
                            }

                        if settings.hourlyRate > 0 {
                            Text(
                                settings.language == .arabic
                                    ? "ساعة شغلك ≈ \(CurrencyFormat.egp(settings.hourlyRate, language: .arabic))"
                                    : "Your hour ≈ \(CurrencyFormat.egp(settings.hourlyRate, language: .english))"
                            )
                            .font(AppFont.headline())
                            .foregroundStyle(BrandTheme.deepTeal)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .masarifyCard(cornerRadius: 18, accent: BrandTheme.coral, fillOpacity: 0.55)
            }
            .masarifyScreenInsets()
            .padding(.vertical, 20)
            .padding(.bottom, 100)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.trueCost))
        .onAppear {
            incomeText = settings.monthlyIncome.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(settings.monthlyIncome))
                : String(settings.monthlyIncome)
            hoursText = settings.workHoursPerMonth.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(settings.workHoursPerMonth))
                : String(settings.workHoursPerMonth)
        }
    }
}
