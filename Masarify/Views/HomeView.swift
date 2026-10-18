import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Expense.createdAt, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @Query(filter: #Predicate<SavingsGoal> { !$0.isArchived }, sort: \SavingsGoal.createdAt)
    private var goals: [SavingsGoal]

    let onVoice: () -> Void
    let onCamera: () -> Void
    let onAdd: () -> Void
    let onSeeAll: () -> Void
    var onBudgets: (() -> Void)? = nil
    var onInsights: (() -> Void)? = nil
    var onGoals: (() -> Void)? = nil

    @State private var contentReady = false
    @State private var showCategories = false
    @State private var showVoicePlan = false
    @State private var showEmergency = false
    @State private var showTrip = false
    @State private var showBudgets = false
    @State private var showMyExpenses = false
    @State private var showDailyReport = false
    @State private var showCoach = false
    @Query(filter: #Predicate<Trip> { $0.isActive }) private var activeTrips: [Trip]

    private var coachTip: FinancialCoachService.Tip {
        FinancialCoachService.primaryTip(
            expenses: expenses,
            budgets: budgets,
            categories: categories,
            language: settings.language,
            activeChallenges: settings.activeChallenges
        )
    }

    private var todayExpenses: [Expense] {
        let start = Calendar.current.startOfDay(for: .now)
        return expenses.filter { $0.date >= start }
    }

    private var todayTotal: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }

    private var monthProgress: [BudgetProgress] {
        BudgetMonitor.progress(for: budgets, expenses: expenses, categories: categories)
    }

    private var overallBudget: BudgetProgress? {
        monthProgress.first(where: \.budget.isOverall)
    }

    private var monthLimit: Double {
        overallBudget?.limit ?? 0
    }

    private var monthRemaining: Double? {
        guard monthLimit > 0 else { return nil }
        return overallBudget?.remaining
    }

    private var topCategory: CategoryItem? {
        let grouped = Dictionary(grouping: todayExpenses, by: \.categoryId)
        guard let topId = grouped.max(by: { lhs, rhs in
            lhs.value.reduce(0) { $0 + $1.amount } < rhs.value.reduce(0) { $0 + $1.amount }
        })?.key else { return nil }
        return CategoryItem.resolve(id: topId, in: categories)
    }

    private var budgetAlerts: [BudgetProgress] {
        BudgetMonitor.activeAlerts(
            from: BudgetMonitor.progress(for: budgets, expenses: expenses, categories: categories)
        )
    }

    private var topCompare: SelfCompareInsight? {
        SelfBenchmarkService.compare(expenses: expenses, categories: categories, language: settings.language)
            .first(where: \.improved)
    }

    private var topPeak: PeakInsight? {
        SpendingInsightsService.peakInsights(expenses: expenses, language: settings.language).first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Prominent Add Expense — top of home (new UI)
                addExpenseBanner
                    .masarifyAppear(0)

                BrandHeroView(
                    todayTotal: todayTotal,
                    monthRemaining: monthRemaining,
                    monthLimit: monthLimit,
                    onManageBudget: { showBudgets = true }
                )
                .masarifyAppear(1)

                myExpensesButton
                    .masarifyAppear(1)

                coachStrip
                    .masarifyAppear(1)

                // Horizontal money quick actions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        moneyAction(settings.t(.coachTitle), "person.wave.2.fill", BrandTheme.deepTeal) { showCoach = true }
                        moneyAction(settings.t(.voicePlan), "waveform", BrandTheme.azure) { showVoicePlan = true }
                        moneyAction(settings.t(.emergency), "lifepreserver.fill", BrandTheme.coral) { showEmergency = true }
                        moneyAction(settings.t(.insights), "chart.line.uptrend.xyaxis", BrandTheme.deepTeal) { onInsights?() }
                        moneyAction(settings.t(.goals), "flag.fill", BrandTheme.highlight) { onGoals?() }
                        moneyAction(settings.t(.tripMode), "airplane", BrandTheme.azure) { showTrip = true }
                        moneyAction(settings.t(.categories), "folder.fill", BrandTheme.lagoon) { showCategories = true }
                        moneyAction(settings.t(.todayReport), "sun.max.fill", BrandTheme.deepTeal) { showDailyReport = true }
                    }
                    .padding(.horizontal, 2)
                }
                .masarifyAppear(2)

                if settings.emergencyModeEnabled {
                    emergencyStrip
                        .masarifyAppear(2)
                }

                if settings.roundUpEnabled {
                    roundUpStrip
                        .masarifyAppear(2)
                }

                if settings.trueCostEnabled {
                    trueCostStrip
                        .masarifyAppear(2)
                }

                if let trip = activeTrips.first {
                    tripStrip(trip)
                        .masarifyAppear(2)
                }

                if let goal = goals.first {
                    goalStrip(goal)
                        .masarifyAppear(3)
                }

                if let win = topCompare {
                    insightCard(title: win.title, detail: win.detail, image: win.systemImage, tint: BrandTheme.deepTeal) {
                        onInsights?()
                    }
                    .masarifyAppear(4)
                } else if let peak = topPeak {
                    insightCard(title: peak.title, detail: peak.detail, image: peak.systemImage, tint: BrandTheme.azure) {
                        onInsights?()
                    }
                    .masarifyAppear(4)
                }

                if !budgetAlerts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel(settings.t(.budgetAlerts))
                        ForEach(Array(budgetAlerts.prefix(2).enumerated()), id: \.element.id) { index, alert in
                            BudgetAlertBanner(progress: alert)
                                .masarifyAppear(index + 5)
                        }
                    }
                }

                topCategoryStrip
                    .masarifyAppear(6)

                recentBlock
                    .masarifyAppear(7)
            }
            .masarifyScreenInsets()
            .padding(.top, 4)
            .padding(.bottom, 130)
            .opacity(contentReady ? 1 : 0)
        }
        .masarifyScreenBackground()
        .masarifyLeadingTrailingChrome(title: settings.t(.appName))
        .sheet(isPresented: $showCategories) {
            NavigationStack { CategoriesView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showBudgets) {
            NavigationStack { BudgetsView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showMyExpenses) {
            NavigationStack { MyExpensesView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showVoicePlan) {
            NavigationStack { VoicePlanView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showEmergency) {
            NavigationStack { EmergencyModeView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showTrip) {
            NavigationStack { TripModeView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showDailyReport) {
            NavigationStack { DailyReportView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showCoach) {
            NavigationStack { FinancialCoachView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .onAppear {
            withAnimation(Motion.gentle) { contentReady = true }
        }
    }

    private var coachStrip: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { showCoach = true } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [BrandTheme.deepTeal, BrandTheme.lagoon],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.t(.coachName))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.deepTeal)
                        Text(coachTip.title)
                            .font(AppFont.headline())
                            .foregroundStyle(BrandTheme.ink)
                            .lineLimit(1)
                        Text(coachTip.message)
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(PressableStyle())

            if settings.coachVoiceEnabled {
                Button {
                    CoachSpeechService.shared.speak(
                        title: coachTip.title,
                        message: coachTip.message,
                        language: settings.language,
                        enabled: true
                    )
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BrandTheme.deepTeal)
                        .frame(width: 40, height: 40)
                        .background(BrandTheme.surface)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(BrandTheme.deepTeal.opacity(0.28), lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(settings.t(.coachSpeak))
            } else {
                Image(systemName: "chevron.forward")
                    .foregroundStyle(BrandTheme.deepTeal.opacity(0.7))
                    .padding(.top, 12)
            }
        }
        .padding(14)
        .background(BrandTheme.deepTeal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
        )
    }

    private var trueCostStrip: some View {
        Button { /* settings via tab */ } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .foregroundStyle(BrandTheme.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.t(.trueCost))
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text(
                        settings.language == .arabic
                            ? "ساعة شغلك ≈ \(CurrencyFormat.egp(settings.hourlyRate, language: .arabic)) — المصروف الكبير هيوريك تكلفته بالوقت."
                            : "Your hour ≈ \(CurrencyFormat.egp(settings.hourlyRate, language: .english)) — big spends show work-time cost."
                    )
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
                    .lineLimit(2)
                }
                Spacer()
            }
            .padding(16)
            .background(BrandTheme.coral.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
            )
        }
        .buttonStyle(PressableStyle())
    }

    private func tripStrip(_ trip: Trip) -> some View {
        Button { showTrip = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "airplane")
                    .foregroundStyle(BrandTheme.azure)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(settings.t(.tripActive)): \(trip.title)")
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text(settings.t(.tripSeparated))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                }
                Spacer()
                Text(trip.currencyCode)
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.azure)
            }
            .padding(16)
            .background(BrandTheme.azure.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
            )
        }
        .buttonStyle(PressableStyle())
    }

    private var roundUpStrip: some View {
        Button { onGoals?() } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.forward.circle.fill")
                    .foregroundStyle(BrandTheme.lagoon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.t(.roundUpTitle))
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text("\(settings.t(.roundUpPiggy)): \(CurrencyFormat.egp(settings.totalRoundUpSaved, language: settings.language))")
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(BrandTheme.lagoon)
            }
            .padding(16)
            .background(BrandTheme.lagoon.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
            )
        }
        .buttonStyle(PressableStyle())
    }

    private var emergencyStrip: some View {
        Button { showEmergency = true } label: {
            HStack {
                Image(systemName: "lifepreserver.fill")
                    .foregroundStyle(BrandTheme.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.t(.emergencyTitle))
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text(settings.t(.emergencyOn))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(BrandTheme.coral)
            }
            .padding(16)
            .background(BrandTheme.coral.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
            )
        }
        .buttonStyle(PressableStyle())
    }

    private func moneyAction(_ title: String, _ image: String, _ tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.16))
                        .frame(width: 52, height: 52)
                    Image(systemName: image)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 76, height: 34, alignment: .top)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(width: 100, height: 118)
            .masarifyCard(cornerRadius: 18, accent: BrandTheme.deepTeal, fillOpacity: 0.55)
        }
        .buttonStyle(PressableStyle())
    }

    private var topCategoryStrip: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(settings.t(.topCategory))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
                Text(topCategory.map { settings.categoryLabel($0) } ?? "—")
                    .font(AppFont.title3())
                    .foregroundStyle(BrandTheme.ink)
                    .lineLimit(1)
            }
            Spacer()
            EgpBillsView(width: 72, height: 46)
        }
        .padding(16)
        .masarifyCard(cornerRadius: 20, accent: BrandTheme.deepTeal, fillOpacity: 0.42)
    }

    private var addExpenseBanner: some View {
        Button(action: onAdd) {
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
                    Text(settings.language == .arabic ? "سجّل مصروف جديد بسرعة" : "Log a new expense fast")
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
    }

    private func goalStrip(_ goal: SavingsGoal) -> some View {
        Button { onGoals?() } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(goal.title)
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    Text("\(Int(goal.progress * 100))%")
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.highlight)
                }
                AnimatedProgressBar(progress: goal.progress, tint: BrandTheme.highlight)
                Text(settings.t(.goalsSubtitle))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
            }
            .padding(16)
            .masarifyCard(cornerRadius: 20, accent: BrandTheme.deepTeal, fillOpacity: 0.55)
        }
        .buttonStyle(PressableStyle())
    }

    private func insightCard(title: String, detail: String, image: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: image)
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text(detail)
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .masarifyCard(cornerRadius: 20, accent: BrandTheme.deepTeal, fillOpacity: 0.55)
        }
        .buttonStyle(PressableStyle())
    }

    private var myExpensesButton: some View {
        Button { showMyExpenses = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(BrandTheme.brandGradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.t(.myExpenses))
                        .font(AppFont.title3())
                        .foregroundStyle(BrandTheme.ink)
                    Text(settings.t(.myExpensesHint))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                }

                Spacer(minLength: 0)

                Image(systemName: settings.language == .arabic ? "chevron.left" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BrandTheme.deepTeal)
            }
            .padding(16)
            .background(Color.white.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
            )
            .shadow(color: BrandTheme.deepTeal.opacity(0.10), radius: 12, y: 5)
        }
        .buttonStyle(PressableStyle())
    }

    private var recentBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel(settings.t(.recentExpenses))
                Spacer()
                Button(settings.t(.seeAll)) { showMyExpenses = true }
                    .font(AppFont.custom(.medium, size: 14))
                    .foregroundStyle(BrandTheme.deepTeal)
            }

            if todayExpenses.isEmpty {
                Text(settings.t(.emptyToday))
                    .font(AppFont.body())
                    .foregroundStyle(BrandTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(todayExpenses.prefix(4).enumerated()), id: \.element.id) { _, expense in
                        ExpenseRowView(expense: expense)
                            .padding(14)
                            .masarifyCard(cornerRadius: 18, accent: BrandTheme.deepTeal, fillOpacity: 0.38)
                    }
                }
            }
        }
    }

    private func sectionLabel(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.title2())
                .foregroundStyle(BrandTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
            }
        }
    }
}
