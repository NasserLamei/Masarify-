import SwiftUI
import SwiftData

struct RootTabView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var appLock: AppLockController
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Tab = .home
    @State private var showVoice = false
    @State private var showReceipt = false
    @State private var showManualAdd = false
    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var showFeatureTour = false
    @State private var featureTourStep = 0
    @State private var showDailyReport = false

    enum Tab: Hashable {
        case home, expenses, insights, goals, more
    }

    private var isIntroActive: Bool { showSplash || showOnboarding }

    var body: some View {
        ZStack {
            ScreenAtmosphere()

            if !isIntroActive {
                tabContent
                    .environment(\.onVoiceCapture, { showVoice = true })
                    .environment(\.onCameraCapture, { showReceipt = true })
                    .animation(Motion.softSpring, value: selectedTab)
                    // Reserve tab content only — bar background paints into the home-indicator zone.
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: 56)
                    }
                    .overlay(alignment: .bottom) {
                        MasarifyTabBar(selection: $selectedTab)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
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
                        DispatchQueue.main.async { AppAppearance.refreshLiveChrome() }
                    }
                    .transition(.opacity)
            }

            if showSplash {
                SplashView(isActive: $showSplash)
                    .transition(.opacity)
                    .zIndex(10)
            }

            if showOnboarding && !showSplash {
                OnboardingView {
                    showOnboarding = false
                    if !settings.hasCompletedFeatureTour {
                        featureTourStep = 0
                        selectedTab = .home
                        withAnimation(Motion.gentle) { showFeatureTour = true }
                    }
                }
                .transition(.opacity)
                .zIndex(15)
            }

            if showFeatureTour && !showSplash && !showOnboarding {
                FeatureTourOverlay(
                    stepIndex: $featureTourStep,
                    onSelectTab: { selectedTab = $0 },
                    onFinished: { showFeatureTour = false }
                )
                .transition(.opacity)
                .zIndex(18)
            }

            if appLock.isLocked && settings.biometricLockEnabled && !showSplash && !showOnboarding {
                BiometricLockOverlay(lock: appLock)
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .onChange(of: showSplash) { _, active in
            guard !active else { return }
            if !settings.hasCompletedOnboarding {
                withAnimation(Motion.gentle) { showOnboarding = true }
            } else if !settings.hasCompletedFeatureTour {
                featureTourStep = 0
                withAnimation(Motion.gentle) { showFeatureTour = true }
            }
        }
        .sheet(isPresented: $showVoice) {
            NavigationStack { VoiceEntryView() }
                .environmentObject(settings)
        }
        .sheet(isPresented: $showReceipt) {
            NavigationStack { ReceiptCaptureView() }
                .environmentObject(settings)
        }
        .sheet(isPresented: $showManualAdd) {
            NavigationStack { ExpenseFormView(mode: .create) }
                .environmentObject(settings)
        }
        .sheet(isPresented: $showDailyReport) {
            NavigationStack { DailyReportView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .onAppear {
            applyDemoLaunchArguments()
            publishWidgetSnapshot()
            openWidgetRequestsIfNeeded()
            refreshDailySummaryNotification()
        }
        .onChange(of: expenses.count) { _, _ in
            publishWidgetSnapshot()
            refreshDailySummaryNotification()
        }
        .onChange(of: budgets.count) { _, _ in
            publishWidgetSnapshot()
            refreshDailySummaryNotification()
        }
        .onChange(of: settings.dailySummaryEnabled) { _, _ in refreshDailySummaryNotification() }
        .onChange(of: settings.dailySummaryHour) { _, _ in refreshDailySummaryNotification() }
        .onChange(of: settings.dailySummaryMinute) { _, _ in refreshDailySummaryNotification() }
        .onChange(of: settings.dailySummaryFocusDay) { _, _ in refreshDailySummaryNotification() }
        .onChange(of: settings.language) { _, _ in refreshDailySummaryNotification() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                if settings.biometricLockEnabled {
                    appLock.lockIfEnabled(true)
                }
            }
            if phase == .active {
                publishWidgetSnapshot()
                openWidgetRequestsIfNeeded()
                refreshDailySummaryNotification()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .masarifyOpenVoice)) { _ in
            showSplash = false
            selectedTab = .home
            showVoice = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .masarifyOpenAddExpense)) { _ in
            showSplash = false
            selectedTab = .home
            showManualAdd = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .masarifyOpenHome)) { _ in
            showSplash = false
            selectedTab = .home
        }
        .onReceive(NotificationCenter.default.publisher(for: .masarifyOpenReport)) { _ in
            showSplash = false
            selectedTab = .insights
            showDailyReport = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .masarifyRefreshDailySummary)) { _ in
            refreshDailySummaryNotification()
        }
    }

    /// Keep stacks alive so tab switches animate smoothly without resetting navigation.
    private var tabContent: some View {
        ZStack {
            tabPage(.home) {
                NavigationStack {
                    HomeView(
                        onVoice: { showVoice = true },
                        onCamera: { showReceipt = true },
                        onAdd: { showManualAdd = true },
                        onSeeAll: { selectedTab = .expenses },
                        onBudgets: { selectedTab = .insights },
                        onInsights: { selectedTab = .insights },
                        onGoals: { selectedTab = .goals }
                    )
                }
            }
            tabPage(.expenses) { NavigationStack { ExpensesListView() } }
            tabPage(.insights) { NavigationStack { InsightsHubView() } }
            tabPage(.goals) { NavigationStack { GoalsView() } }
            tabPage(.more) { NavigationStack { MoreView() } }
        }
    }

    private func tabPage<Content: View>(
        _ tab: Tab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let active = selectedTab == tab
        return content()
            .opacity(active ? 1 : 0)
            .scaleEffect(active ? 1 : 0.985)
            .offset(y: active ? 0 : 10)
            .allowsHitTesting(active)
            .accessibilityHidden(!active)
            .zIndex(active ? 1 : 0)
    }

    private func publishWidgetSnapshot() {
        WidgetBudgetPublisher.publish(
            expenses: expenses,
            budgets: budgets,
            language: settings.language
        )
    }

    private func refreshDailySummaryNotification() {
        let focusDay = settings.dailySummaryFocusDay
        let snapshot = DailySummarySnapshot.build(
            day: focusDay.date(),
            expenses: expenses,
            budgets: budgets,
            categories: categories,
            language: settings.language
        )
        DailySummaryNotifier.rescheduleFromSnapshot(
            enabled: settings.dailySummaryEnabled,
            hour: settings.dailySummaryHour,
            minute: settings.dailySummaryMinute,
            snapshot: snapshot,
            focusDay: focusDay,
            language: settings.language
        )
    }

    private func openWidgetRequestsIfNeeded() {
        if WidgetBudgetStore.consumeVoiceRequest() {
            showSplash = false
            selectedTab = .home
            showVoice = true
        }
        if WidgetBudgetStore.consumeAddExpenseRequest() {
            showSplash = false
            selectedTab = .home
            showManualAdd = true
        }
    }

    private func applyDemoLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-skipSplash") || args.contains("-seedDemoData") {
            showSplash = false
        }
        if args.contains("-demoVoice") {
            selectedTab = .home
            showVoice = true
            showSplash = false
        } else if args.contains("-demoReceipt") {
            selectedTab = .home
            showReceipt = true
            showSplash = false
        } else if args.contains("-demoExpenses") {
            selectedTab = .expenses
            showSplash = false
        } else if args.contains("-demoSplash") {
            showSplash = true
        }
    }
}

/// Dock-style tab bar — solid seafoam cradle, filled teal icon well when selected.
private struct MasarifyTabBar: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var selection: RootTabView.Tab
    @Namespace private var tabNS

    private let items: [(RootTabView.Tab, String, L10n.Key)] = [
        (.home, "house.fill", .tabHome),
        (.expenses, "list.bullet.rectangle", .tabExpenses),
        (.insights, "sparkles", .tabInsights),
        (.goals, "flag.fill", .tabGoals),
        (.more, "ellipsis.circle.fill", .tabMore)
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.0) { tab, icon, key in
                let selected = selection == tab
                Button {
                    withAnimation(Motion.softSpring) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(BrandTheme.deepTeal)
                                    .matchedGeometryEffect(id: "tabWell", in: tabNS)
                                    .shadow(color: BrandTheme.deepTeal.opacity(0.28), radius: 8, y: 3)
                            }

                            Image(systemName: icon)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(selected ? Color.white : BrandTheme.muted)
                                .symbolEffect(.bounce, value: selected)
                        }
                        .frame(width: 48, height: 34)

                        Text(settings.t(key))
                            .font(AppFont.caption(10))
                            .foregroundStyle(selected ? BrandTheme.deepTeal : BrandTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.t(key))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        // Small fixed pad only — avoid safeAreaPadding (it adds the full ~34pt home-indicator band).
        .padding(.bottom, 10)
        .background {
            BrandTheme.surface
                .shadow(color: BrandTheme.ink.opacity(0.08), radius: 10, y: -2)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(BrandTheme.deepTeal.opacity(0.10))
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct SplashView: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var isActive: Bool
    @State private var brandOpacity: Double = 0
    @State private var titleRise: CGFloat = 28
    @State private var logoScale: CGFloat = 0.55
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BrandTheme.foam,
                    BrandTheme.seafoam.opacity(0.92),
                    BrandTheme.mist
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.85)

            // Bills float around — no big coin
            SplashMoneyOrchestra()

            // Brand centered as the hero
            VStack(spacing: 16) {
                Spacer()

                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: BrandTheme.deepTeal.opacity(0.32), radius: 24, y: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(.white.opacity(0.55), lineWidth: 1.5)
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text(settings.t(.appName))
                    .font(AppFont.brand(42))
                    .foregroundStyle(BrandTheme.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .padding(.horizontal, BrandTheme.screenInset)
                    .opacity(brandOpacity)
                    .offset(y: titleRise)

                Text(settings.t(.splashSubtitle))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .opacity(brandOpacity)
                    .offset(y: titleRise)

                Spacer()
                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                logoScale = 1
                logoOpacity = 1
            }
            withAnimation(.spring(response: 0.75, dampingFraction: 0.8).delay(0.22)) {
                brandOpacity = 1
                titleRise = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(Motion.gentle) { isActive = false }
            }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppSettings())
        .modelContainer(for: [Expense.self, MonthlyBudget.self, CategoryItem.self, SavingsGoal.self, Trip.self, DebtLoan.self], inMemory: true)
}
