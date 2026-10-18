import SwiftUI
import SwiftData

struct BudgetsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MonthlyBudget.createdAt, order: .forward) private var budgets: [MonthlyBudget]
    @Query private var expenses: [Expense]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]

    @State private var showEditor = false
    @State private var editingBudget: MonthlyBudget?
    @State private var draftLimit = ""
    @State private var draftCategoryId: String = BuiltInCategory.food.rawValue
    @State private var isOverall = true
    @State private var showValidation = false
    @State private var showCategories = false

    private var monthKey: String { MonthlyBudget.currentMonthKey() }

    private var progressList: [BudgetProgress] {
        BudgetMonitor.progress(for: budgets, expenses: expenses, categories: categories, monthKey: monthKey)
    }

    private var alerts: [BudgetProgress] {
        BudgetMonitor.activeAlerts(from: progressList)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("حد شهري للإجمالي أو لكل فئة — تنبيه عند ٨٠٪ وعند التجاوز.")
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 4)

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
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("إضافة حد شهري")
                            .font(AppFont.headline())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BrandTheme.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(2)

                Button {
                    showCategories = true
                } label: {
                    Label("إدارة الفئات", systemImage: "folder")
                        .font(AppFont.headline())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(BrandTheme.deepTeal)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
                        )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(3)
            }
            .masarifyScreenInsets()
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .masarifyScreenBackground()
        .masarifyLeadingTrailingChrome(
            title: settings.t(.budgets),
            showVoice: false,
            showCamera: false,
            trailingExtra: AnyView(
                ToolbarCircleButton(
                    systemImage: "plus",
                    tint: BrandTheme.deepTeal,
                    action: beginCreate
                )
                .accessibilityLabel("إضافة حد")
            )
        )
        .onAppear {
            CategoryItem.seedDefaults(into: modelContext)
            if ProcessInfo.processInfo.arguments.contains("-demoBudgetEditor") {
                editingBudget = nil
                isOverall = false
                draftCategoryId = categories.first(where: { $0.id == BuiltInCategory.food.rawValue })?.id
                    ?? categories.first?.id
                    ?? BuiltInCategory.food.rawValue
                draftLimit = ""
                showValidation = false
                showEditor = true
            }
        }
        .sheet(isPresented: $showEditor) {
            BudgetEditorSheet(
                editingBudget: editingBudget,
                isOverall: $isOverall,
                draftCategoryId: $draftCategoryId,
                draftLimit: $draftLimit,
                showValidation: $showValidation,
                categories: categories,
                onManageCategories: { showCategories = true },
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
        .sheet(isPresented: $showCategories) {
            NavigationStack { CategoriesView() }
                .environment(\.layoutDirection, .rightToLeft)
        }
        .onChange(of: showEditor) { _, open in
            if open {
                DispatchQueue.main.async {
                    AppAppearance.refreshLiveChrome()
                }
            }
        }
    }

    private func beginCreate() {
        editingBudget = nil
        isOverall = true
        draftCategoryId = categories.first?.id ?? BuiltInCategory.food.rawValue
        draftLimit = ""
        showValidation = false
        showEditor = true
    }

    private func beginEdit(_ budget: MonthlyBudget) {
        editingBudget = budget
        isOverall = budget.isOverall
        draftCategoryId = budget.categoryId
            ?? categories.first?.id
            ?? BuiltInCategory.food.rawValue
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
        let categoryId: String? = isOverall ? nil : draftCategoryId

        if let editingBudget {
            editingBudget.limitAmount = amount
            editingBudget.categoryId = categoryId
            editingBudget.monthKey = monthKey
            editingBudget.updatedAt = .now
        } else {
            if let existing = budgets.first(where: {
                $0.monthKey == monthKey && $0.categoryRaw == categoryId
            }) {
                existing.limitAmount = amount
                existing.updatedAt = .now
            } else {
                modelContext.insert(
                    MonthlyBudget(monthKey: monthKey, categoryId: categoryId, limitAmount: amount)
                )
            }
        }
        showEditor = false
    }
}

private struct BudgetEditorSheet: View {
    let editingBudget: MonthlyBudget?
    @Binding var isOverall: Bool
    @Binding var draftCategoryId: String
    @Binding var draftLimit: String
    @Binding var showValidation: Bool
    let categories: [CategoryItem]
    let onManageCategories: () -> Void
    let onCancel: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

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
                                    options: categories.map { ($0.id, $0.labelAr) },
                                    selection: $draftCategoryId
                                )
                                Button(action: onManageCategories) {
                                    Label("إضافة فئة جديدة", systemImage: "plus.circle")
                                        .font(AppFont.caption())
                                        .foregroundStyle(BrandTheme.deepTeal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    MasarifyFormCard(header: "الحد") {
                        MasarifyAmountField(placeholder: "المبلغ بالجنيه", text: $draftLimit, fontSize: 22)
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
                .masarifyScreenInsets()
                .padding(.vertical, 20)
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

/// Invisible UIKit host that refreshes Cairo chrome after SwiftUI layout.
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
