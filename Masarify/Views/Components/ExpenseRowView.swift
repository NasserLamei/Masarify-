import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(expense.category.tint.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: expense.category.systemImage)
                    .foregroundStyle(expense.category.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.note.isEmpty ? expense.category.labelAr : expense.note)
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(expense.category.labelAr)
                        .font(AppFont.caption())
                        .foregroundStyle(expense.category.tint)
                    Text("·")
                        .foregroundStyle(BrandTheme.muted)
                    Text(expense.source.labelAr)
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                }
            }

            Spacer()

            Text(CurrencyFormat.egp(expense.amount))
                .font(AppFont.headline())
                .foregroundStyle(BrandTheme.ink)
        }
        .padding(.vertical, 6)
    }
}
