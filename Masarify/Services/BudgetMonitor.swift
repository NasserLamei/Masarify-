import Foundation
import SwiftData

enum BudgetMonitor {
    static func progress(
        for budgets: [MonthlyBudget],
        expenses: [Expense],
        categories: [CategoryItem],
        monthKey: String = MonthlyBudget.currentMonthKey()
    ) -> [BudgetProgress] {
        let monthBudgets = budgets.filter { $0.monthKey == monthKey }
        guard let interval = MonthlyBudget.monthInterval(for: monthKey) else { return [] }

        // Trip expenses stay outside the normal monthly budget.
        let monthExpenses = expenses.filter { interval.contains($0.date) && !$0.isTripExpense }

        return monthBudgets
            .sorted { lhs, rhs in
                if lhs.isOverall != rhs.isOverall { return lhs.isOverall && !rhs.isOverall }
                return lhs.titleAr(categories: categories) < rhs.titleAr(categories: categories)
            }
            .map { budget in
                let spent: Double
                if let categoryId = budget.categoryId {
                    spent = monthExpenses
                        .filter { $0.categoryId == categoryId }
                        .reduce(0) { $0 + $1.amount }
                } else {
                    spent = monthExpenses.reduce(0) { $0 + $1.amount }
                }
                let category = CategoryItem.resolve(id: budget.categoryId, in: categories)
                return BudgetProgress(budget: budget, spent: spent, category: category)
            }
    }

    static func activeAlerts(from progress: [BudgetProgress]) -> [BudgetProgress] {
        progress.filter { $0.level != .ok }
    }
}
