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
        Form {
            Section("المبلغ") {
                TextField("٠٫٠٠", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
            }

            Section("الفئة") {
                Picker("الفئة", selection: $category) {
                    ForEach(ExpenseCategory.allCases) { cat in
                        Label(cat.labelAr, systemImage: cat.systemImage)
                            .tag(cat)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("التفاصيل") {
                TextField("ملاحظة", text: $note)
                TextField("التاجر (اختياري)", text: $merchant)
                DatePicker("التاريخ", selection: $date, displayedComponents: .date)
            }

            if showValidation {
                Section {
                    Text("أدخل مبلغًا صحيحًا أكبر من صفر.")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("إلغاء") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("حفظ") { save() }
                    .fontWeight(.semibold)
            }
            if case .edit = mode {
                ToolbarItem(placement: .bottomBar) {
                    Button("حذف المصروف", role: .destructive) {
                        deleteExpense()
                    }
                }
            }
        }
        .onAppear(perform: hydrate)
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
