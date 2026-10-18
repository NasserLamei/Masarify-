import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic
    case english

    var id: String { rawValue }

    /// UI locale — Arabic keeps RTL/copy, but digits stay Western (0–9).
    var locale: Locale {
        switch self {
        case .arabic: Locale(identifier: "ar_EG@numbers=latn")
        case .english: Locale(identifier: "en_US")
        }
    }

    /// Always Western digits for currency / amount formatters.
    static var latinDigitsLocale: Locale { Locale(identifier: "en_US_POSIX") }

    var layoutDirection: LayoutDirection {
        switch self {
        case .arabic: .rightToLeft
        case .english: .leftToRight
        }
    }
}

/// Which calendar day the daily-summary notification describes.
enum DailySummaryFocusDay: String, CaseIterable, Identifiable {
    case today
    case yesterday

    var id: String { rawValue }

    func date(relativeTo now: Date = .now, calendar: Calendar = .current) -> Date {
        switch self {
        case .today: return now
        case .yesterday: return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey) }
    }

    @Published var isDarkMode: Bool {
        didSet { UserDefaults.standard.set(isDarkMode, forKey: Self.darkKey) }
    }

    /// Emergency safety net ("فلوس الأزمات").
    @Published var emergencyModeEnabled: Bool {
        didSet { UserDefaults.standard.set(emergencyModeEnabled, forKey: Self.emergencyKey) }
    }

    /// Day of month payday usually arrives (1...28).
    @Published var paydayDay: Int {
        didSet { UserDefaults.standard.set(paydayDay, forKey: Self.paydayKey) }
    }

    /// Round-up micro-saving challenge (تحدي الفكة).
    @Published var roundUpEnabled: Bool {
        didSet { UserDefaults.standard.set(roundUpEnabled, forKey: Self.roundUpEnabledKey) }
    }

    /// Goal that receives round-up spare (UUID string).
    @Published var roundUpGoalId: String? {
        didSet { UserDefaults.standard.set(roundUpGoalId, forKey: Self.roundUpGoalKey) }
    }

    /// Lifetime spare saved via round-up (hidden piggy meter).
    @Published var totalRoundUpSaved: Double {
        didSet { UserDefaults.standard.set(totalRoundUpSaved, forKey: Self.roundUpTotalKey) }
    }

    /// True-cost / time-to-income converter.
    @Published var trueCostEnabled: Bool {
        didSet { UserDefaults.standard.set(trueCostEnabled, forKey: Self.trueCostEnabledKey) }
    }

    /// Approximate monthly income (EGP) used for hour conversion.
    @Published var monthlyIncome: Double {
        didSet { UserDefaults.standard.set(monthlyIncome, forKey: Self.monthlyIncomeKey) }
    }

    /// Working hours assumed per month (default 176).
    @Published var workHoursPerMonth: Double {
        didSet { UserDefaults.standard.set(workHoursPerMonth, forKey: Self.workHoursKey) }
    }

    /// Ghost subscription hunter toggle.
    @Published var ghostHunterEnabled: Bool {
        didSet { UserDefaults.standard.set(ghostHunterEnabled, forKey: Self.ghostEnabledKey) }
    }

    /// Dismissed ghost subscription ids.
    @Published var dismissedGhostIds: [String] {
        didSet { UserDefaults.standard.set(dismissedGhostIds, forKey: Self.ghostDismissedKey) }
    }

    /// Local notification with yesterday's spend summary.
    @Published var dailySummaryEnabled: Bool {
        didSet { UserDefaults.standard.set(dailySummaryEnabled, forKey: Self.dailySummaryEnabledKey) }
    }

    /// Hour of day (0...23) to fire the daily summary.
    @Published var dailySummaryHour: Int {
        didSet { UserDefaults.standard.set(dailySummaryHour, forKey: Self.dailySummaryHourKey) }
    }

    /// Minute (0...59) for the daily summary notification.
    @Published var dailySummaryMinute: Int {
        didSet { UserDefaults.standard.set(dailySummaryMinute, forKey: Self.dailySummaryMinuteKey) }
    }

    /// Which day the notification summarizes: today or yesterday.
    @Published var dailySummaryFocusDay: DailySummaryFocusDay {
        didSet { UserDefaults.standard.set(dailySummaryFocusDay.rawValue, forKey: Self.dailySummaryFocusDayKey) }
    }

    /// Binding helper for `DatePicker` (.hourAndMinute).
    var dailySummaryTime: Date {
        get {
            var comps = DateComponents()
            comps.hour = dailySummaryHour
            comps.minute = dailySummaryMinute
            return Calendar.current.date(from: comps) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            dailySummaryHour = comps.hour ?? 9
            dailySummaryMinute = comps.minute ?? 0
        }
    }

    /// Require Face ID / Touch ID when opening the app.
    @Published var biometricLockEnabled: Bool {
        didSet { UserDefaults.standard.set(biometricLockEnabled, forKey: Self.biometricLockKey) }
    }

    /// Prefer SwiftData + CloudKit sync (applied on next cold launch).
    @Published var iCloudSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(iCloudSyncEnabled, forKey: Self.iCloudSyncKey) }
    }

    /// First-launch benefit carousel completed.
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.onboardingKey) }
    }

    /// In-app feature tour after onboarding completed.
    @Published var hasCompletedFeatureTour: Bool {
        didSet { UserDefaults.standard.set(hasCompletedFeatureTour, forKey: Self.featureTourKey) }
    }

    /// Active saving challenges from the financial coach.
    @Published var activeChallenges: [FinancialCoachService.ActiveChallenge] {
        didSet { Self.persistChallenges(activeChallenges) }
    }

    /// When on, the coach reads tips aloud (TTS).
    @Published var coachVoiceEnabled: Bool {
        didSet {
            UserDefaults.standard.set(coachVoiceEnabled, forKey: Self.coachVoiceKey)
            if !coachVoiceEnabled {
                Task { @MainActor in CoachSpeechService.shared.stop() }
            }
        }
    }

    /// Read before `ModelContainer` is created (not MainActor-bound).
    static var prefersICloudSync: Bool {
        if UserDefaults.standard.object(forKey: iCloudSyncKey) == nil { return true }
        return UserDefaults.standard.bool(forKey: iCloudSyncKey)
    }

    private static let languageKey = "masarify.language"
    private static let darkKey = "masarify.darkMode"
    private static let emergencyKey = "masarify.emergencyMode"
    private static let paydayKey = "masarify.paydayDay"
    private static let roundUpEnabledKey = "masarify.roundUpEnabled"
    private static let roundUpGoalKey = "masarify.roundUpGoalId"
    private static let roundUpTotalKey = "masarify.roundUpTotal"
    private static let trueCostEnabledKey = "masarify.trueCostEnabled"
    private static let monthlyIncomeKey = "masarify.monthlyIncome"
    private static let workHoursKey = "masarify.workHoursPerMonth"
    private static let ghostEnabledKey = "masarify.ghostHunterEnabled"
    private static let ghostDismissedKey = "masarify.ghostDismissed"
    private static let dailySummaryEnabledKey = "masarify.dailySummaryEnabled"
    private static let dailySummaryHourKey = "masarify.dailySummaryHour"
    private static let dailySummaryMinuteKey = "masarify.dailySummaryMinute"
    private static let dailySummaryFocusDayKey = "masarify.dailySummaryFocusDay"
    private static let biometricLockKey = "masarify.biometricLockEnabled"
    private static let iCloudSyncKey = "masarify.iCloudSyncEnabled"
    private static let onboardingKey = "masarify.hasCompletedOnboarding"
    private static let featureTourKey = "masarify.hasCompletedFeatureTour"
    private static let challengesKey = "masarify.activeChallenges"
    private static let coachVoiceKey = "masarify.coachVoiceEnabled"

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.languageKey) ?? AppLanguage.arabic.rawValue
        language = AppLanguage(rawValue: raw) ?? .arabic
        isDarkMode = UserDefaults.standard.bool(forKey: Self.darkKey)
        emergencyModeEnabled = UserDefaults.standard.bool(forKey: Self.emergencyKey)
        let day = UserDefaults.standard.integer(forKey: Self.paydayKey)
        paydayDay = (1...28).contains(day) ? day : 25
        roundUpEnabled = UserDefaults.standard.bool(forKey: Self.roundUpEnabledKey)
        roundUpGoalId = UserDefaults.standard.string(forKey: Self.roundUpGoalKey)
        totalRoundUpSaved = UserDefaults.standard.double(forKey: Self.roundUpTotalKey)
        trueCostEnabled = UserDefaults.standard.object(forKey: Self.trueCostEnabledKey) as? Bool ?? true
        let income = UserDefaults.standard.double(forKey: Self.monthlyIncomeKey)
        monthlyIncome = income > 0 ? income : 8000
        let hours = UserDefaults.standard.double(forKey: Self.workHoursKey)
        workHoursPerMonth = hours > 0 ? hours : TrueCostService.defaultHoursPerMonth
        ghostHunterEnabled = UserDefaults.standard.object(forKey: Self.ghostEnabledKey) as? Bool ?? true
        dismissedGhostIds = UserDefaults.standard.stringArray(forKey: Self.ghostDismissedKey) ?? []
        dailySummaryEnabled = UserDefaults.standard.bool(forKey: Self.dailySummaryEnabledKey)
        let hour = UserDefaults.standard.integer(forKey: Self.dailySummaryHourKey)
        dailySummaryHour = (0...23).contains(hour) && UserDefaults.standard.object(forKey: Self.dailySummaryHourKey) != nil
            ? hour
            : 9
        let minute = UserDefaults.standard.integer(forKey: Self.dailySummaryMinuteKey)
        dailySummaryMinute = (0...59).contains(minute) && UserDefaults.standard.object(forKey: Self.dailySummaryMinuteKey) != nil
            ? minute
            : 0
        let focusRaw = UserDefaults.standard.string(forKey: Self.dailySummaryFocusDayKey)
        dailySummaryFocusDay = DailySummaryFocusDay(rawValue: focusRaw ?? "") ?? .yesterday
        biometricLockEnabled = UserDefaults.standard.bool(forKey: Self.biometricLockKey)
        iCloudSyncEnabled = UserDefaults.standard.object(forKey: Self.iCloudSyncKey) as? Bool ?? true
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        hasCompletedFeatureTour = UserDefaults.standard.bool(forKey: Self.featureTourKey)
        activeChallenges = Self.loadChallenges()
        coachVoiceEnabled = UserDefaults.standard.bool(forKey: Self.coachVoiceKey)
    }

    func startChallenge(_ kind: FinancialCoachService.ChallengeKind) {
        // One active challenge at a time keeps the coach clear.
        let challenge = FinancialCoachService.start(kind: kind, roundUpTotal: totalRoundUpSaved)
        activeChallenges = [challenge]
        if kind == .spareChange {
            roundUpEnabled = true
        }
    }

    func clearChallenge(id: String) {
        activeChallenges.removeAll { $0.id == id }
    }

    func clearAllChallenges() {
        activeChallenges = []
    }

    private static func loadChallenges() -> [FinancialCoachService.ActiveChallenge] {
        guard let data = UserDefaults.standard.data(forKey: challengesKey),
              let decoded = try? JSONDecoder().decode([FinancialCoachService.ActiveChallenge].self, from: data)
        else { return [] }
        return decoded
    }

    private static func persistChallenges(_ value: [FinancialCoachService.ActiveChallenge]) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: challengesKey)
    }

    var hourlyRate: Double {
        guard workHoursPerMonth > 0 else { return 0 }
        return monthlyIncome / workHoursPerMonth
    }

    func dismissGhost(_ id: String) {
        guard !dismissedGhostIds.contains(id) else { return }
        dismissedGhostIds.append(id)
    }

    var preferredColorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }

    func t(_ key: L10n.Key) -> String {
        L10n.string(key, language: language)
    }

    func categoryLabel(_ item: CategoryItem) -> String {
        switch language {
        case .arabic: item.nameAr
        case .english: item.nameEn.isEmpty ? item.nameAr : item.nameEn
        }
    }
}
