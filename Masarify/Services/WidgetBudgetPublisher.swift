import Foundation
import SwiftData
import WidgetKit

enum WidgetBudgetPublisher {
    @MainActor
    static func publish(from context: ModelContext, language: AppLanguage) {
        let expenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        let budgets = (try? context.fetch(FetchDescriptor<MonthlyBudget>())) ?? []
        publish(expenses: expenses, budgets: budgets, language: language)
    }

    @MainActor
    static func publish(
        expenses: [Expense],
        budgets: [MonthlyBudget],
        language: AppLanguage,
        calendar: Calendar = .current,
        now: Date = .now
    ) {
        let monthKey = MonthlyBudget.currentMonthKey(for: now, calendar: calendar)
        let overall = budgets.first { $0.monthKey == monthKey && $0.isOverall }
        let monthLimit = overall?.limitAmount ?? 0

        let daysInMonth = Double(calendar.range(of: .day, in: .month, for: now)?.count ?? 30)
        let dayLimit = monthLimit > 0 ? monthLimit / max(daysInMonth, 1) : 0
        let weekLimit = dayLimit * 7

        let dayStart = calendar.startOfDay(for: now)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? dayStart
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
        let monthInterval = MonthlyBudget.monthInterval(for: monthKey) ?? DateInterval(start: dayStart, end: dayEnd)

        let nonTrip = expenses.filter { !$0.isTripExpense }
        let daySpent = nonTrip.filter { $0.date >= dayStart && $0.date < dayEnd }.reduce(0) { $0 + $1.amount }
        let weekSpent = nonTrip.filter { $0.date >= weekStart && $0.date < weekEnd }.reduce(0) { $0 + $1.amount }
        let monthSpent = nonTrip.filter { monthInterval.contains($0.date) }.reduce(0) { $0 + $1.amount }

        let snapshot = WidgetBudgetSnapshot(
            updatedAt: now,
            isArabic: language == .arabic,
            dayLimit: dayLimit,
            daySpent: daySpent,
            weekLimit: weekLimit,
            weekSpent: weekSpent,
            monthLimit: monthLimit,
            monthSpent: monthSpent
        )
        WidgetBudgetStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
