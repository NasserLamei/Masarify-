import SwiftUI
import SwiftData

struct ExpenseRowView: View {
    @EnvironmentObject private var settings: AppSettings
    let expense: Expense
    var showDate: Bool = true
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]

    private var category: CategoryItem? {
        CategoryItem.resolve(id: expense.categoryId, in: categories)
    }

    var body: some View {
        HStack(spacing: 14) {
            CategoryIconView(category: category, size: 48)
                .symbolEffect(.bounce, value: expense.id)

            VStack(alignment: .leading, spacing: 3) {
                Text(displayTitle)
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(categoryTitle)
                        .font(AppFont.caption())
                        .foregroundStyle(category?.tint ?? BrandTheme.muted)
                        .lineLimit(1)

                    if showDate {
                        Text("·")
                            .foregroundStyle(BrandTheme.muted.opacity(0.5))
                        Text(formattedDate)
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 8)

            Text(CurrencyFormat.egp(expense.amount, language: settings.language))
                .font(AppFont.custom(.bold, size: 16))
                .foregroundStyle(BrandTheme.deepTeal)
                .contentTransition(.numericText())
        }
    }

    private var categoryTitle: String {
        guard let category else { return settings.language == .arabic ? "مصروف" : "Expense" }
        return settings.categoryLabel(category)
    }

    /// Prefer localized category label when note was saved as a category name in either language.
    private var displayTitle: String {
        let trimmed = expense.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return categoryTitle }
        if noteMatchesCategory(trimmed) { return categoryTitle }
        return trimmed
    }

    private func noteMatchesCategory(_ note: String) -> Bool {
        var aliases: [String] = []
        if let category {
            aliases.append(category.nameAr)
            if !category.nameEn.isEmpty { aliases.append(category.nameEn) }
        }
        if let builtIn = BuiltInCategory(rawValue: expense.categoryId) {
            aliases.append(builtIn.nameAr)
            aliases.append(builtIn.nameEn)
        }
        return aliases.contains { $0.caseInsensitiveCompare(note) == .orderedSame }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = settings.language.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expense.date)
    }
}
