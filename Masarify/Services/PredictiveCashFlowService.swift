import Foundation

/// Predicts upcoming mandatory bills from learned recurring expenses.
enum PredictiveCashFlowService {
    struct UpcomingBill: Identifiable, Equatable {
        var id: String
        var label: String
        var amount: Double
        var expectedDate: Date
        var systemImage: String
    }

    struct Forecast: Equatable {
        var windowDays: Int
        var upcoming: [UpcomingBill]
        var upcomingTotal: Double
        var remainingBudget: Double?
        var freeCash: Double?
        var summary: String
    }

    private static let billHints: [String] = [
        "كهرباء", "نت", "انترنت", "إيجار", "ايجار", "قسط", "مياه", "غاز", "فوري", "ممكن",
        "we ", "etisalat", "vodafone", "orange", "internet", "rent", "installment", "electric",
        "فاتورة", "اشتراك", "netflix", "spotify", "icloud"
    ]

    static func forecast(
        expenses: [Expense],
        budgets: [MonthlyBudget],
        categories: [CategoryItem],
        language: AppLanguage,
        windowDays: Int = 7
    ) -> Forecast {
        let cal = Calendar.current
        let now = Date()
        let horizon = cal.date(byAdding: .day, value: windowDays, to: now) ?? now
        let upcoming = detectUpcoming(expenses: expenses, categories: categories, language: language, from: now, to: horizon, calendar: cal)
        let total = upcoming.reduce(0) { $0 + $1.amount }

        let progress = BudgetMonitor.progress(for: budgets, expenses: expenses, categories: categories)
        let remaining = progress.first(where: \.budget.isOverall)?.remaining
        let free: Double? = remaining.map { max(0, $0 - total) }

        let summary: String = {
            if upcoming.isEmpty {
                return language == .arabic
                    ? "لسه مفيش نمط فواتير واضح — صوّر فواتير الكهرباء/النت/الإيجار كام شهر وهنتوقّعها."
                    : "No clear bill pattern yet — log electricity/net/rent a couple months and we’ll forecast."
            }
            let totalText = CurrencyFormat.egp(total, language: language)
            if let free {
                let freeText = CurrencyFormat.egp(free, language: language)
                return language == .arabic
                    ? "خد بالك، عندك فواتير بـ \(totalText) هتنزل خلال \(windowDays) أيام. المتاح عندك فعليًا كفائض ≈ \(freeText)."
                    : "Heads up: \(totalText) in bills land within \(windowDays) days. Real surplus left ≈ \(freeText)."
            }
            return language == .arabic
                ? "خد بالك، عندك فواتير بـ \(totalText) خلال \(windowDays) أيام الجايين — حدّد ميزانية عشان نحسب الفائض."
                : "Heads up: \(totalText) in bills within \(windowDays) days — set a budget to see surplus."
        }()

        return Forecast(
            windowDays: windowDays,
            upcoming: upcoming.sorted { $0.expectedDate < $1.expectedDate },
            upcomingTotal: total,
            remainingBudget: remaining,
            freeCash: free,
            summary: summary
        )
    }

    private static func detectUpcoming(
        expenses: [Expense],
        categories: [CategoryItem],
        language: AppLanguage,
        from: Date,
        to: Date,
        calendar: Calendar
    ) -> [UpcomingBill] {
        let nonTrip = expenses.filter { !$0.isTripExpense }
        var buckets: [String: [Expense]] = [:]
        for expense in nonTrip where isMandatoryLike(expense) {
            let key = normalizeKey(expense)
            guard !key.isEmpty else { continue }
            buckets[key, default: []].append(expense)
        }

        var results: [UpcomingBill] = []
        for (key, items) in buckets {
            guard items.count >= 2 else { continue }
            let months = Set(items.map { monthKey($0.date, calendar) })
            guard months.count >= 2 else { continue }

            let amounts = items.map(\.amount).sorted()
            let median = amounts[amounts.count / 2]
            guard median >= 30 else { continue }

            let similar = items.filter { abs($0.amount - median) / max(median, 1) <= 0.25 }
            guard similar.count >= 2 else { continue }

            let avgDay = averageDayOfMonth(similar.map(\.date), calendar: calendar)
            guard let next = nextOccurrence(day: avgDay, after: from, calendar: calendar),
                  next <= to else { continue }

            // Skip if already paid this month for same key around that day.
            let paidThisCycle = similar.contains {
                calendar.isDate($0.date, equalTo: next, toGranularity: .month)
                    && abs(calendar.component(.day, from: $0.date) - avgDay) <= 4
                    && $0.date <= from
            }
            if paidThisCycle { continue }

            let label = displayLabel(similar, language: language, categories: categories)
            results.append(
                UpcomingBill(
                    id: key,
                    label: label,
                    amount: median,
                    expectedDate: next,
                    systemImage: "bolt.fill"
                )
            )
        }
        return results
    }

    private static func isMandatoryLike(_ expense: Expense) -> Bool {
        if expense.categoryId == BuiltInCategory.bills.rawValue { return true }
        let blob = "\(expense.note) \(expense.merchant ?? "")".lowercased()
        return billHints.contains(where: { blob.contains($0) })
    }

    private static func normalizeKey(_ expense: Expense) -> String {
        let merchant = (expense.merchant ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let note = expense.note.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = !merchant.isEmpty ? merchant : note
        let cleaned = base
            .replacingOccurrences(of: #"\d+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count >= 3 { return cleaned }
        return expense.categoryId == BuiltInCategory.bills.rawValue ? "bills-\(expense.categoryId)" : cleaned
    }

    private static func monthKey(_ date: Date, _ calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    private static func averageDayOfMonth(_ dates: [Date], calendar: Calendar) -> Int {
        let days = dates.map { calendar.component(.day, from: $0) }
        guard !days.isEmpty else { return 1 }
        return max(1, min(28, Int((Double(days.reduce(0, +)) / Double(days.count)).rounded())))
    }

    private static func nextOccurrence(day: Int, after: Date, calendar: Calendar) -> Date? {
        var comps = calendar.dateComponents([.year, .month], from: after)
        comps.day = day
        comps.hour = 10
        guard var candidate = calendar.date(from: comps) else { return nil }
        if candidate <= after {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: candidate) else { return nil }
            var nc = calendar.dateComponents([.year, .month], from: nextMonth)
            nc.day = day
            nc.hour = 10
            candidate = calendar.date(from: nc) ?? nextMonth
        }
        return candidate
    }

    private static func displayLabel(_ items: [Expense], language: AppLanguage, categories: [CategoryItem]) -> String {
        if let merchant = items.compactMap(\.merchant).first(where: { !$0.isEmpty }) { return merchant }
        if let note = items.map(\.note).first(where: { !$0.isEmpty }) { return note }
        if let id = items.first?.categoryId, let cat = CategoryItem.resolve(id: id, in: categories) {
            return language == .arabic ? cat.nameAr : (cat.nameEn.isEmpty ? cat.nameAr : cat.nameEn)
        }
        return language == .arabic ? "فاتورة" : "Bill"
    }
}
