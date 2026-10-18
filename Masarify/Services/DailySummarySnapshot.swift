import Foundation

/// Shared “what did I spend?” snapshot for Home, DailyReport, and notifications.
struct DailySummarySnapshot: Equatable {
    var dayStart: Date
    var total: Double
    var topCategoryId: String?
    var topCategoryLabel: String?
    var remainingBudget: Double?
    var expenseCount: Int

    static func build(
        day: Date,
        expenses: [Expense],
        budgets: [MonthlyBudget],
        categories: [CategoryItem],
        language: AppLanguage
    ) -> DailySummarySnapshot {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else {
            return DailySummarySnapshot(
                dayStart: start,
                total: 0,
                topCategoryId: nil,
                topCategoryLabel: nil,
                remainingBudget: nil,
                expenseCount: 0
            )
        }

        let dayExpenses = expenses.filter { $0.date >= start && $0.date < end }
        let total = dayExpenses.reduce(0) { $0 + $1.amount }

        let grouped = Dictionary(grouping: dayExpenses, by: \.categoryId)
        let topPair = grouped.max { lhs, rhs in
            lhs.value.reduce(0) { $0 + $1.amount } < rhs.value.reduce(0) { $0 + $1.amount }
        }
        let topId = topPair?.key
        let topCat = CategoryItem.resolve(id: topId, in: categories)
        let topLabel: String? = {
            guard let topCat else { return nil }
            switch language {
            case .arabic: return topCat.nameAr
            case .english: return topCat.nameEn.isEmpty ? topCat.nameAr : topCat.nameEn
            }
        }()

        let progress = BudgetMonitor.progress(for: budgets, expenses: expenses, categories: categories)
        let remaining = progress.first(where: \.budget.isOverall)?.remaining

        return DailySummarySnapshot(
            dayStart: start,
            total: total,
            topCategoryId: topId,
            topCategoryLabel: topLabel,
            remainingBudget: remaining,
            expenseCount: dayExpenses.count
        )
    }

    func notificationBody(language: AppLanguage, focusDay: DailySummaryFocusDay = .yesterday) -> String {
        let totalText = CurrencyFormat.egp(total, language: language)
        let top = topCategoryLabel
            ?? (language == .arabic ? "أخرى" : "Other")
        let remainingText: String = {
            guard let remainingBudget else {
                return language == .arabic ? "مفيش ميزانية محددة" : "No monthly budget set"
            }
            return CurrencyFormat.egp(remainingBudget, language: language)
        }()

        switch (language, focusDay) {
        case (.arabic, .today):
            return "صرفت النهاردة إجمالي \(totalText)، أكتر بند كان \(top)، والمتبقي من ميزانيتك \(remainingText)."
        case (.arabic, .yesterday):
            return "صرفت امبارح إجمالي \(totalText)، أكتر بند كان \(top)، والمتبقي من ميزانيتك \(remainingText)."
        case (.english, .today):
            return "Today you spent \(totalText). Top category: \(top). Budget left: \(remainingText)."
        case (.english, .yesterday):
            return "Yesterday you spent \(totalText). Top category: \(top). Budget left: \(remainingText)."
        }
    }

    func notificationTitle(language: AppLanguage, focusDay: DailySummaryFocusDay = .yesterday) -> String {
        switch (language, focusDay) {
        case (.arabic, .today): return "ملخص النهاردة"
        case (.arabic, .yesterday): return "ملخص امبارح"
        case (.english, .today): return "Today’s summary"
        case (.english, .yesterday): return "Yesterday’s summary"
        }
    }
}
