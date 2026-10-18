import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MonthlyBudget.createdAt, order: .forward) private var budgets: [MonthlyBudget]
    @Query private var expenses: [Expense]

    @State private var showEditor = false
    @State private var editingBudget: MonthlyBudget?
    @State private var draftLimit = ""
    @State private var draftCategory: ExpenseCategory? = nil
    @State private var isOverall = true
    @State private var showValidation = false

    private var monthKey: String { MonthlyBudget.currentMonthKey() }

    private var progressList: [BudgetProgress] {
        BudgetMonitor.progress(for: budgets, expenses: expenses, monthKey: monthKey)
    }

    private var alerts: [BudgetProgress] {
        BudgetMonitor.activeAlerts(from: progressList)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("الميزانية الشهرية")
                        .font(AppFont.title())
                        .foregroundStyle(BrandTheme.ink)
                    Text("حد شهري للإجمالي أو لكل فئة — تنبيه عند ٨٠٪ وعند التجاوز.")
                        .font(AppFont.body())
                        .foregroundStyle(BrandTheme.muted)
                }

                if !alerts.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(alerts) { alert in
                            BudgetAlertBanner(progress: alert)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("تقدّم هذا الشهر")
                        .font(AppFont.title3())
                        .foregroundStyle(BrandTheme.ink)

                    if progressList.isEmpty {
                        Text("لسه مفيش حدود. أضف ميزانية شهرية للبدء.")
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.muted)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(progressList) { item in
                            Button {
                                beginEdit(item.budget)
                            } label: {
                                BudgetProgressRow(progress: item)
                            }
                            .buttonStyle(.plain)
                            Divider().opacity(0.3)
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button {
                    beginCreate()
                } label: {
                    Label("إضافة حد شهري", systemImage: "plus.circle.fill")
                        .font(AppFont.headline())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandTheme.deepTeal)
            }
            .padding(20)
            .padding(.bottom, 110)
        }
        .background(
            LinearGradient(colors: [BrandTheme.foam, BrandTheme.mist.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationTitle("الميزانية")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    beginCreate()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .background(MasarifyChromeHost())
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-demoBudgetEditor") {
                editingBudget = nil
                isOverall = false
                draftCategory = .food
                draftLimit = ""
                showValidation = false
                showEditor = true
            }
        }
        .sheet(isPresented: $showEditor) {
            BudgetEditorSheet(
                editingBudget: editingBudget,
                isOverall: $isOverall,
                draftCategory: $draftCategory,
                draftLimit: $draftLimit,
                showValidation: $showValidation,
                onCancel: { showEditor = false },
                onSave: saveDraft,
                onDelete: {
                    if let editingBudget {
                        modelContext.delete(editingBudget)
                    }
                    showEditor = false
                }
            )
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.font, AppFont.body())
        }
        .onChange(of: showEditor) { _, open in
            if open {
                DispatchQueue.main.async {
                    AppAppearance.refreshLiveChrome()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        AppAppearance.refreshLiveChrome()
                    }
                }
            }
        }
    }

    private func beginCreate() {
        editingBudget = nil
        isOverall = true
        draftCategory = .food
        draftLimit = ""
        showValidation = false
        showEditor = true
    }

    private func beginEdit(_ budget: MonthlyBudget) {
        editingBudget = budget
        isOverall = budget.isOverall
        draftCategory = budget.category ?? .food
        draftLimit = budget.limitAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(budget.limitAmount))
            : String(budget.limitAmount)
        showValidation = false
        showEditor = true
    }

    private func saveDraft() {
        let normalized = draftLimit.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(normalized), amount > 0 else {
            showValidation = true
            return
        }
        showValidation = false
        let category: ExpenseCategory? = isOverall ? nil : (draftCategory ?? .food)

        if let editingBudget {
            editingBudget.limitAmount = amount
            editingBudget.category = category
            editingBudget.monthKey = monthKey
            editingBudget.updatedAt = .now
        } else {
            if let existing = budgets.first(where: {
                $0.monthKey == monthKey && $0.categoryRaw == category?.rawValue
            }) {
                existing.limitAmount = amount
                existing.updatedAt = .now
            } else {
                modelContext.insert(
                    MonthlyBudget(monthKey: monthKey, category: category, limitAmount: amount)
                )
            }
        }
        showEditor = false
    }
}

private struct BudgetEditorSheet: View {
    let editingBudget: MonthlyBudget?
    @Binding var isOverall: Bool
    @Binding var draftCategory: ExpenseCategory?
    @Binding var draftLimit: String
    @Binding var showValidation: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    private var categoryBinding: Binding<ExpenseCategory> {
        Binding(
            get: { draftCategory ?? .food },
            set: { draftCategory = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    MasarifyFormCard(header: "النوع") {
                        VStack(alignment: .leading, spacing: 14) {
                            MasarifySegmentedControl(
                                options: [
                                    (true, "إجمالي الشهر"),
                                    (false, "حسب الفئة")
                                ],
                                selection: $isOverall
                            )

                            if !isOverall {
                                MasarifyMenuPicker(
                                    title: "الفئة",
                                    options: ExpenseCategory.allCases.map { ($0, $0.labelAr) },
                                    selection: categoryBinding
                                )
                            }
                        }
                    }

                    MasarifyFormCard(header: "الحد") {
                        TextField("المبلغ بالجنيه", text: $draftLimit)
                            .keyboardType(.decimalPad)
                            .font(AppFont.title2())
                            .foregroundStyle(BrandTheme.ink)
                    }

                    if showValidation {
                        Text("أدخل مبلغًا صحيحًا أكبر من صفر.")
                            .font(AppFont.subheadline())
                            .foregroundStyle(.red)
                    }

                    if editingBudget != nil {
                        Button(role: .destructive, action: onDelete) {
                            Text("حذف الحد")
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
            .masarifyInlineTitle(editingBudget == nil ? "حد جديد" : "تعديل الحد")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    MasarifyToolbarButton(title: "إلغاء", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    MasarifyToolbarButton(title: "حفظ", prominent: true, action: onSave)
                }
            }
            .background(MasarifyChromeHost())
            .onAppear {
                AppAppearance.apply()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    AppAppearance.refreshLiveChrome()
                }
            }
        }
    }
}

/// Invisible UIKit host that refreshes Tajawal chrome after SwiftUI layout.
struct MasarifyChromeHost: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        scheduleRefresh()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        scheduleRefresh()
    }

    private func scheduleRefresh() {
        DispatchQueue.main.async {
            AppAppearance.refreshLiveChrome()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                AppAppearance.refreshLiveChrome()
            }
        }
    }
}
