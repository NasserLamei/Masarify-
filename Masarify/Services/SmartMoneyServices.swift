import Foundation

enum NecessityKind: String, Codable {
    case essential
    case luxury
    case flexible

    func label(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.essential, .arabic): return "ضروري جداً"
        case (.essential, .english): return "Essential"
        case (.luxury, .arabic): return "رفاهيات"
        case (.luxury, .english): return "Luxury"
        case (.flexible, .arabic): return "مرن"
        case (.flexible, .english): return "Flexible"
        }
    }
}

enum NecessityClassifier {
    static func kind(for categoryId: String?) -> NecessityKind {
        switch categoryId {
        case BuiltInCategory.food.rawValue,
             BuiltInCategory.health.rawValue,
             BuiltInCategory.bills.rawValue:
            return .essential
        case BuiltInCategory.entertainment.rawValue,
             BuiltInCategory.shopping.rawValue:
            return .luxury
        default:
            return .flexible
        }
    }

    static func kind(for category: CategoryItem?) -> NecessityKind {
        kind(for: category?.id)
    }
}

struct SurvivalPlan: Equatable {
    var daysLeft: Int
    var remainingEssentialBudget: Double
    var dailyCap: Double
    var tips: [String]

    static func build(
        paydayDay: Int,
        expenses: [Expense],
        budgets: [MonthlyBudget],
        language: AppLanguage
    ) -> SurvivalPlan {
        let calendar = Calendar.current
        let now = Date()
        let day = calendar.component(.day, from: now)
        var days = paydayDay - day
        if days <= 0 { days += 30 }
        days = max(1, days)

        let monthKey = MonthlyBudget.currentMonthKey()
        let overall = budgets.first { $0.monthKey == monthKey && $0.categoryId == nil }
        let monthSpend = expenses
            .filter { MonthlyBudget.currentMonthKey(for: $0.date) == monthKey && !$0.isTripExpense }
            .reduce(0) { $0 + $1.amount }
        let limit = overall?.limitAmount ?? max(monthSpend * 1.2, 1000)
        let remaining = max(0, limit - monthSpend)
        let daily = remaining / Double(days)

        let tips: [String]
        if language == .arabic {
            tips = [
                "الأكل والشرب والعلاج فقط — الرفاهيات متوقفة.",
                "حدّ يومي تقريبي: \(CurrencyFormat.egp(daily, language: .arabic)).",
                "حضّر وجبات البيت عشان تقلل صرف السوبرماركت.",
                "أجّل أي شراء مش ضروري لحد ما المرتب ينزل."
            ]
        } else {
            tips = [
                "Essentials only — food, drink, medicine.",
                "Approx daily cap: \(CurrencyFormat.egp(daily, language: .english)).",
                "Cook at home to cut supermarket impulse buys.",
                "Postpone non-essentials until payday."
            ]
        }

        return SurvivalPlan(
            daysLeft: days,
            remainingEssentialBudget: remaining,
            dailyCap: daily,
            tips: tips
        )
    }
}

struct PeakInsight: Identifiable, Equatable {
    var id: String { title + detail }
    var title: String
    var detail: String
    var systemImage: String
}

enum SpendingInsightsService {
    static func peakInsights(
        expenses: [Expense],
        language: AppLanguage
    ) -> [PeakInsight] {
        guard !expenses.isEmpty else {
            return [
                PeakInsight(
                    title: language == .arabic ? "لسه بنجمع بيانات" : "Still learning",
                    detail: language == .arabic
                        ? "سجّل مصروفات أكتر عشان نطلع أوقات الذروة."
                        : "Log more expenses to unlock peak-time insights.",
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            ]
        }

        let calendar = Calendar.current
        var weekdayTotals: [Int: Double] = [:]
        var hourTotals: [Int: Double] = [:]
        for expense in expenses {
            let wd = calendar.component(.weekday, from: expense.date)
            let hour = calendar.component(.hour, from: expense.date)
            weekdayTotals[wd, default: 0] += expense.amount
            hourTotals[hour, default: 0] += expense.amount
        }

        let total = expenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        var insights: [PeakInsight] = []

        if let topDay = weekdayTotals.max(by: { $0.value < $1.value }) {
            let pct = Int((topDay.value / total * 100).rounded())
            let name = weekdayName(topDay.key, language: language)
            insights.append(
                PeakInsight(
                    title: language == .arabic ? "يوم الذروة" : "Peak day",
                    detail: language == .arabic
                        ? "\(pct)% من صرفك بيحصل يوم \(name)."
                        : "\(pct)% of your spending lands on \(name).",
                    systemImage: "calendar"
                )
            )
        }

        if let topHour = hourTotals.max(by: { $0.value < $1.value }) {
            let pct = Int((topHour.value / total * 100).rounded())
            let band = hourBand(topHour.key, language: language)
            insights.append(
                PeakInsight(
                    title: language == .arabic ? "ساعة الصفر" : "Zero hour",
                    detail: language == .arabic
                        ? "لاحظنا إن \(pct)% من الصرف بيحصل \(band) — خد بالك من المحفزات."
                        : "\(pct)% of spend happens \(band) — watch the triggers.",
                    systemImage: "clock.fill"
                )
            )
        }

        let evening = expenses.filter {
            let h = calendar.component(.hour, from: $0.date)
            return h >= 20 || h < 1
        }
        let eveningShare = evening.reduce(0) { $0 + $1.amount } / total
        if eveningShare >= 0.35 {
            let pct = Int((eveningShare * 100).rounded())
            insights.append(
                PeakInsight(
                    title: language == .arabic ? "ليلة السوشيال؟" : "Late-night scroll?",
                    detail: language == .arabic
                        ? "\(pct)% من فلوسك بتتخسر بالليل — غالباً وقت السوشيال ميديا."
                        : "\(pct)% of money goes out late — often while scrolling.",
                    systemImage: "moon.stars.fill"
                )
            )
        }

        let commute = expenses.filter {
            let h = calendar.component(.hour, from: $0.date)
            return (h >= 16 && h <= 19) && NecessityClassifier.kind(for: $0.categoryId) != .essential
        }
        if !commute.isEmpty {
            let amount = commute.reduce(0) { $0 + $1.amount }
            insights.append(
                PeakInsight(
                    title: language == .arabic ? "رجوع الشغل" : "Commute window",
                    detail: language == .arabic
                        ? "صرف إضافي حوالي \(CurrencyFormat.egp(amount, language: .arabic)) بين ٤ و٧ مساءً — سوبرماركت وأنت جعان؟"
                        : "Extra \(CurrencyFormat.egp(amount, language: .english)) between 4–7pm — hungry supermarket runs?",
                    systemImage: "bag.fill"
                )
            )
        }

        return insights
    }

    private static func weekdayName(_ weekday: Int, language: AppLanguage) -> String {
        let ar = ["", "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
        let en = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let list = language == .arabic ? ar : en
        guard weekday >= 1, weekday <= 7 else { return "—" }
        return list[weekday]
    }

    private static func hourBand(_ hour: Int, language: AppLanguage) -> String {
        switch hour {
        case 5..<12: return language == .arabic ? "الصبح" : "in the morning"
        case 12..<17: return language == .arabic ? "بعد الظهر" : "in the afternoon"
        case 17..<21: return language == .arabic ? "المساء" : "in the evening"
        default: return language == .arabic ? "بالليل" : "late at night"
        }
    }
}

struct SelfCompareInsight: Identifiable, Equatable {
    var id: String { categoryId + title }
    var categoryId: String
    var title: String
    var detail: String
    var improved: Bool
    var systemImage: String
}

enum SelfBenchmarkService {
    static func compare(
        expenses: [Expense],
        categories: [CategoryItem],
        language: AppLanguage
    ) -> [SelfCompareInsight] {
        let calendar = Calendar.current
        let now = Date()
        guard let thisStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let lastStart = calendar.date(byAdding: .month, value: -1, to: thisStart),
              let lastEnd = calendar.date(byAdding: .day, value: -1, to: thisStart) else {
            return []
        }

        let thisMonth = expenses.filter { $0.date >= thisStart }
        let lastMonth = expenses.filter { $0.date >= lastStart && $0.date <= lastEnd }
        guard !lastMonth.isEmpty else {
            return [
                SelfCompareInsight(
                    categoryId: "none",
                    title: language == .arabic ? "أول شهر مقارنة" : "First compare month",
                    detail: language == .arabic
                        ? "الشهر الجاي هنقارنك بنفسك — كمّل التسجيل."
                        : "Next month we'll compare you to yourself — keep logging.",
                    improved: true,
                    systemImage: "flag.checkered"
                )
            ]
        }

        let thisBy = Dictionary(grouping: thisMonth, by: \.categoryId)
        let lastBy = Dictionary(grouping: lastMonth, by: \.categoryId)
        var results: [SelfCompareInsight] = []

        for (id, lastItems) in lastBy {
            let lastSum = lastItems.reduce(0) { $0 + $1.amount }
            let thisSum = (thisBy[id] ?? []).reduce(0) { $0 + $1.amount }
            guard lastSum > 0 else { continue }
            let delta = lastSum - thisSum
            let pct = Int((abs(delta) / lastSum * 100).rounded())
            let category = CategoryItem.resolve(id: id, in: categories)
            let name: String = {
                guard let category else { return id }
                return language == .arabic ? category.nameAr : (category.nameEn.isEmpty ? category.nameAr : category.nameEn)
            }()

            if delta > 0.5 {
                results.append(
                    SelfCompareInsight(
                        categoryId: id,
                        title: language == .arabic ? "عاش!" : "Nice!",
                        detail: language == .arabic
                            ? "صرفت في \(name) أقل \(pct)% عن الشهر اللي فات، وفّرت \(CurrencyFormat.egp(delta, language: .arabic))."
                            : "You spent \(pct)% less on \(name) vs last month — saved \(CurrencyFormat.egp(delta, language: .english)).",
                        improved: true,
                        systemImage: "arrow.down.heart.fill"
                    )
                )
            } else if delta < -0.5 {
                results.append(
                    SelfCompareInsight(
                        categoryId: id,
                        title: language == .arabic ? "خد بالك" : "Heads up",
                        detail: language == .arabic
                            ? "\(name) أعلى \(pct)% عن الشهر اللي فات."
                            : "\(name) is up \(pct)% vs last month.",
                        improved: false,
                        systemImage: "arrow.up.right"
                    )
                )
            }
        }

        return results.sorted { $0.improved && !$1.improved }.prefix(5).map { $0 }
    }
}

// MARK: - Round-up micro-saving (تحدي الفكة)

struct RoundUpResult: Equatable {
    let spent: Double
    let rounded: Double
    let spare: Double

    var hasSpare: Bool { spare > 0.009 }
}

enum RoundUpService {
    /// Ceil to next `unit` (default 10 EGP). 23 → 30 spare 7; 30 → 30 spare 0.
    static func compute(amount: Double, unit: Double = 10) -> RoundUpResult {
        let spent = max(0, amount)
        guard unit > 0 else {
            return RoundUpResult(spent: spent, rounded: spent, spare: 0)
        }
        let steps = (spent / unit).rounded(.up)
        let rounded = steps * unit
        let spare = max(0, (rounded - spent).rounded(toPlaces: 2))
        return RoundUpResult(spent: spent, rounded: rounded, spare: spare)
    }

    /// Apply spare to the chosen goal (or first goal) and track piggy total.
    @MainActor
    static func applyIfNeeded(
        amount: Double,
        settings: AppSettings,
        goals: [SavingsGoal]
    ) -> RoundUpResult? {
        guard settings.roundUpEnabled else { return nil }
        let result = compute(amount: amount)
        guard result.hasSpare else { return result }

        settings.totalRoundUpSaved += result.spare

        let target: SavingsGoal? = {
            if let id = settings.roundUpGoalId,
               let match = goals.first(where: { $0.id.uuidString == id }) {
                return match
            }
            return goals.first
        }()

        if let target {
            target.savedAmount += result.spare
            if settings.roundUpGoalId == nil {
                settings.roundUpGoalId = target.id.uuidString
            }
        }
        return result
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}

// MARK: - True cost / Time-to-income (تكلفة الحقيقة)

struct TrueCostResult: Equatable {
    let amount: Double
    let hourlyRate: Double
    let hours: Double
    let shouldHighlight: Bool

    var hoursLabelArabic: String {
        if hours < 1 {
            let mins = Int((hours * 60).rounded())
            return "\(max(1, mins)) دقيقة"
        }
        let whole = Int(hours)
        let frac = hours - Double(whole)
        if frac < 0.15 {
            return whole == 1 ? "ساعة واحدة" : "\(whole) ساعات"
        }
        if frac < 0.65 {
            return whole == 0 ? "نص ساعة" : "\(whole) ساعة ونص"
        }
        return "\(whole + 1) ساعات"
    }

    var hoursLabelEnglish: String {
        if hours < 1 {
            let mins = Int((hours * 60).rounded())
            return "\(max(1, mins)) minutes"
        }
        let rounded = (hours * 10).rounded() / 10
        return rounded == 1 ? "1 hour" : "\(rounded) hours"
    }

    func message(itemName: String, language: AppLanguage) -> String {
        switch language {
        case .arabic:
            return "«\(itemName)» ده معناه إنك اشتغلت \(hoursLabelArabic) عشانه!"
        case .english:
            return "“\(itemName)” means you worked \(hoursLabelEnglish) for it!"
        }
    }
}

enum TrueCostService {
    /// Default working hours/month (~22 days × 8h).
    static let defaultHoursPerMonth: Double = 176

    static func compute(
        amount: Double,
        monthlyIncome: Double,
        hoursPerMonth: Double = defaultHoursPerMonth,
        isLuxury: Bool,
        largeThresholdHours: Double = 1.0
    ) -> TrueCostResult? {
        guard monthlyIncome > 0, hoursPerMonth > 0, amount > 0 else { return nil }
        let rate = monthlyIncome / hoursPerMonth
        guard rate > 0 else { return nil }
        let hours = amount / rate
        let shouldHighlight = isLuxury || hours >= largeThresholdHours
        return TrueCostResult(
            amount: amount,
            hourlyRate: rate,
            hours: hours,
            shouldHighlight: shouldHighlight
        )
    }
}

// MARK: - Ghost subscriptions hunter

struct GhostSubscription: Identifiable, Equatable {
    var id: String
    var label: String
    var monthlyAmount: Double
    var monthsSeen: Int
    var totalPaid: Double
    var categoryId: String?
    var systemImage: String

    func report(language: AppLanguage) -> String {
        let amount = CurrencyFormat.egp(monthlyAmount, language: language)
        let total = CurrencyFormat.egp(totalPaid, language: language)
        switch language {
        case .arabic:
            return "انت دافع \(amount) لـ«\(label)» بقالك \(monthsSeen) شهور (إجمالي \(total))، ومفيش إشارة إنك بتستخدمها.. تحب نشيلها من لستتك؟"
        case .english:
            return "You've paid \(amount) for “\(label)” for \(monthsSeen) months (total \(total)) with no sign of use.. remove it from your list?"
        }
    }
}

enum GhostSubscriptionHunter {
    private static let subscriptionHints: [String] = [
        "نتفليكس", "netflix", "spotify", "سبوتيفاي", "شاهد", "shahid", "osn", "disney",
        "يوتيوب", "youtube", "icloud", "apple", "google", "اشتراك", "subscription",
        "جيم", "gym", "نادي", "prime", "game pass", "xbox", "playstation", "ps plus",
        "canva", "openai", "chatgpt", "cursor", "adobe"
    ]

    static func detect(
        expenses: [Expense],
        categories: [CategoryItem],
        language: AppLanguage,
        dismissedIds: Set<String>
    ) -> [GhostSubscription] {
        let calendar = Calendar.current
        let nonTrip = expenses.filter { !$0.isTripExpense }
        guard !nonTrip.isEmpty else { return [] }

        // Group by normalized label key
        var buckets: [String: [Expense]] = [:]
        for expense in nonTrip {
            let key = normalizeKey(expense)
            guard !key.isEmpty else { continue }
            buckets[key, default: []].append(expense)
        }

        var ghosts: [GhostSubscription] = []
        for (key, items) in buckets {
            guard items.count >= 2 else { continue }
            let months = Set(items.map { monthKey(for: $0.date, calendar: calendar) })
            guard months.count >= 2 else { continue }

            let amounts = items.map(\.amount).sorted()
            let median = amounts[amounts.count / 2]
            guard median >= 20 else { continue }

            // Similar recurring amounts (±20%)
            let similar = items.filter { abs($0.amount - median) / max(median, 1) <= 0.2 }
            guard similar.count >= 2 else { continue }
            let similarMonths = Set(similar.map { monthKey(for: $0.date, calendar: calendar) })
            guard similarMonths.count >= 2 else { continue }

            let categoryId = similar.first?.categoryId
            let looksSub = isSubscriptionLike(label: key, categoryId: categoryId)
            // Entertainment/shopping recurring OR explicit subscription keywords
            guard looksSub else { continue }

            let id = key
            guard !dismissedIds.contains(id) else { continue }

            let monthly = similar.map(\.amount).reduce(0, +) / Double(similarMonths.count)
            let total = similar.reduce(0) { $0 + $1.amount }
            let label = displayLabel(from: similar, language: language, categories: categories)

            ghosts.append(
                GhostSubscription(
                    id: id,
                    label: label,
                    monthlyAmount: monthly,
                    monthsSeen: similarMonths.count,
                    totalPaid: total,
                    categoryId: categoryId,
                    systemImage: "eye.trianglebadge.exclamationmark"
                )
            )
        }

        return ghosts.sorted { $0.totalPaid > $1.totalPaid }
    }

    private static func monthKey(for date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    private static func normalizeKey(_ expense: Expense) -> String {
        let merchant = (expense.merchant ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let note = expense.note.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = !merchant.isEmpty ? merchant : note
        let cleaned = base
            .replacingOccurrences(of: #"\d+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count >= 3 { return cleaned }
        return expense.categoryId
    }

    private static func isSubscriptionLike(label: String, categoryId: String?) -> Bool {
        let lower = label.lowercased()
        if subscriptionHints.contains(where: { lower.contains($0) }) { return true }
        switch categoryId {
        case BuiltInCategory.entertainment.rawValue,
             BuiltInCategory.shopping.rawValue:
            return true
        default:
            return false
        }
    }

    private static func displayLabel(
        from items: [Expense],
        language: AppLanguage,
        categories: [CategoryItem]
    ) -> String {
        if let merchant = items.compactMap(\.merchant).first(where: { !$0.isEmpty }) {
            return merchant
        }
        if let note = items.map(\.note).first(where: { !$0.isEmpty }) {
            return note
        }
        if let id = items.first?.categoryId,
           let cat = CategoryItem.resolve(id: id, in: categories) {
            return language == .arabic ? cat.nameAr : (cat.nameEn.isEmpty ? cat.nameAr : cat.nameEn)
        }
        return language == .arabic ? "اشتراك" : "Subscription"
    }
}
