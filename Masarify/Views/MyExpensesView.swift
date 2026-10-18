import SwiftUI
import SwiftData

private struct ExpenseDayGroup: Identifiable {
    let id: Date
    let day: Date
    let expenses: [Expense]
}

/// Full expense list — category filter, grouped by day (newest / last-added first).
struct MyExpensesView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]

    @State private var categoryId: String? = nil

    private var filtered: [Expense] {
        expenses.filter { expense in
            guard let categoryId else { return true }
            return expense.categoryId == categoryId
        }
    }

    /// Days newest-first; within each day keep last-added order (query already reverse by date).
    private var dayGroups: [ExpenseDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filtered) { expense in
            calendar.startOfDay(for: expense.date)
        }
        return grouped.keys.sorted(by: >).map { day in
            ExpenseDayGroup(
                id: day,
                day: day,
                expenses: (grouped[day] ?? []).sorted { $0.date > $1.date }
            )
        }
    }

    private var filteredTotal: Double {
        filtered.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                Text(settings.t(.myExpensesHint))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)

                categoryFilterRow

                if !filtered.isEmpty {
                    HStack {
                        Text(settings.t(.total))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)
                        Spacer()
                        Text(CurrencyFormat.egp(filteredTotal, language: settings.language))
                            .font(AppFont.custom(.bold, size: 17))
                            .foregroundStyle(BrandTheme.deepTeal)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 4)
                }

                if expenses.isEmpty {
                    emptyState(
                        title: settings.t(.emptyExpenses),
                        detail: settings.t(.emptyExpensesHint)
                    )
                } else if filtered.isEmpty {
                    emptyState(
                        title: settings.language == .arabic ? "مفيش نتائج للفلتر ده" : "No results for this filter",
                        detail: settings.language == .arabic
                            ? "جرّب فئة تانية."
                            : "Try another category."
                    )
                } else {
                    ForEach(dayGroups) { group in
                        Section {
                            ForEach(group.expenses) { expense in
                                NavigationLink {
                                    ExpenseFormView(mode: .edit(expense))
                                } label: {
                                    ExpenseRowView(expense: expense, showDate: true)
                                        .padding(14)
                                        .masarifyCard(cornerRadius: 18, accent: BrandTheme.deepTeal, fillOpacity: 0.55)
                                }
                                .buttonStyle(PressableStyle())
                            }
                        } header: {
                            dayHeader(for: group)
                        }
                    }
                }
            }
            .masarifyScreenInsets()
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .masarifyScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            MasarifyCustomHeader(title: settings.t(.myExpenses)) {
                MasarifyHeaderTextButton(title: settings.t(.cancel)) { dismiss() }
            } trailing: {
                Color.clear.frame(width: 76, height: 1)
            }
        }
        .background(MasarifyChromeHost())
        .onAppear {
            AppAppearance.apply()
            DispatchQueue.main.async {
                AppAppearance.refreshLiveChrome()
            }
        }
        .animation(Motion.snappy, value: categoryId)
    }

    private func dayHeader(for group: ExpenseDayGroup) -> some View {
        let dayTotal = group.expenses.reduce(0) { $0 + $1.amount }
        return HStack(alignment: .firstTextBaseline) {
            Text(dayTitle(for: group.day))
                .font(AppFont.headline())
                .foregroundStyle(BrandTheme.ink)
            Spacer()
            Text(CurrencyFormat.egp(dayTotal, language: settings.language))
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.azure)
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
    }

    private func dayTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) {
            return settings.language == .arabic ? "النهاردة" : "Today"
        }
        if calendar.isDateInYesterday(day) {
            return settings.language == .arabic ? "امبارح" : "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.locale = settings.language.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: day)
    }

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(
                    title: settings.t(.filterAllCategories),
                    tint: BrandTheme.deepTeal,
                    selected: categoryId == nil
                ) {
                    categoryId = nil
                }

                ForEach(categories) { category in
                    categoryChip(
                        title: settings.categoryLabel(category),
                        tint: category.tint,
                        selected: categoryId == category.id
                    ) {
                        categoryId = category.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func categoryChip(title: String, tint: Color, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(AppFont.caption())
                    .foregroundStyle(selected ? .white : BrandTheme.ink)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if selected {
                    Capsule().fill(tint.opacity(0.92))
                } else {
                    Capsule().fill(Color.white.opacity(0.65))
                }
            }
            .overlay(
                Capsule().strokeBorder(tint.opacity(selected ? 0 : 0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func emptyState(title: String, detail: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(BrandTheme.muted)
            Text(title)
                .font(AppFont.headline())
                .foregroundStyle(BrandTheme.ink)
            Text(detail)
                .font(AppFont.subheadline())
                .foregroundStyle(BrandTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}
