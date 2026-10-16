import SwiftUI
import SwiftData

@main
struct MasarifyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Expense.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .preferredColorScheme(.light)
                .onAppear {
                    seedDemoDataIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func seedDemoDataIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-seedDemoData") else { return }
        let context = sharedModelContainer.mainContext
        let existing = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        guard existing.isEmpty else { return }
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
}
