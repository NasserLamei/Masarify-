import SwiftUI
import SwiftData

@main
struct MasarifyApp: App {
    init() {
        AppAppearance.apply()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Expense.self, MonthlyBudget.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Schema grew (budgets) — reset local store for MVP rather than crash.
            let url = configuration.url
            try? FileManager.default.removeItem(at: url)
            let sibling = url.deletingLastPathComponent()
            for name in ["default.store", "default.store-shm", "default.store-wal"] {
                try? FileManager.default.removeItem(at: sibling.appendingPathComponent(name))
            }
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .environment(\.font, AppFont.body())
                .preferredColorScheme(.light)
                .onAppear {
                    AppAppearance.apply()
                    seedDemoDataIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func seedDemoDataIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-seedDemoData") else { return }
        let context = sharedModelContainer.mainContext
        let existingExpenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        if existingExpenses.isEmpty {
            let samples: [(Double, ExpenseCategory, String, ExpenseSource)] = [
                (85, .food, "غداء عمل", .manual),
                (45, .transport, "أوبر للمنزل", .voice),
                (320, .bills, "فاتورة نت", .receipt),
                (150, .entertainment, "سينما", .manual)
            ]
            for (amount, category, note, source) in samples {
                context.insert(
                    Expense(amount: amount, category: category, note: note, date: .now, source: source)
                )
            }
        }

        let existingBudgets = (try? context.fetch(FetchDescriptor<MonthlyBudget>())) ?? []
        if existingBudgets.isEmpty {
            let month = MonthlyBudget.currentMonthKey()
            // Overall roomy limit; bills at 320 with limit 400 → ~80% near-limit alert
            context.insert(MonthlyBudget(monthKey: month, category: nil, limitAmount: 2000))
            context.insert(MonthlyBudget(monthKey: month, category: .bills, limitAmount: 400))
            context.insert(MonthlyBudget(monthKey: month, category: .food, limitAmount: 500))
        }
    }
}
