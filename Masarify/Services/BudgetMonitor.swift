import Foundation
import SwiftData

enum BudgetMonitor {
    static func progress(
        for budgets: [MonthlyBudget],
        expenses: [Expense],
        monthKey: String = MonthlyBudget.currentMonthKey()
    ) -> [BudgetProgress] {
        let monthBudgets = budgets.filter { $0.monthKey == monthKey }
        guard let interval = MonthlyBudget.monthInterval(for: monthKey) else { return [] }

        let monthExpenses = expenses.filter { interval.contains($0.date) }

        return monthBudgets
            .sorted { lhs, rhs in
                if lhs.isOverall != rhs.isOverall { return lhs.isOverall && !rhs.isOverall }
                return lhs.titleAr < rhs.titleAr
            }
            .map { budget in
                let spent: Double
                if let category = budget.category {
                    spent = monthExpenses
                        .filter { $0.category == category }
                        .reduce(0) { $0 + $1.amount }
                } else {
                    spent = monthExpenses.reduce(0) { $0 + $1.amount }
                }
                return BudgetProgress(budget: budget, spent: spent)
            }
    }

    static func activeAlerts(from progress: [BudgetProgress]) -> [BudgetProgress] {
        progress.filter { $0.level != .ok }
    }
}
