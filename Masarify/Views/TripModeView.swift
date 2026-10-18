import SwiftUI
import SwiftData

struct TripModeView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Trip> { $0.isActive }, sort: \Trip.startedAt, order: .reverse)
    private var activeTrips: [Trip]
    @Query(sort: \Trip.startedAt, order: .reverse) private var allTrips: [Trip]
    @Query private var expenses: [Expense]

    @State private var title = ""
    @State private var budgetText = ""
    @State private var currency: TripCurrency = .egp
    @State private var rateText = ""
    @State private var showStartForm = false

    private var activeTrip: Trip? { activeTrips.first }

    private var tripSpentEGP: Double {
        guard let trip = activeTrip else { return 0 }
        return expenses
            .filter { $0.tripIdRaw == trip.id.uuidString }
            .reduce(0) { $0 + $1.amount }
    }

    private var tripProgress: Double {
        guard let trip = activeTrip, trip.budgetEGP > 0 else { return 0 }
        return min(1, tripSpentEGP / trip.budgetEGP)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(settings.t(.tripHint))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 4)

                if let trip = activeTrip {
                    activeTripCard(trip)
                } else {
                    emptyTripCard
                }

                if showStartForm || activeTrip == nil {
                    startForm
                }

                if !allTrips.filter({ !$0.isActive }).isEmpty {
                    Text(settings.language == .arabic ? "رحلات سابقة" : "Past trips")
                        .font(AppFont.title3())
                        .foregroundStyle(BrandTheme.ink)
                    ForEach(allTrips.filter { !$0.isActive }.prefix(5), id: \.id) { trip in
                        pastTripRow(trip)
                    }
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.tripMode))
        .onAppear {
            rateText = String(format: "%.2f", currency.defaultRateToEGP)
        }
        .onChange(of: currency) { _, newValue in
            rateText = String(format: "%.2f", newValue.defaultRateToEGP)
        }
    }

    private var emptyTripCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(settings.t(.tripMode), systemImage: "airplane.departure")
                .font(AppFont.headline())
                .foregroundStyle(BrandTheme.azure)
            Text(settings.t(.tripEmpty))
                .font(AppFont.subheadline())
                .foregroundStyle(BrandTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BrandTheme.azure.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func activeTripCard(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundStyle(BrandTheme.azure)
                Text(trip.title)
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                Spacer()
                Text(settings.t(.tripActive))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.azure)
            }

            AnimatedProgressBar(progress: tripProgress, tint: BrandTheme.azure)

            HStack {
                Text(CurrencyFormat.egp(tripSpentEGP, language: settings.language))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
                Spacer()
                Text(CurrencyFormat.egp(trip.budgetEGP, language: settings.language))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.ink)
            }

            if trip.currency != .egp {
                Text(
                    settings.language == .arabic
                        ? "العملة: \(trip.currency.label(.arabic)) · ١ = \(String(format: "%.2f", trip.exchangeRateToEGP)) ج.م"
                        : "Currency: \(trip.currency.label(.english)) · 1 = \(String(format: "%.2f", trip.exchangeRateToEGP)) EGP"
                )
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)
            }

            Text(settings.t(.tripSeparated))
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.deepTeal)

            Button(role: .destructive) {
                endTrip(trip)
            } label: {
                Text(settings.t(.tripEnd))
                    .font(AppFont.headline())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(BrandTheme.coral)
        }
        .padding(16)
        .masarifyCard(cornerRadius: 20, accent: BrandTheme.deepTeal, fillOpacity: 0.55)
    }

    private var startForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(settings.t(.tripStart))
                .font(AppFont.title3())
                .foregroundStyle(BrandTheme.ink)

            TextField(settings.language == .arabic ? "اسم الرحلة / المصيف" : "Trip name", text: $title)
                .masarifyFieldFont(16)
                .font(AppFont.body())
                .padding(12)
                .background(BrandTheme.glass.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            MasarifyAmountField(placeholder: settings.t(.tripBudget), text: $budgetText)
                .font(AppFont.body())
                .padding(12)
                .background(BrandTheme.glass.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(settings.t(.tripCurrency))
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TripCurrency.allCases) { code in
                        Button {
                            currency = code
                        } label: {
                            Text(code.rawValue)
                                .font(AppFont.caption())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(currency == code ? BrandTheme.azure.opacity(0.2) : BrandTheme.glass.opacity(0.5))
                                .foregroundStyle(currency == code ? BrandTheme.azure : BrandTheme.ink)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if currency != .egp {
                Text(settings.t(.tripRate))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
                MasarifyAmountField(placeholder: "48.50", text: $rateText)
                    .font(AppFont.body())
                    .padding(12)
                    .background(BrandTheme.glass.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button(action: startTrip) {
                Text(settings.t(.tripStart))
                    .font(AppFont.headline())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(BrandTheme.brandGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableStyle())
            .disabled(activeTrip != nil)
        }
        .padding(16)
        .background(BrandTheme.glass.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func pastTripRow(_ trip: Trip) -> some View {
        let spent = expenses.filter { $0.tripIdRaw == trip.id.uuidString }.reduce(0) { $0 + $1.amount }
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.ink)
                Text("\(CurrencyFormat.egp(spent, language: settings.language)) / \(CurrencyFormat.egp(trip.budgetEGP, language: settings.language))")
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
            }
            Spacer()
            Text(trip.currencyCode)
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.azure)
        }
        .padding(14)
        .background(BrandTheme.glass.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startTrip() {
        guard activeTrip == nil else { return }
        let budget = Double(budgetText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let rate = Double(rateText.replacingOccurrences(of: ",", with: ".")) ?? currency.defaultRateToEGP
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, budget > 0 else { return }

        // Budget entered in trip currency → store as EGP
        let budgetEGP = currency == .egp ? budget : budget * rate
        let trip = Trip(
            title: name,
            budgetEGP: budgetEGP,
            currency: currency,
            exchangeRateToEGP: rate,
            isActive: true
        )
        modelContext.insert(trip)
        title = ""
        budgetText = ""
        showStartForm = false
    }

    private func endTrip(_ trip: Trip) {
        trip.isActive = false
        trip.endedAt = .now
    }
}
