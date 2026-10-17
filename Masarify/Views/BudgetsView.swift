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
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                Form {
                    Section("النوع") {
                        Picker("النطاق", selection: $isOverall) {
                            Text("إجمالي الشهر").tag(true)
                            Text("حسب الفئة").tag(false)
                        }
                        .pickerStyle(.segmented)

                        if !isOverall {
                            Picker("الفئة", selection: Binding(
                                get: { draftCategory ?? .food },
                                set: { draftCategory = $0 }
                            )) {
                                ForEach(ExpenseCategory.allCases) { cat in
                                    Text(cat.labelAr).tag(cat)
                                }
                            }
                        }
                    }

                    Section("الحد") {
                        TextField("المبلغ بالجنيه", text: $draftLimit)
                            .keyboardType(.decimalPad)
                            .font(AppFont.title2())
                    }

                    if showValidation {
                        Section {
                            Text("أدخل مبلغًا صحيحًا أكبر من صفر.")
                                .foregroundStyle(.red)
                                .font(AppFont.subheadline())
                        }
                    }

                    if editingBudget != nil {
                        Section {
                            Button("حذف الحد", role: .destructive) {
                                if let editingBudget {
                                    modelContext.delete(editingBudget)
                                }
                                showEditor = false
                            }
                        }
                    }
                }
                .navigationTitle(editingBudget == nil ? "حد جديد" : "تعديل الحد")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("إلغاء") { showEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("حفظ") { saveDraft() }
                            .fontWeight(.semibold)
                    }
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
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
            // Replace existing budget for same scope/month if present
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
