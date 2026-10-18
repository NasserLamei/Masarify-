import SwiftUI
import SwiftData

struct DailyReportView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @State private var appeared = false
    @State private var dayMode: DayMode = .today

    enum DayMode: String, CaseIterable, Identifiable {
        case today, yesterday
        var id: String { rawValue }
    }

    private var focusDay: Date {
        let cal = Calendar.current
        switch dayMode {
        case .today: return .now
        case .yesterday: return cal.date(byAdding: .day, value: -1, to: .now) ?? .now
        }
    }

    private var snapshot: DailySummarySnapshot {
        DailySummarySnapshot.build(
            day: focusDay,
            expenses: expenses,
            budgets: budgets,
            categories: categories,
            language: settings.language
        )
    }

    private var dayExpenses: [Expense] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: focusDay)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
        return expenses.filter { $0.date >= start && $0.date < end }
    }

    private var categoryTotals: [(CategoryItem, Double)] {
        Dictionary(grouping: dayExpenses, by: \.categoryId)
            .compactMap { id, items -> (CategoryItem, Double)? in
                guard let category = CategoryItem.resolve(id: id, in: categories) else { return nil }
                return (category, items.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.1 > $1.1 }
    }

    private var monthProgress: [BudgetProgress] {
        BudgetMonitor.progress(for: budgets, expenses: expenses, categories: categories)
    }

    private var titleText: String {
        switch dayMode {
        case .today: return settings.t(.todayReport)
        case .yesterday: return settings.t(.yesterdayReport)
        }
    }

    private var subtitleText: String {
        switch dayMode {
        case .today: return settings.t(.todayReportSubtitle)
        case .yesterday: return settings.t(.yesterdayReportSubtitle)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Picker("", selection: $dayMode) {
                    Text(settings.t(.filterToday)).tag(DayMode.today)
                    Text(settings.t(.yesterday)).tag(DayMode.yesterday)
                }
                .pickerStyle(.segmented)
                .padding(.top, 4)

                Text(subtitleText)
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)

                VStack(alignment: .leading, spacing: 10) {
                    Text(settings.t(.total))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.ink.opacity(0.65))
                    Text(CurrencyFormat.egp(snapshot.total, language: settings.language))
                        .font(AppFont.display(42))
                        .foregroundStyle(BrandTheme.deepTeal)
                        .contentTransition(.numericText())
                        .scaleEffect(appeared ? 1 : 0.9)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    if let top = snapshot.topCategoryLabel {
                        Text("\(settings.t(.topCategory)): \(top)")
                            .font(AppFont.subheadline())
                            .foregroundStyle(BrandTheme.muted)
                    }

                    if let remaining = snapshot.remainingBudget {
                        Text("\(settings.t(.balanceRemaining)): \(CurrencyFormat.egp(remaining, language: settings.language))")
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.deepTeal)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .masarifyCard(cornerRadius: 22, accent: BrandTheme.deepTeal, fillOpacity: 0.72)
                .masarifyAppear(0)

                if !monthProgress.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(settings.t(.budgets))
                            .font(AppFont.title3())
                            .foregroundStyle(BrandTheme.ink)
                        ForEach(monthProgress.prefix(4)) { item in
                            BudgetProgressRow(progress: item)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text(settings.t(.categories))
                        .font(AppFont.title3())
                        .foregroundStyle(BrandTheme.ink)

                    if categoryTotals.isEmpty {
                        Text(dayMode == .today ? settings.t(.emptyToday) : settings.t(.emptyYesterday))
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.muted)
                    } else {
                        ForEach(categoryTotals, id: \.0.id) { item in
                            let (category, amount) = item
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label(settings.categoryLabel(category), systemImage: category.systemImage)
                                        .font(AppFont.headline())
                                        .foregroundStyle(category.tint)
                                    Spacer()
                                    Text(CurrencyFormat.egp(amount, language: settings.language))
                                        .font(AppFont.custom(.medium, size: 14))
                                        .foregroundStyle(BrandTheme.ink)
                                }
                                AnimatedProgressBar(
                                    progress: amount / max(snapshot.total, 1),
                                    tint: category.tint
                                )
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(settings.t(.recentExpenses))
                        .font(AppFont.title3())
                        .foregroundStyle(BrandTheme.ink)
                    ForEach(dayExpenses.prefix(8)) { expense in
                        ExpenseRowView(expense: expense)
                        Divider().opacity(0.3)
                    }
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 20)
            .padding(.bottom, 100)
            .animation(Motion.gentle, value: dayMode)
        }
        .masarifyScreenBackground()
        .masarifyLeadingTrailingChrome(title: titleText)
        .onAppear {
            withAnimation(Motion.softSpring) {
                appeared = true
            }
        }
    }
}
