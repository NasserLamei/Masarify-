import SwiftUI
import SwiftData

struct ExpenseFormView: View {
    enum Mode {
        case create
        case edit(Expense)
        case draft(ExpenseDraft)
    }

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @Query(filter: #Predicate<SavingsGoal> { !$0.isArchived }, sort: \SavingsGoal.createdAt)
    private var goals: [SavingsGoal]
    @Query(filter: #Predicate<Trip> { $0.isActive }) private var activeTrips: [Trip]

    let mode: Mode

    @State private var amountText: String = ""
    @State private var categoryId: String = BuiltInCategory.food.rawValue
    @State private var note: String = ""
    @State private var merchant: String = ""
    @State private var date: Date = .now
    @State private var source: ExpenseSource = .manual
    @State private var showValidation = false
    @State private var showSavedToast = false
    @State private var showLuxuryAlert = false
    @State private var pendingAmount: Double?
    @State private var assignToTrip = false

    private var activeTrip: Trip? { activeTrips.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if settings.emergencyModeEnabled {
                    emergencyBanner
                }

                if let tip = goalTipText {
                    MasarifyPanel(tint: BrandTheme.highlight) {
                        Label(tip, systemImage: "sparkles")
                            .font(AppFont.subheadline())
                            .foregroundStyle(BrandTheme.ink)
                    }
                }

                if let roundTip = roundUpPreviewText {
                    MasarifyPanel(tint: BrandTheme.lagoon) {
                        Label(roundTip, systemImage: "arrow.up.forward.circle.fill")
                            .font(AppFont.subheadline())
                            .foregroundStyle(BrandTheme.ink)
                    }
                }

                if let trueTip = trueCostPreviewText {
                    MasarifyPanel(tint: BrandTheme.coral) {
                        Label(trueTip, systemImage: "clock.badge.exclamationmark.fill")
                            .font(AppFont.subheadline())
                            .foregroundStyle(BrandTheme.ink)
                    }
                }

                if let trip = activeTrip {
                    MasarifyFormCard(header: settings.t(.tripMode)) {
                        Toggle(isOn: $assignToTrip) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(settings.t(.tripExpense)): \(trip.title)")
                                    .font(AppFont.headline())
                                    .foregroundStyle(BrandTheme.ink)
                                Text(settings.t(.tripSeparated))
                                    .font(AppFont.caption())
                                    .foregroundStyle(BrandTheme.muted)
                                if trip.currency != .egp {
                                    Text(
                                        settings.language == .arabic
                                            ? "المبلغ بـ \(trip.currencyCode) → يتحول تلقائي للجنيه"
                                            : "Amount in \(trip.currencyCode) → auto-converted to EGP"
                                    )
                                    .font(AppFont.caption())
                                    .foregroundStyle(BrandTheme.azure)
                                }
                            }
                        }
                        .tint(BrandTheme.azure)
                    }
                }

                MasarifyFormCard(header: amountHeader) {
                    MasarifyAmountField(placeholder: "0.00", text: $amountText, fontSize: 22)
                    if assignToTrip, let trip = activeTrip, trip.currency != .egp,
                       let foreign = Double(WesternDigits.normalize(amountText).replacingOccurrences(of: ",", with: ".")), foreign > 0 {
                        Text("≈ \(CurrencyFormat.egp(trip.toEGP(foreign), language: settings.language))")
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.azure)
                    }
                }

                MasarifyFormCard(header: settings.t(.categories)) {
                    MasarifyMenuPicker(
                        title: settings.language == .arabic ? "الفئة" : "Category",
                        options: categories.map { ($0.id, settings.categoryLabel($0)) },
                        selection: $categoryId
                    )
                }

                MasarifyFormCard(header: settings.language == .arabic ? "التفاصيل" : "Details") {
                    VStack(alignment: .leading, spacing: 14) {
                        TextField(settings.language == .arabic ? "ملاحظة" : "Note", text: $note)
                            .masarifyFieldFont(16)
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.ink)

                        TextField(settings.language == .arabic ? "التاجر (اختياري)" : "Merchant (optional)", text: $merchant)
                            .masarifyFieldFont(16)
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.ink)

                        DatePicker(selection: $date, displayedComponents: .date) {
                            Text(settings.language == .arabic ? "التاريخ" : "Date")
                                .font(AppFont.body())
                                .foregroundStyle(BrandTheme.ink)
                        }
                        // Western digits in date even when UI is Arabic.
                        .environment(\.locale, AppLanguage.latinDigitsLocale)
                        .environment(\.layoutDirection, settings.language.layoutDirection)
                        .font(AppFont.body())
                    }
                }

                if showValidation {
                    Text(settings.language == .arabic
                         ? "أدخل مبلغًا صحيحًا أكبر من صفر."
                         : "Enter a valid amount greater than zero.")
                        .font(AppFont.subheadline())
                        .foregroundStyle(.red)
                }

                if case .edit = mode {
                    Button(role: .destructive) {
                        deleteExpense()
                    } label: {
                        Text(settings.t(.delete))
                            .font(AppFont.headline())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 12)
        }
        .background(BrandTheme.foam.ignoresSafeArea())
        .environment(\.font, AppFont.body())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            MasarifyCustomHeader(title: title) {
                MasarifyHeaderTextButton(title: settings.t(.cancel)) { dismiss() }
            } trailing: {
                MasarifyHeaderTextButton(title: settings.t(.save), prominent: true) { attemptSave() }
            }
        }
        .background(MasarifyChromeHost())
        .masarifyToast(
            isPresented: $showSavedToast,
            title: settings.language == .arabic ? "تم الحفظ" : "Saved",
            subtitle: settings.language == .arabic ? "اتضاف المصروف بنجاح" : "Expense added"
        )
        .alert(settings.t(.luxuryBlockTitle), isPresented: $showLuxuryAlert) {
            Button(settings.t(.keepBlocked), role: .cancel) {}
            Button(settings.t(.saveAnyway), role: .destructive) {
                if let pendingAmount { commitSave(amount: pendingAmount) }
            }
        } message: {
            Text(settings.t(.luxuryBlockBody))
        }
        .onAppear {
            CategoryItem.seedDefaults(into: modelContext)
            hydrate()
            if categories.first(where: { $0.id == categoryId }) == nil {
                categoryId = categories.first?.id ?? BuiltInCategory.other.rawValue
            }
            AppAppearance.apply()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                AppAppearance.refreshLiveChrome()
            }
        }
    }

    private var emergencyBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lifepreserver.fill")
            Text(settings.t(.emergencyTitle))
                .font(AppFont.headline())
            Spacer()
            Text(NecessityClassifier.kind(for: categoryId).label(settings.language))
                .font(AppFont.caption())
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(BrandTheme.emergencyGradient)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var goalTipText: String? {
        guard let amount = Double(WesternDigits.normalize(amountText).replacingOccurrences(of: ",", with: ".")), amount > 0,
              let goal = goals.first else { return nil }
        let pct = goal.percentToward(amount: amount)
        guard pct > 0.05 else { return nil }
        let formatted = String(format: "%.1f", pct)
        if settings.language == .arabic {
            return "المبلغ ده يقربك من «\(goal.title)» بنسبة \(formatted)% — \(settings.t(.goalCloser))."
        }
        return "This amount moves you \(formatted)% closer to “\(goal.title)”."
    }

    private var roundUpPreviewText: String? {
        guard settings.roundUpEnabled else { return nil }
        switch mode {
        case .create, .draft: break
        case .edit: return nil
        }
        guard let amount = Double(WesternDigits.normalize(amountText).replacingOccurrences(of: ",", with: ".")), amount > 0 else { return nil }
        let result = RoundUpService.compute(amount: amount)
        guard result.hasSpare else { return nil }
        let spareText = CurrencyFormat.egp(result.spare, language: settings.language)
        let roundedText = CurrencyFormat.egp(result.rounded, language: settings.language)
        if settings.language == .arabic {
            return "\(settings.t(.roundUpOnSave)): هيتقفل على \(roundedText) ويتوحّش \(spareText) في الحصالة."
        }
        return "\(settings.t(.roundUpOnSave)): rounds to \(roundedText), stashes \(spareText)."
    }

    private var trueCostPreviewText: String? {
        guard settings.trueCostEnabled, settings.monthlyIncome > 0 else { return nil }
        guard let amount = Double(WesternDigits.normalize(amountText).replacingOccurrences(of: ",", with: ".")), amount > 0 else { return nil }
        let isLuxury = NecessityClassifier.kind(for: categoryId) == .luxury
        guard let result = TrueCostService.compute(
            amount: amount,
            monthlyIncome: settings.monthlyIncome,
            hoursPerMonth: settings.workHoursPerMonth,
            isLuxury: isLuxury
        ), result.shouldHighlight else { return nil }
        let name = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (selectedCategory.map { settings.categoryLabel($0) } ?? (settings.language == .arabic ? "المصروف" : "this"))
            : note
        return result.message(itemName: name, language: settings.language)
    }

    private var title: String {
        switch mode {
        case .create: return settings.t(.addExpense)
        case .edit: return settings.language == .arabic ? "تعديل مصروف" : "Edit expense"
        case .draft: return settings.language == .arabic ? "مراجعة وحفظ" : "Review & save"
        }
    }

    private var amountHeader: String {
        if assignToTrip, let trip = activeTrip, trip.currency != .egp {
            return settings.language == .arabic
                ? "المبلغ (\(trip.currencyCode))"
                : "Amount (\(trip.currencyCode))"
        }
        return settings.language == .arabic ? "المبلغ" : "Amount"
    }

    private var selectedCategory: CategoryItem? {
        CategoryItem.resolve(id: categoryId, in: categories)
    }

    private func hydrate() {
        switch mode {
        case .create:
            source = .manual
            categoryId = categories.first?.id ?? BuiltInCategory.food.rawValue
            assignToTrip = activeTrip != nil
        case .edit(let expense):
            amountText = expense.amount.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(expense.amount))
                : String(expense.amount)
            categoryId = expense.categoryId
            note = expense.note
            merchant = expense.merchant ?? ""
            date = expense.date
            source = expense.source
        case .draft(let draft):
            if let amount = draft.amount {
                amountText = amount.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(amount))
                    : String(amount)
            }
            categoryId = draft.categoryId
                ?? categories.first?.id
                ?? BuiltInCategory.other.rawValue
            note = draft.note
            merchant = draft.merchant ?? ""
            date = draft.date
            source = draft.source
        }
    }

    private func attemptSave() {
        let normalized = WesternDigits.normalize(amountText)
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(normalized), amount > 0 else {
            showValidation = true
            return
        }
        showValidation = false

        if settings.emergencyModeEnabled,
           NecessityClassifier.kind(for: categoryId) == .luxury,
           case .create = mode {
            pendingAmount = amount
            showLuxuryAlert = true
            return
        }
        if settings.emergencyModeEnabled,
           NecessityClassifier.kind(for: categoryId) == .luxury,
           case .draft = mode {
            pendingAmount = amount
            showLuxuryAlert = true
            return
        }

        commitSave(amount: amount)
    }

    private func commitSave(amount: Double) {
        switch mode {
        case .create, .draft:
            let trip = assignToTrip ? activeTrip : nil
            let original = amount
            let rate = trip?.exchangeRateToEGP ?? 1
            let currency = trip?.currencyCode ?? "EGP"
            let egpAmount: Double = {
                guard let trip, trip.currency != .egp else { return amount }
                return trip.toEGP(amount)
            }()

            // Keep note empty when it's just the category — row shows localized categoryLabel.
            let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            let expense = Expense(
                amount: egpAmount,
                categoryId: categoryId,
                note: trimmedNote,
                merchant: merchant.isEmpty ? nil : merchant,
                date: date,
                source: source,
                tripId: trip?.id,
                currencyCode: currency,
                originalAmount: original,
                exchangeRateToEGP: rate
            )
            modelContext.insert(expense)

            // Round-up only for normal (non-trip) spends. True-cost stays as inline tip — no popup.
            if trip == nil {
                _ = RoundUpService.applyIfNeeded(amount: egpAmount, settings: settings, goals: goals)
            }
        case .edit(let expense):
            expense.amount = amount
            expense.categoryId = categoryId
            expense.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            expense.merchant = merchant.isEmpty ? nil : merchant
            expense.date = date
        }
        try? modelContext.save()
        WidgetBudgetPublisher.publish(from: modelContext, language: settings.language)
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            dismiss()
        }
    }

    private func deleteExpense() {
        if case .edit(let expense) = mode {
            modelContext.delete(expense)
            try? modelContext.save()
            WidgetBudgetPublisher.publish(from: modelContext, language: settings.language)
            dismiss()
        }
    }
}
