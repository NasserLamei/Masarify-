import SwiftUI
import SwiftData

@main
struct MasarifyApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var cloudAccount = CloudAccountStore()
    @StateObject private var appLock = AppLockController()

    init() {
        AppAppearance.apply()
        DailySummaryNotifier.configureAtLaunch()
        DispatchQueue.main.async {
            PodIntegrations.configureAtLaunch()
        }
    }

    var sharedModelContainer: ModelContainer = {
        Self.makeModelContainer(preferCloud: AppSettings.prefersICloudSync)
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
                .environmentObject(cloudAccount)
                .environmentObject(appLock)
                .environment(\.layoutDirection, settings.language.layoutDirection)
                .environment(\.locale, settings.language.locale)
                .environment(\.font, AppFont.body())
                .preferredColorScheme(settings.preferredColorScheme)
                .animation(Motion.gentle, value: settings.language)
                .animation(Motion.gentle, value: settings.isDarkMode)
                .onAppear {
                    AppAppearance.apply()
                    CategoryItem.seedDefaults(into: sharedModelContainer.mainContext)
                    seedDemoDataIfNeeded()
                    if settings.biometricLockEnabled {
                        appLock.lockIfEnabled(true)
                    }
                }
                .onChange(of: settings.language) { _, _ in
                    DispatchQueue.main.async { AppAppearance.refreshLiveChrome() }
                }
                .onChange(of: settings.isDarkMode) { _, _ in
                    DispatchQueue.main.async { AppAppearance.refreshLiveChrome() }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    /// Prefer CloudKit private DB when enabled; fall back to local store if unavailable.
    private static func makeModelContainer(preferCloud: Bool) -> ModelContainer {
        let schema = Schema([Expense.self, MonthlyBudget.self, CategoryItem.self, SavingsGoal.self, Trip.self, DebtLoan.self])

        if preferCloud {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
                return container
            }
        }

        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            let url = localConfig.url
            try? FileManager.default.removeItem(at: url)
            let sibling = url.deletingLastPathComponent()
            for name in ["default.store", "default.store-shm", "default.store-wal"] {
                try? FileManager.default.removeItem(at: sibling.appendingPathComponent(name))
            }
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "masarify" else { return }
        let host = (url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).lowercased()
        if host == "voice" {
            WidgetBudgetStore.requestVoiceCapture()
            NotificationCenter.default.post(name: .masarifyOpenVoice, object: nil)
        } else if host == "add" || host == "expense" {
            WidgetBudgetStore.requestAddExpense()
            NotificationCenter.default.post(name: .masarifyOpenAddExpense, object: nil)
        } else if host == "home" {
            NotificationCenter.default.post(name: .masarifyOpenHome, object: nil)
        } else if host == "report" || host == "summary" {
            NotificationCenter.default.post(name: .masarifyOpenReport, object: nil)
        }
    }

    private func seedDemoDataIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-seedDemoData") else { return }
        let context = sharedModelContainer.mainContext
        CategoryItem.seedDefaults(into: context)

        let existingExpenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        if existingExpenses.isEmpty {
            let samples: [(Double, String, String, ExpenseSource)] = [
                (85, BuiltInCategory.food.rawValue, "غداء عمل", .manual),
                (45, BuiltInCategory.transport.rawValue, "أوبر للمنزل", .voice),
                (320, BuiltInCategory.bills.rawValue, "فاتورة نت", .receipt),
                (150, BuiltInCategory.entertainment.rawValue, "سينما", .manual)
            ]
            for (amount, categoryId, note, source) in samples {
                context.insert(
                    Expense(amount: amount, categoryId: categoryId, note: note, date: .now, source: source)
                )
            }
        }

        let existingBudgets = (try? context.fetch(FetchDescriptor<MonthlyBudget>())) ?? []
        if existingBudgets.isEmpty {
            let month = MonthlyBudget.currentMonthKey()
            context.insert(MonthlyBudget(monthKey: month, categoryId: nil, limitAmount: 2000))
            context.insert(MonthlyBudget(monthKey: month, categoryId: BuiltInCategory.bills.rawValue, limitAmount: 400))
            context.insert(MonthlyBudget(monthKey: month, categoryId: BuiltInCategory.food.rawValue, limitAmount: 500))
        }
    }
}
