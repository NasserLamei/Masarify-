import SwiftUI
import SwiftData

struct ExpensesListView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showAdd = false
    @State private var editingExpense: Expense?
    @State private var showEdit = false
    @State private var showCategories = false

    private var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Top add CTA — always visible
                Button { showAdd = true } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.95))
                                .frame(width: 44, height: 44)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(BrandTheme.deepTeal)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(settings.t(.addExpense))
                                .font(AppFont.headline())
                                .foregroundStyle(.white)
                            Text(settings.language == .arabic ? "اضغط عشان تسجّل مصروف" : "Tap to log an expense")
                                .font(AppFont.caption())
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer(minLength: 8)
                        EgpBillsView(width: 68, height: 42)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(BrandTheme.brandGradient)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 1))
                    .shadow(color: BrandTheme.deepTeal.opacity(0.32), radius: 18, y: 8)
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(0)

                if !expenses.isEmpty {
                    HStack {
                        Text(settings.language == .arabic ? "الإجمالي" : "Total")
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)
                        Spacer()
                        Text(CurrencyFormat.egp(total, language: settings.language))
                            .font(AppFont.headline())
                            .foregroundStyle(BrandTheme.deepTeal)
                    }
                    .padding(.horizontal, 4)
                    .masarifyAppear(1)
                }

                if expenses.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(BrandTheme.muted)
                        Text(settings.t(.emptyExpenses))
                            .font(AppFont.headline())
                            .foregroundStyle(BrandTheme.ink)
                        Text(settings.t(.emptyExpensesHint))
                            .font(AppFont.subheadline())
                            .foregroundStyle(BrandTheme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(expenses.enumerated()), id: \.element.id) { index, expense in
                            Button {
                                editingExpense = expense
                                showEdit = true
                            } label: {
                                ExpenseRowView(expense: expense)
                                    .padding(14)
                                    .masarifyCard(cornerRadius: 18, accent: BrandTheme.deepTeal, fillOpacity: 0.38)
                            }
                            .buttonStyle(PressableStyle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(expense)
                                } label: {
                                    Label(settings.t(.delete), systemImage: "trash")
                                }
                            }
                            .masarifyAppear(min(index + 2, 8))
                        }
                    }
                }
            }
            .masarifyScreenInsets()
            .padding(.top, 8)
            .padding(.bottom, 130)
        }
        .masarifyScreenBackground()
        .masarifyLeadingTrailingChrome(
            title: settings.t(.expenses),
            leadingExtra: AnyView(
                ToolbarCircleButton(
                    systemImage: "folder.fill",
                    tint: BrandTheme.lagoon,
                    action: { showCategories = true }
                )
                .accessibilityLabel(settings.t(.categories))
            ),
            trailingExtra: AnyView(
                ToolbarCircleButton(
                    systemImage: "plus",
                    tint: BrandTheme.deepTeal,
                    action: { showAdd = true }
                )
                .accessibilityLabel(settings.t(.addExpense))
            )
        )
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                ExpenseFormView(mode: .create)
            }
            .environmentObject(settings)
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                if let editingExpense {
                    ExpenseFormView(mode: .edit(editingExpense))
                }
            }
            .environmentObject(settings)
        }
        .sheet(isPresented: $showCategories) {
            NavigationStack {
                CategoriesView()
            }
            .environmentObject(settings)
            .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .onAppear {
            CategoryItem.seedDefaults(into: modelContext)
        }
    }
}
