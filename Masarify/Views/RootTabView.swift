import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showVoice = false
    @State private var showReceipt = false
    @State private var showManualAdd = false

    enum Tab: Hashable {
        case home, expenses, budgets, report
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(
                        onVoice: { showVoice = true },
                        onCamera: { showReceipt = true },
                        onAdd: { showManualAdd = true },
                        onSeeAll: { selectedTab = .expenses },
                        onBudgets: { selectedTab = .budgets }
                    )
                }
                .tabItem {
                    Label {
                        Text("الرئيسية").font(AppFont.caption(10))
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }
                .tag(Tab.home)

                NavigationStack {
                    ExpensesListView()
                }
                .tabItem {
                    Label {
                        Text("المصروفات").font(AppFont.caption(10))
                    } icon: {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }
                .tag(Tab.expenses)

                NavigationStack {
                    BudgetsView()
                }
                .tabItem {
                    Label {
                        Text("الميزانية").font(AppFont.caption(10))
                    } icon: {
                        Image(systemName: "chart.pie.fill")
                    }
                }
                .tag(Tab.budgets)

                NavigationStack {
                    DailyReportView()
                }
                .tabItem {
                    Label {
                        Text("تقرير اليوم").font(AppFont.caption(10))
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
                .tag(Tab.report)
            }
            .tint(BrandTheme.deepTeal)
            .background(MasarifyChromeHost())
            .onAppear {
                AppAppearance.apply()
                DispatchQueue.main.async {
                    AppAppearance.refreshLiveChrome()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        AppAppearance.refreshLiveChrome()
                    }
                }
            }
            .onChange(of: selectedTab) { _, _ in
                DispatchQueue.main.async {
                    AppAppearance.refreshLiveChrome()
                }
            }

            HStack(spacing: 16) {
                PrimaryActionButton(
                    title: "صوت",
                    systemImage: "mic.fill",
                    colors: [BrandTheme.deepTeal, BrandTheme.azure]
                ) {
                    showVoice = true
                }
                PrimaryActionButton(
                    title: "كاميرا",
                    systemImage: "camera.fill",
                    colors: [BrandTheme.azure, Color(hex: 0x0E7490)]
                ) {
                    showReceipt = true
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 56)
        }
        .sheet(isPresented: $showVoice) {
            NavigationStack { VoiceEntryView() }
        }
        .sheet(isPresented: $showReceipt) {
            NavigationStack { ReceiptCaptureView() }
        }
        .sheet(isPresented: $showManualAdd) {
            NavigationStack {
                ExpenseFormView(mode: .create)
            }
        }
        .onAppear(perform: applyDemoLaunchArguments)
    }

    private func applyDemoLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-demoVoice") {
            selectedTab = .home
            showVoice = true
        } else if args.contains("-demoReceipt") {
            selectedTab = .home
            showReceipt = true
        } else if args.contains("-demoReport") {
            selectedTab = .report
        } else if args.contains("-demoExpenses") {
            selectedTab = .expenses
        } else if args.contains("-demoBudgetEditor") || args.contains("-demoBudgets") {
            selectedTab = .budgets
        }
    }
}

private struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let colors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(AppFont.headline())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: BrandTheme.deepTeal.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Expense.self, MonthlyBudget.self], inMemory: true)
}
