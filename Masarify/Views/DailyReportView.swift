import SwiftUI
import SwiftData

struct DailyReportView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    @State private var appeared = false

    private var todayExpenses: [Expense] {
        let start = Calendar.current.startOfDay(for: .now)
        return expenses.filter { $0.date >= start }
    }

    private var total: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }

    private var categoryTotals: [(ExpenseCategory, Double)] {
        Dictionary(grouping: todayExpenses, by: \.category)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
    }

    private var monthProgress: [BudgetProgress] {
        BudgetMonitor.progress(for: budgets, expenses: expenses)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("تقرير اليوم")
                        .font(AppFont.title())
                        .foregroundStyle(BrandTheme.ink)
                    Text("إجمالي اليوم، أعلى الفئات، وآخر القيود.")
                        .font(AppFont.body())
                        .foregroundStyle(BrandTheme.muted)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("إجمالي اليوم")
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                    Text(CurrencyFormat.egp(total))
                        .font(AppFont.display(40))
                        .foregroundStyle(BrandTheme.ink)
                        .scaleEffect(appeared ? 1 : 0.92)
                        .opacity(appeared ? 1 : 0)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BrandTheme.heroGradient)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                if !monthProgress.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("الميزانية الشهرية")
                            .font(AppFont.title3())
                        ForEach(monthProgress.prefix(4)) { item in
                            BudgetProgressRow(progress: item)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("حسب الفئة")
                        .font(AppFont.title3())

                    if categoryTotals.isEmpty {
                        Text("مفيش بيانات لعرضها النهاردة.")
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.muted)
                    } else {
                        ForEach(categoryTotals, id: \.0) { item in
                            let (category, amount) = item
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label(category.labelAr, systemImage: category.systemImage)
                                        .font(AppFont.headline())
                                        .foregroundStyle(category.tint)
                                    Spacer()
                                    Text(CurrencyFormat.egp(amount))
                                        .font(AppFont.custom(.medium, size: 14))
                                }
                                GeometryReader { geo in
                                    Capsule()
                                        .fill(category.tint.opacity(0.15))
                                        .overlay(alignment: .leading) {
                                            Capsule()
                                                .fill(category.tint)
                                                .frame(width: max(8, geo.size.width * CGFloat(amount / max(total, 1))))
                                        }
                                }
                                .frame(height: 10)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("آخر القيود")
                        .font(AppFont.title3())
                    ForEach(todayExpenses.prefix(8)) { expense in
                        ExpenseRowView(expense: expense)
                        Divider().opacity(0.3)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .background(BrandTheme.foam.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
