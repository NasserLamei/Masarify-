import Foundation

/// Shared App Group bridge between the app and WidgetKit extension.
enum WidgetShared {
    static let appGroupID = "group.com.masarify.app"
    static let snapshotKey = "masarify.widget.budgetSnapshot"
    static let voiceFlagKey = "masarify.widget.openVoice"
    static let addExpenseFlagKey = "masarify.widget.openAddExpense"
    static let periodKey = "masarify.widget.period"
    static let voiceURL = URL(string: "masarify://voice")!
    static let homeURL = URL(string: "masarify://home")!
    static let addExpenseURL = URL(string: "masarify://add")!

    /// Prefer App Group suite when available; otherwise `.standard`.
    static var defaults: UserDefaults {
        if let suite = UserDefaults(suiteName: appGroupID) {
            return suite
        }
        return .standard
    }
}

enum WidgetPeriod: String, Codable, CaseIterable {
    case day
    case week
    case month

    var titleAr: String {
        switch self {
        case .day: return "اليوم"
        case .week: return "الأسبوع"
        case .month: return "الشهر"
        }
    }

    var titleEn: String {
        switch self {
        case .day: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        }
    }

    func title(isArabic: Bool) -> String {
        isArabic ? titleAr : titleEn
    }

    /// Compact chip labels so period row fits medium height.
    var shortTitleAr: String {
        switch self {
        case .day: return "يوم"
        case .week: return "أسبوع"
        case .month: return "شهر"
        }
    }

    var shortTitleEn: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }

    func shortTitle(isArabic: Bool) -> String {
        isArabic ? shortTitleAr : shortTitleEn
    }
}

struct WidgetBudgetSnapshot: Codable, Equatable {
    var updatedAt: Date
    var isArabic: Bool
    var dayLimit: Double
    var daySpent: Double
    var weekLimit: Double
    var weekSpent: Double
    var monthLimit: Double
    var monthSpent: Double

    static let empty = WidgetBudgetSnapshot(
        updatedAt: .distantPast,
        isArabic: true,
        dayLimit: 0,
        daySpent: 0,
        weekLimit: 0,
        weekSpent: 0,
        monthLimit: 0,
        monthSpent: 0
    )

    func limit(for period: WidgetPeriod) -> Double {
        switch period {
        case .day: dayLimit
        case .week: weekLimit
        case .month: monthLimit
        }
    }

    func spent(for period: WidgetPeriod) -> Double {
        switch period {
        case .day: daySpent
        case .week: weekSpent
        case .month: monthSpent
        }
    }

    func remaining(for period: WidgetPeriod) -> Double {
        max(0, limit(for: period) - spent(for: period))
    }

    /// Remaining fraction (1 = full budget left, 0 = depleted). Ring shrinks as you spend.
    func remainingRatio(for period: WidgetPeriod) -> Double {
        let limit = limit(for: period)
        guard limit > 0 else { return 0 }
        return min(1, max(0, remaining(for: period) / limit))
    }

    func isOver(for period: WidgetPeriod) -> Bool {
        spent(for: period) > limit(for: period) && limit(for: period) > 0
    }
}

enum WidgetBudgetStore {
    static func save(_ snapshot: WidgetBudgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        WidgetShared.defaults.set(data, forKey: WidgetShared.snapshotKey)
    }

    static func load() -> WidgetBudgetSnapshot {
        guard let data = WidgetShared.defaults.data(forKey: WidgetShared.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetBudgetSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }

    static func preferredPeriod() -> WidgetPeriod {
        let raw = WidgetShared.defaults.string(forKey: WidgetShared.periodKey) ?? WidgetPeriod.day.rawValue
        return WidgetPeriod(rawValue: raw) ?? .day
    }

    static func setPreferredPeriod(_ period: WidgetPeriod) {
        WidgetShared.defaults.set(period.rawValue, forKey: WidgetShared.periodKey)
    }

    static func requestVoiceCapture() {
        WidgetShared.defaults.set(true, forKey: WidgetShared.voiceFlagKey)
    }

    static func consumeVoiceRequest() -> Bool {
        let flag = WidgetShared.defaults.bool(forKey: WidgetShared.voiceFlagKey)
        if flag {
            WidgetShared.defaults.set(false, forKey: WidgetShared.voiceFlagKey)
        }
        return flag
    }

    static func requestAddExpense() {
        WidgetShared.defaults.set(true, forKey: WidgetShared.addExpenseFlagKey)
    }

    static func consumeAddExpenseRequest() -> Bool {
        let flag = WidgetShared.defaults.bool(forKey: WidgetShared.addExpenseFlagKey)
        if flag {
            WidgetShared.defaults.set(false, forKey: WidgetShared.addExpenseFlagKey)
        }
        return flag
    }
}
