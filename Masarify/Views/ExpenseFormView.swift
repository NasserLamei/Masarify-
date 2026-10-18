import SwiftUI
import SwiftData

struct ExpenseFormView: View {
    enum Mode {
        case create
        case edit(Expense)
        case draft(ExpenseDraft)
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var amountText: String = ""
    @State private var category: ExpenseCategory = .food
    @State private var note: String = ""
    @State private var merchant: String = ""
    @State private var date: Date = .now
    @State private var source: ExpenseSource = .manual
    @State private var showValidation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MasarifyFormCard(header: "المبلغ") {
                    TextField("٠٫٠٠", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(AppFont.title2())
                        .foregroundStyle(BrandTheme.ink)
                }

                MasarifyFormCard(header: "الفئة") {
                    MasarifyMenuPicker(
                        title: "الفئة",
                        options: ExpenseCategory.allCases.map { ($0, $0.labelAr) },
                        selection: $category
                    )
                }

                MasarifyFormCard(header: "التفاصيل") {
                    VStack(alignment: .leading, spacing: 14) {
                        TextField("ملاحظة", text: $note)
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.ink)

                        TextField("التاجر (اختياري)", text: $merchant)
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.ink)

                        DatePicker(selection: $date, displayedComponents: .date) {
                            Text("التاريخ")
                                .font(AppFont.body())
                                .foregroundStyle(BrandTheme.ink)
                        }
                        .environment(\.locale, Locale(identifier: "ar"))
                        .font(AppFont.body())
                    }
                }

                if showValidation {
                    Text("أدخل مبلغًا صحيحًا أكبر من صفر.")
                        .font(AppFont.subheadline())
                        .foregroundStyle(.red)
                }

                if case .edit = mode {
                    Button(role: .destructive) {
                        deleteExpense()
                    } label: {
                        Text("حذف المصروف")
                            .font(AppFont.headline())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .environment(\.font, AppFont.body())
        .masarifyInlineTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                MasarifyToolbarButton(title: "إلغاء") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                MasarifyToolbarButton(title: "حفظ", prominent: true) { save() }
            }
        }
        .background(MasarifyChromeHost())
        .onAppear {
            hydrate()
            AppAppearance.apply()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                AppAppearance.refreshLiveChrome()
            }
        }
    }

    private var title: String {
        switch mode {
        case .create: return "مصروف جديد"
        case .edit: return "تعديل مصروف"
        case .draft: return "مراجعة وحفظ"
        }
    }

    private func hydrate() {
        switch mode {
        case .create:
            source = .manual
        case .edit(let expense):
            amountText = expense.amount.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(expense.amount))
                : String(expense.amount)
            category = expense.category
            note = expense.note
            merchant = expense.merchant ?? ""
            date = expense.date
            source = expense.source
        case .draft(let draft):
            if let amount = draft.amount {
                amountText = amount.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(amount))
                    : String(amount)
            }
            category = draft.category ?? .other
            note = draft.note
            merchant = draft.merchant ?? ""
            date = draft.date
            source = draft.source
        }
    }

    private func save() {
        let normalized = amountText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(normalized), amount > 0 else {
            showValidation = true
            return
        }
        showValidation = false

        switch mode {
        case .create, .draft:
            let expense = Expense(
                amount: amount,
                category: category,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? category.labelAr
                    : note,
                merchant: merchant.isEmpty ? nil : merchant,
                date: date,
                source: source
            )
            modelContext.insert(expense)
        case .edit(let expense):
            expense.amount = amount
            expense.category = category
            expense.note = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? category.labelAr
                : note
            expense.merchant = merchant.isEmpty ? nil : merchant
            expense.date = date
        }
        dismiss()
    }

    private func deleteExpense() {
        if case .edit(let expense) = mode {
            modelContext.delete(expense)
            dismiss()
        }
    }
}
