import Foundation
import SwiftData

@Model
final class MonthlyBudget {
    var id: UUID
    /// `yyyy-MM` for the calendar month this limit applies to.
    var monthKey: String
    /// `nil` means overall monthly limit; otherwise an `ExpenseCategory.rawValue`.
    var categoryRaw: String?
    var limitAmount: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        monthKey: String = MonthlyBudget.currentMonthKey(),
        category: ExpenseCategory? = nil,
        limitAmount: Double,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.monthKey = monthKey
        self.categoryRaw = category?.rawValue
        self.limitAmount = limitAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var category: ExpenseCategory? {
        get {
            guard let categoryRaw else { return nil }
            return ExpenseCategory(rawValue: categoryRaw)
        }
        set { categoryRaw = newValue?.rawValue }
    }

    var isOverall: Bool { categoryRaw == nil }

    var titleAr: String {
        if let category { return category.labelAr }
        return "الإجمالي الشهري"
    }

    static func currentMonthKey(for date: Date = .now, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
    }

    static func monthInterval(for monthKey: String, calendar: Calendar = .current) -> DateInterval? {
        let parts = monthKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = 1
        guard let start = calendar.date(from: comps),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
        return DateInterval(start: start, end: end)
    }
}

enum BudgetAlertLevel: Equatable {
    case ok
    case nearLimit   // ~80%+
    case overBudget

    var bannerTitle: String {
        switch self {
        case .ok: return ""
        case .nearLimit: return "قربت من الحد"
        case .overBudget: return "تجاوزت الميزانية"
        }
    }
}

struct BudgetProgress: Identifiable, Equatable {
    var id: UUID { budget.id }
    let budget: MonthlyBudget
    let spent: Double

    var limit: Double { budget.limitAmount }
    var ratio: Double {
        guard limit > 0 else { return 0 }
        return spent / limit
    }

    var remaining: Double { max(0, limit - spent) }

    var level: BudgetAlertLevel {
        if spent > limit { return .overBudget }
        if ratio >= 0.8 { return .nearLimit }
        return .ok
    }
}
