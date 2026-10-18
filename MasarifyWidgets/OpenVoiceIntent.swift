import AppIntents
import Foundation
import WidgetKit

/// Opens Masarify straight into voice capture from the Home Screen widget.
struct OpenVoiceIntent: AppIntent {
    static var title: LocalizedStringResource = "تسجيل مصروف بالصوت"
    static var description = IntentDescription("يفتح مصاريفي على شاشة الصوت مباشرة.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        WidgetBudgetStore.requestVoiceCapture()
        return .result()
    }
}

struct OpenAddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "إضافة مصروف"
    static var description = IntentDescription("يفتح نموذج إضافة مصروف جديد.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        WidgetBudgetStore.requestAddExpense()
        return .result()
    }
}

struct SetWidgetPeriodIntent: AppIntent {
    static var title: LocalizedStringResource = "فترة الميزانية"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "الفترة")
    var periodRaw: String

    init() {
        periodRaw = WidgetPeriod.day.rawValue
    }

    init(period: WidgetPeriod) {
        periodRaw = period.rawValue
    }

    func perform() async throws -> some IntentResult {
        let period = WidgetPeriod(rawValue: periodRaw) ?? .day
        WidgetBudgetStore.setPreferredPeriod(period)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct ReloadWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "تحديث الويدجت"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct CycleWidgetPeriodIntent: AppIntent {
    static var title: LocalizedStringResource = "تبديل فترة الميزانية"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let current = WidgetBudgetStore.preferredPeriod()
        let all = WidgetPeriod.allCases
        let next = all[((all.firstIndex(of: current) ?? 0) + 1) % all.count]
        WidgetBudgetStore.setPreferredPeriod(next)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
