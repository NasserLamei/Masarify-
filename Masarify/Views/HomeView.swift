import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Expense.createdAt, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]

    let onVoice: () -> Void
    let onCamera: () -> Void
    let onAdd: () -> Void
    let onSeeAll: () -> Void
    var onBudgets: (() -> Void)? = nil

    private var todayExpenses: [Expense] {
        let start = Calendar.current.startOfDay(for: .now)
        return expenses.filter { $0.date >= start }
    }

    private var todayTotal: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }

    private var topCategory: ExpenseCategory? {
        let grouped = Dictionary(grouping: todayExpenses, by: \.category)
        return grouped.max(by: { lhs, rhs in
            lhs.value.reduce(0) { $0 + $1.amount } < rhs.value.reduce(0) { $0 + $1.amount }
        })?.key
    }

    private var budgetAlerts: [BudgetProgress] {
        BudgetMonitor.activeAlerts(
            from: BudgetMonitor.progress(for: budgets, expenses: expenses)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BrandHeroView()

                if !budgetAlerts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("تنبيهات الميزانية")
                            .font(AppFont.title3())
                            .foregroundStyle(BrandTheme.ink)
                        ForEach(budgetAlerts.prefix(3)) { alert in
                            BudgetAlertBanner(progress: alert)
                        }
                        if let onBudgets {
                            Button("إدارة الميزانية", action: onBudgets)
                                .font(AppFont.subheadline())
                                .foregroundStyle(BrandTheme.deepTeal)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("تقرير اليوم")
                        .font(AppFont.title2())
                        .foregroundStyle(BrandTheme.ink)
                    Text("ملخص سريع لما صرفته النهاردة.")
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.muted)

                    HStack(spacing: 12) {
                        StatBlock(title: "الإجمالي", value: CurrencyFormat.egp(todayTotal))
                        StatBlock(
                            title: "أعلى فئة",
                            value: topCategory?.labelAr ?? "—"
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("آخر المصروفات")
                            .font(AppFont.title3())
                        Spacer()
                        Button("عرض الكل", action: onSeeAll)
                            .font(AppFont.custom(.medium, size: 14))
                            .foregroundStyle(BrandTheme.deepTeal)
                    }

                    if todayExpenses.isEmpty {
                        Text("لسه مفيش مصروفات النهاردة. سجّل بالصوت أو الكاميرا.")
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.muted)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(todayExpenses.prefix(5))) { expense in
                            ExpenseRowView(expense: expense)
                            Divider().opacity(0.35)
                        }
                    }
                }

                Button(action: onAdd) {
                    Label("إضافة مصروف", systemImage: "plus.circle.fill")
                        .font(AppFont.headline())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandTheme.deepTeal)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .background(
            LinearGradient(
                colors: [BrandTheme.foam, BrandTheme.mist.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("مصاريفي")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onVoice) {
                    Image(systemName: "mic.fill")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onCamera) {
                    Image(systemName: "camera.fill")
                }
            }
        }
    }
}

private struct StatBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)
            Text(value)
                .font(AppFont.custom(.bold, size: 18))
                .foregroundStyle(BrandTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
