import Foundation

/// On-device financial coach — friendly Egyptian / English nudges + saving challenges.
enum FinancialCoachService {
    struct Tip: Identifiable, Equatable {
        enum Tone: String { case nudge, cheer, watch, challenge }
        var id: String
        var tone: Tone
        var title: String
        var message: String
        var systemImage: String
    }

    enum ChallengeKind: String, CaseIterable, Codable, Identifiable {
        case noCafe5
        case spareChange
        case noFun3
        case cookHome4

        var id: String { rawValue }

        var durationDays: Int {
            switch self {
            case .noCafe5: return 5
            case .spareChange: return 7
            case .noFun3: return 3
            case .cookHome4: return 4
            }
        }

        func title(_ language: AppLanguage) -> String {
            switch (self, language) {
            case (.noCafe5, .arabic): return "تحدي ٥ أيام بدون كافيهات"
            case (.noCafe5, .english): return "5 days without cafés"
            case (.spareChange, .arabic): return "تحدي حصالة الخردة"
            case (.spareChange, .english): return "Spare-change piggy"
            case (.noFun3, .arabic): return "٣ أيام بدون ترفيه"
            case (.noFun3, .english): return "3 days off entertainment"
            case (.cookHome4, .arabic): return "٤ أيام أكل بيت"
            case (.cookHome4, .english): return "4 days home cooking"
            }
        }

        func detail(_ language: AppLanguage) -> String {
            switch (self, language) {
            case (.noCafe5, .arabic): return "منغير قهوة برّه ولا كافيه — وفّر وأثبت لنفسك إنك قدّها."
            case (.noCafe5, .english): return "Skip café / coffee-out spends and prove the streak."
            case (.spareChange, .arabic): return "فعّل التقريب لأعلى وادّخر الخردة ٧ أيام — هدف بسيط: ٢٠ ج."
            case (.spareChange, .english): return "Keep round-ups on for 7 days — aim for ~20 EGP spare change."
            case (.noFun3, .arabic): return "ثلاث أيام من غير سينما/ألعاب/خروج ترفيهي."
            case (.noFun3, .english): return "Three days without fun / outing category spends."
            case (.cookHome4, .arabic): return "٤ أيام ركّز على أكل البيت وقلّل الطلبات السريعة."
            case (.cookHome4, .english): return "Four days favoring home meals over takeout cues."
            }
        }

        var systemImage: String {
            switch self {
            case .noCafe5: return "cup.and.saucer.fill"
            case .spareChange: return "coloncurrencysign.circle.fill"
            case .noFun3: return "film.fill"
            case .cookHome4: return "fork.knife"
            }
        }

        var accentHex: UInt32 {
            switch self {
            case .noCafe5: return 0xC9891A
            case .spareChange: return 0x14948F
            case .noFun3: return 0xD94F3D
            case .cookHome4: return 0x1A7A9C
            }
        }
    }

    struct ActiveChallenge: Codable, Identifiable, Equatable {
        var id: String
        var kindRaw: String
        var startedAt: Date
        var roundUpBaseline: Double

        var kind: ChallengeKind? { ChallengeKind(rawValue: kindRaw) }

        var endDate: Date {
            let days = kind?.durationDays ?? 5
            return Calendar.current.date(byAdding: .day, value: days, to: Calendar.current.startOfDay(for: startedAt))
                ?? startedAt.addingTimeInterval(Double(days) * 86400)
        }

        var daysRemaining: Int {
            let cal = Calendar.current
            let today = cal.startOfDay(for: .now)
            let end = cal.startOfDay(for: endDate)
            return max(0, cal.dateComponents([.day], from: today, to: end).day ?? 0)
        }
    }

    enum ChallengeStatus: Equatable {
        case active(daysLeft: Int, progress: Double)
        case won
        case failed(reason: String)
    }

    // MARK: - Tips

    static func tips(
        expenses: [Expense],
        budgets: [MonthlyBudget],
        categories: [CategoryItem],
        language: AppLanguage,
        activeChallenges: [ActiveChallenge]
    ) -> [Tip] {
        var result: [Tip] = []
        let cal = Calendar.current
        let now = Date()
        let day = cal.component(.day, from: now)
        let monthKey = MonthlyBudget.currentMonthKey()
        let monthExpenses = expenses.filter {
            MonthlyBudget.currentMonthKey(for: $0.date) == monthKey && !$0.isTripExpense
        }
        let monthTotal = monthExpenses.reduce(0) { $0 + $1.amount }
        let overallBudget = budgets.first { $0.monthKey == monthKey && $0.categoryId == nil }?.limitAmount
        let funSpend = monthExpenses
            .filter { $0.categoryId == BuiltInCategory.entertainment.rawValue }
            .reduce(0) { $0 + $1.amount }
        let shopSpend = monthExpenses
            .filter { $0.categoryId == BuiltInCategory.shopping.rawValue }
            .reduce(0) { $0 + $1.amount }
        let foodSpend = monthExpenses
            .filter { $0.categoryId == BuiltInCategory.food.rawValue }
            .reduce(0) { $0 + $1.amount }

        // Early-month luxury pace warning
        if day <= 10, funSpend >= 200 {
            let expectedPace = (overallBudget ?? max(monthTotal * 1.4, 2000)) * (Double(day) / 30.0)
            if funSpend >= expectedPace * 0.35 || funSpend >= 350 {
                result.append(
                    Tip(
                        id: "early-fun-\(monthKey)",
                        tone: .watch,
                        title: language == .arabic ? "يا باشا… على مهلك" : "Easy, champ",
                        message: language == .arabic
                            ? "إحنا لسه في أول \(day) أيام، والترفيه واصل \(CurrencyFormat.egp(funSpend, language: .arabic)). الرحلات دي هتعمل أزمة في آخر الشهر!"
                            : "We’re only on day \(day) and entertainment is already \(CurrencyFormat.egp(funSpend, language: .english)). That pace will sting later this month.",
                        systemImage: "exclamationmark.bubble.fill"
                    )
                )
            }
        }

        // Shopping surge
        if day <= 12, shopSpend >= 400 {
            result.append(
                Tip(
                    id: "shop-surge-\(monthKey)",
                    tone: .nudge,
                    title: language == .arabic ? "التسوّق بيجري أسرع منك" : "Shopping is ahead of you",
                    message: language == .arabic
                        ? "صرف التسوق الشهر ده \(CurrencyFormat.egp(shopSpend, language: .arabic)). لو مش ضروري، أجّله لأسبوع الجاي."
                        : "Shopping this month is \(CurrencyFormat.egp(shopSpend, language: .english)). If it’s not essential, park it for next week.",
                    systemImage: "bag.fill"
                )
            )
        }

        // Food / café lean
        if foodSpend >= 500, day <= 15 {
            result.append(
                Tip(
                    id: "food-lean-\(monthKey)",
                    tone: .nudge,
                    title: language == .arabic ? "الأكل برّه بيزق الميزانية" : "Eating out is pushing the budget",
                    message: language == .arabic
                        ? "أكلك واصل \(CurrencyFormat.egp(foodSpend, language: .arabic)). جرّب تحدي أيام البيت أو تحدي بدون كافيهات."
                        : "Food is at \(CurrencyFormat.egp(foodSpend, language: .english)). Try a home-cooking or no-café challenge.",
                    systemImage: "fork.knife"
                )
            )
        }

        // Cheer when pacing well
        if let budget = overallBudget, budget > 0, day >= 5 {
            let expected = budget * (Double(day) / Double(cal.range(of: .day, in: .month, for: now)?.count ?? 30))
            if monthTotal > 0, monthTotal <= expected * 0.85 {
                result.append(
                    Tip(
                        id: "pace-good-\(monthKey)-\(day)",
                        tone: .cheer,
                        title: language == .arabic ? "ماشي تمام يا بطل" : "Nice pace",
                        message: language == .arabic
                            ? "صرفك أقل من معدّل الشهر — كمّل بنفس الأسلوب، والمحفظة هتشكرك آخر الشهر."
                            : "You’re under the monthly pace — keep it up and month-end will thank you.",
                        systemImage: "hand.thumbsup.fill"
                    )
                )
            }
        }

        // Challenge prompt if none active
        if activeChallenges.isEmpty {
            result.append(
                Tip(
                    id: "challenge-prompt",
                    tone: .challenge,
                    title: language == .arabic ? "نلعب تحدي ادخار؟" : "Up for a saving challenge?",
                    message: language == .arabic
                        ? "تحدي ٥ أيام بدون كافيهات، أو حصالة الخردة — قصير وممتع ويفرق في الجيب."
                        : "Try 5 days without cafés, or the spare-change piggy — short, fun, and wallet-friendly.",
                    systemImage: "flag.checkered"
                )
            )
        } else if let active = activeChallenges.first, let kind = active.kind {
            let status = evaluate(challenge: active, expenses: expenses, roundUpTotal: nil, language: language)
            switch status {
            case .active(let daysLeft, _):
                result.append(
                    Tip(
                        id: "challenge-active-\(active.id)",
                        tone: .cheer,
                        title: kind.title(language),
                        message: language == .arabic
                            ? "فاضل \(daysLeft) يوم على التحدي — متستسلمش!"
                            : "\(daysLeft) day(s) left — don’t break the streak!",
                        systemImage: kind.systemImage
                    )
                )
            case .won:
                result.append(
                    Tip(
                        id: "challenge-won-\(active.id)",
                        tone: .cheer,
                        title: language == .arabic ? "كسبت التحدي!" : "Challenge cleared!",
                        message: language == .arabic
                            ? "\(kind.title(language)) خلص بنجاح. فخور بيك — اختار تحدي جديد؟"
                            : "\(kind.title(language)) done. Proud of you — pick another?",
                        systemImage: "trophy.fill"
                    )
                )
            case .failed(let reason):
                result.append(
                    Tip(
                        id: "challenge-fail-\(active.id)",
                        tone: .nudge,
                        title: language == .arabic ? "التحدي اتكسر… عادي" : "Streak broke — it’s fine",
                        message: reason,
                        systemImage: "arrow.counterclockwise"
                    )
                )
            }
        }

        if result.isEmpty {
            result.append(
                Tip(
                    id: "default",
                    tone: .cheer,
                    title: language == .arabic ? "أنا معاك في الفلوس" : "I’ve got your back",
                    message: language == .arabic
                        ? "سجّل مصاريفك بالصوت أو الكاميرا، وأنا هنبّهك بلُطف لو الإيقاع بقى خطر."
                        : "Log with voice or camera — I’ll nudge you gently if the pace gets risky.",
                    systemImage: "person.wave.2.fill"
                )
            )
        }

        return result
    }

    static func primaryTip(
        expenses: [Expense],
        budgets: [MonthlyBudget],
        categories: [CategoryItem],
        language: AppLanguage,
        activeChallenges: [ActiveChallenge]
    ) -> Tip {
        tips(
            expenses: expenses,
            budgets: budgets,
            categories: categories,
            language: language,
            activeChallenges: activeChallenges
        ).first!
    }

    // MARK: - Challenges

    static func evaluate(
        challenge: ActiveChallenge,
        expenses: [Expense],
        roundUpTotal: Double?,
        language: AppLanguage
    ) -> ChallengeStatus {
        guard let kind = challenge.kind else {
            return .failed(reason: language == .arabic ? "تحدي غير معروف" : "Unknown challenge")
        }

        let cal = Calendar.current
        let start = cal.startOfDay(for: challenge.startedAt)
        let end = challenge.endDate
        let window = expenses.filter { $0.date >= start && $0.date < end && !$0.isTripExpense }
        let now = Date()

        switch kind {
        case .noCafe5:
            let hits = window.filter { isCafeLike($0) }
            if let first = hits.first {
                let reason = language == .arabic
                    ? "اتكتب كافيه/قهوة (\(CurrencyFormat.egp(first.amount, language: .arabic))). نبدأ من جديد لما تكون جاهز."
                    : "A café-like spend of \(CurrencyFormat.egp(first.amount, language: .english)) broke it. Restart when ready."
                return .failed(reason: reason)
            }
            if now >= end { return .won }
            let progress = 1 - Double(challenge.daysRemaining) / Double(kind.durationDays)
            return .active(daysLeft: challenge.daysRemaining, progress: min(1, max(0, progress)))

        case .noFun3:
            let hits = window.filter { $0.categoryId == BuiltInCategory.entertainment.rawValue }
            if let first = hits.first {
                let reason = language == .arabic
                    ? "فيه ترفيه بـ \(CurrencyFormat.egp(first.amount, language: .arabic)) — التحدي وقف."
                    : "Entertainment of \(CurrencyFormat.egp(first.amount, language: .english)) ended the streak."
                return .failed(reason: reason)
            }
            if now >= end { return .won }
            let progress = 1 - Double(challenge.daysRemaining) / Double(kind.durationDays)
            return .active(daysLeft: challenge.daysRemaining, progress: min(1, max(0, progress)))

        case .cookHome4:
            let hits = window.filter { isTakeoutLike($0) }
            if let first = hits.first {
                let reason = language == .arabic
                    ? "طلب برّه/توصيل ظاهر (\(CurrencyFormat.egp(first.amount, language: .arabic)))."
                    : "Takeout-like spend (\(CurrencyFormat.egp(first.amount, language: .english))) broke the cook-home run."
                return .failed(reason: reason)
            }
            if now >= end { return .won }
            let progress = 1 - Double(challenge.daysRemaining) / Double(kind.durationDays)
            return .active(daysLeft: challenge.daysRemaining, progress: min(1, max(0, progress)))

        case .spareChange:
            let gained = max(0, (roundUpTotal ?? 0) - challenge.roundUpBaseline)
            let target = 20.0
            if gained >= target { return .won }
            if now >= end {
                return gained >= target * 0.5
                    ? .won
                    : .failed(
                        reason: language == .arabic
                            ? "الخردة المجمّعة \(CurrencyFormat.egp(gained, language: .arabic)) — جرّب تاني مع التقريب لأعلى."
                            : "Spare change hit \(CurrencyFormat.egp(gained, language: .english)) — retry with round-ups on."
                    )
            }
            return .active(daysLeft: challenge.daysRemaining, progress: min(1, gained / target))
        }
    }

    private static func isCafeLike(_ expense: Expense) -> Bool {
        let note = expense.note.lowercased()
        let keys = ["كافيه", "قهوة", "قهوه", "ستاربكس", "costa", "coffee", "cafe", "cappuccino", "لاتيه", "espresso"]
        return keys.contains(where: { note.contains($0) })
    }

    private static func isTakeoutLike(_ expense: Expense) -> Bool {
        let note = expense.note.lowercased()
        let keys = ["طلب", "ديلفري", "delivery", "talabat", "طلبات", "اجنحة", "pizza", "برجر", "burger", "كشري بره"]
        if keys.contains(where: { note.contains($0) }) { return true }
        return false
    }

    static func start(kind: ChallengeKind, roundUpTotal: Double) -> ActiveChallenge {
        ActiveChallenge(
            id: "\(kind.rawValue)-\(Int(Date().timeIntervalSince1970))",
            kindRaw: kind.rawValue,
            startedAt: .now,
            roundUpBaseline: roundUpTotal
        )
    }
}
