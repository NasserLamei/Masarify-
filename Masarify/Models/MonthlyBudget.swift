import Foundation
import SwiftData

@Model
final class MonthlyBudget {
    var id: UUID
    /// `yyyy-MM` for the calendar month this limit applies to.
    var monthKey: String
    /// `nil` means overall monthly limit; otherwise a `CategoryItem.id`.
    var categoryRaw: String?
    var limitAmount: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        monthKey: String = MonthlyBudget.currentMonthKey(),
        categoryId: String? = nil,
        limitAmount: Double,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.monthKey = monthKey
        self.categoryRaw = categoryId
        self.limitAmount = limitAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var categoryId: String? {
        get { categoryRaw }
        set { categoryRaw = newValue }
    }

    var isOverall: Bool { categoryRaw == nil }

    func titleAr(categories: [CategoryItem]) -> String {
        guard let categoryId else { return "الإجمالي الشهري" }
        return CategoryItem.resolve(id: categoryId, in: categories)?.labelAr ?? categoryId
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

    var bannerTitle: String { bannerTitle(language: .arabic) }

    func bannerTitle(language: AppLanguage) -> String {
        switch (self, language) {
        case (.ok, _): return ""
        case (.nearLimit, .arabic): return "قربت من الحد"
        case (.nearLimit, .english): return "Near limit"
        case (.overBudget, .arabic): return "تجاوزت الميزانية"
        case (.overBudget, .english): return "Over budget"
        }
    }
}

struct BudgetProgress: Identifiable, Equatable {
    var id: UUID { budget.id }
    let budget: MonthlyBudget
    let spent: Double
    let category: CategoryItem?

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

    static func == (lhs: BudgetProgress, rhs: BudgetProgress) -> Bool {
        lhs.budget.id == rhs.budget.id
            && lhs.spent == rhs.spent
            && lhs.category?.id == rhs.category?.id
    }
}
