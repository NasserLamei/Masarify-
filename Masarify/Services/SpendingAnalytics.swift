import Foundation

enum SpendingPeriod: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }
}

struct CategorySpendSlice: Identifiable, Equatable {
    var id: String { categoryId }
    let categoryId: String
    let label: String
    let tintHex: Int
    let amount: Double
    let percent: Double
}

struct DaySpendPoint: Identifiable, Equatable {
    var id: Date { day }
    let day: Date
    let amount: Double
    let label: String
}

enum SpendingAnalytics {
    static func range(for period: SpendingPeriod, now: Date = .now, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let end = calendar.startOfDay(for: now).addingTimeInterval(86_400) // exclusive end tomorrow
        switch period {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
            return (start, end)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: comps) ?? now
            return (start, end)
        }
    }

    static func expenses(
        in period: SpendingPeriod,
        from all: [Expense],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Expense] {
        let (start, end) = range(for: period, now: now, calendar: calendar)
        return all.filter { $0.date >= start && $0.date < end && !$0.isTripExpense }
    }

    static func categorySlices(
        expenses: [Expense],
        categories: [CategoryItem],
        language: AppLanguage
    ) -> [CategorySpendSlice] {
        let total = expenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: expenses, by: \.categoryId)
        return grouped.compactMap { id, items -> CategorySpendSlice? in
            let amount = items.reduce(0) { $0 + $1.amount }
            guard amount > 0 else { return nil }
            let cat = CategoryItem.resolve(id: id, in: categories)
            let label: String = {
                guard let cat else { return id }
                switch language {
                case .arabic: return cat.nameAr
                case .english: return cat.nameEn.isEmpty ? cat.nameAr : cat.nameEn
                }
            }()
            return CategorySpendSlice(
                categoryId: id,
                label: label,
                tintHex: cat?.tintHex ?? 0x64748B,
                amount: amount,
                percent: amount / total
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    /// Daily totals across the period (for bar chart).
    static func dailyPoints(
        expenses: [Expense],
        period: SpendingPeriod,
        language: AppLanguage,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [DaySpendPoint] {
        let (start, end) = range(for: period, now: now, calendar: calendar)
        var days: [Date] = []
        var cursor = start
        while cursor < end {
            days.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = period == .week ? "EEE" : "d"

        return days.map { day in
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let amount = expenses
                .filter { $0.date >= day && $0.date < next }
                .reduce(0) { $0 + $1.amount }
            return DaySpendPoint(day: day, amount: amount, label: formatter.string(from: day))
        }
    }

    static func topDrain(slices: [CategorySpendSlice]) -> CategorySpendSlice? {
        slices.first
    }
}
