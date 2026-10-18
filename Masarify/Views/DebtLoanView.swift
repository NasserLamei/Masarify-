import SwiftUI
import SwiftData

struct DebtLoanView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DebtLoan.createdAt, order: .reverse) private var items: [DebtLoan]
    @State private var showAdd = false
    @State private var filter: DebtLoanKind? = nil

    private var openItems: [DebtLoan] {
        items.filter { !$0.isSettled && (filter == nil || $0.kind == filter) }
    }

    private var lentTotal: Double {
        items.filter { !$0.isSettled && $0.kind == .lent }.reduce(0) { $0 + $1.amount }
    }

    private var borrowedTotal: Double {
        items.filter { !$0.isSettled && $0.kind == .borrowed }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(settings.t(.debtHint))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)

                HStack(spacing: 12) {
                    summaryChip(
                        title: settings.t(.debtLentTotal),
                        value: CurrencyFormat.egp(lentTotal, language: settings.language),
                        tint: BrandTheme.lagoon
                    )
                    summaryChip(
                        title: settings.t(.debtBorrowedTotal),
                        value: CurrencyFormat.egp(borrowedTotal, language: settings.language),
                        tint: BrandTheme.coral
                    )
                }

                Picker("", selection: Binding(
                    get: { filter.map { Optional($0) } ?? Optional<DebtLoanKind>.none },
                    set: { filter = $0 }
                )) {
                    Text(settings.language == .arabic ? "الكل" : "All").tag(Optional<DebtLoanKind>.none)
                    Text(DebtLoanKind.lent.listTitle(settings.language)).tag(Optional.some(DebtLoanKind.lent))
                    Text(DebtLoanKind.borrowed.listTitle(settings.language)).tag(Optional.some(DebtLoanKind.borrowed))
                }
                .pickerStyle(.segmented)

                if openItems.isEmpty {
                    Text(settings.t(.debtEmpty))
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.muted)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(openItems, id: \.id) { item in
                        debtRow(item)
                    }
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 16)
            .padding(.bottom, 100)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(
            title: settings.t(.debtTitle),
            trailing: AnyView(
                ToolbarCircleButton(systemImage: "plus", tint: BrandTheme.deepTeal) { showAdd = true }
            )
        )
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                DebtLoanFormView()
                    .environmentObject(settings)
            }
        }
    }

    private func summaryChip(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)
            Text(value)
                .font(AppFont.headline())
                .foregroundStyle(tint)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func debtRow(_ item: DebtLoan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.personName)
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                Spacer()
                Text(CurrencyFormat.egp(item.amount, language: settings.language))
                    .font(AppFont.headline())
                    .foregroundStyle(item.kind == .lent ? BrandTheme.lagoon : BrandTheme.coral)
            }
            HStack {
                Text(item.kind.title(settings.language))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
                if let due = item.dueDate {
                    Text("·")
                        .foregroundStyle(BrandTheme.muted)
                    Text(due, style: .date)
                        .font(AppFont.caption())
                        .foregroundStyle(item.isOverdue ? BrandTheme.coral : BrandTheme.muted)
                        .environment(\.locale, AppLanguage.latinDigitsLocale)
                    if item.isOverdue {
                        Text(settings.t(.debtOverdue))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.coral)
                    }
                }
            }
            if !item.note.isEmpty {
                Text(item.note)
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
            }
            Button(settings.t(.debtSettle)) {
                item.isSettled = true
                DebtLoanNotifier.cancel(id: item.id)
                try? modelContext.save()
            }
            .font(AppFont.subheadline())
            .foregroundStyle(BrandTheme.deepTeal)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .masarifyCard(
            cornerRadius: 16,
            accent: item.kind == .lent ? BrandTheme.lagoon : BrandTheme.coral,
            fillOpacity: 0.5
        )
    }
}

struct DebtLoanFormView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var kind: DebtLoanKind = .lent
    @State private var name = ""
    @State private var amountText = ""
    @State private var note = ""
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var hasDueDate = true
    @State private var reminder = true
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MasarifyFormCard(header: settings.t(.debtKind)) {
                    Picker("", selection: $kind) {
                        Text(DebtLoanKind.lent.title(settings.language)).tag(DebtLoanKind.lent)
                        Text(DebtLoanKind.borrowed.title(settings.language)).tag(DebtLoanKind.borrowed)
                    }
                    .pickerStyle(.segmented)
                }

                MasarifyFormCard(header: settings.t(.debtPerson)) {
                    TextField(settings.t(.debtPerson), text: $name)
                        .font(AppFont.body())
                }

                MasarifyFormCard(header: settings.t(.debtAmount)) {
                    MasarifyAmountField(placeholder: "0", text: $amountText)
                }

                MasarifyFormCard(header: settings.t(.debtDue)) {
                    Toggle(isOn: $hasDueDate) {
                        Text(settings.t(.debtDue))
                            .font(AppFont.subheadline())
                    }
                    .tint(BrandTheme.deepTeal)
                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .labelsHidden()
                            .environment(\.locale, AppLanguage.latinDigitsLocale)
                        Toggle(isOn: $reminder) {
                            Text(settings.t(.debtReminder))
                                .font(AppFont.subheadline())
                        }
                        .tint(BrandTheme.deepTeal)
                    }
                }

                MasarifyFormCard(header: settings.language == .arabic ? "ملاحظة" : "Note") {
                    TextField(settings.language == .arabic ? "اختياري" : "Optional", text: $note)
                        .font(AppFont.body())
                }

                if showError {
                    Text(settings.t(.debtValidation))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.coral)
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 16)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(
            title: settings.t(.debtAdd),
            trailing: AnyView(
                MasarifyHeaderTextButton(title: settings.t(.save), prominent: true) { save() }
            )
        )
        .scrollDismissesKeyboard(.interactively)
    }

    private func save() {
        let amount = Double(WesternDigits.normalize(amountText).replacingOccurrences(of: ",", with: ".")) ?? 0
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard amount > 0, !trimmed.isEmpty else {
            showError = true
            return
        }
        let item = DebtLoan(
            personName: trimmed,
            amount: amount,
            kind: kind,
            dueDate: hasDueDate ? dueDate : nil,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            reminderEnabled: hasDueDate && reminder
        )
        modelContext.insert(item)
        try? modelContext.save()
        DebtLoanNotifier.refresh(for: item, language: settings.language)
        dismiss()
    }
}
