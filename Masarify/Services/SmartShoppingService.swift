import Foundation

/// Learns merchant/price patterns from receipts and suggests cheaper alternatives.
enum SmartShoppingService {
    struct Observation: Codable, Equatable, Identifiable {
        var id: String { "\(categoryId)|\(merchantKey)" }
        var categoryId: String
        var merchant: String
        var merchantKey: String
        var amount: Double
        var date: Date
    }

    struct Tip: Identifiable, Equatable {
        var id: String
        var title: String
        var message: String
        var systemImage: String
    }

    private static let storeKey = "masarify.smartShopping.observations"
    private static let maxStored = 80

    static func record(
        merchant: String?,
        amount: Double?,
        categoryId: String?,
        note: String
    ) {
        guard let amount, amount > 0 else { return }
        let merchantName = (merchant ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard merchantName.count >= 2 else { return }
        let category = categoryId ?? BuiltInCategory.shopping.rawValue
        guard isShopLike(categoryId: category, note: note, merchant: merchantName) else { return }

        var all = load()
        let obs = Observation(
            categoryId: category,
            merchant: merchantName,
            merchantKey: normalize(merchantName),
            amount: amount,
            date: .now
        )
        all.removeAll { $0.merchantKey == obs.merchantKey && $0.categoryId == obs.categoryId }
        all.insert(obs, at: 0)
        if all.count > maxStored { all = Array(all.prefix(maxStored)) }
        save(all)
    }

    static func tip(
        forMerchant merchant: String?,
        amount: Double?,
        categoryId: String?,
        language: AppLanguage
    ) -> Tip? {
        guard let amount, amount > 0 else { return nil }
        let merchantName = (merchant ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard merchantName.count >= 2 else { return nil }
        let category = categoryId ?? BuiltInCategory.shopping.rawValue
        let key = normalize(merchantName)
        let peers = load().filter { $0.categoryId == category && $0.merchantKey != key }
        guard let cheaper = peers.min(by: { $0.amount < $1.amount }),
              cheaper.amount < amount * 0.92,
              amount - cheaper.amount >= 15 else {
            // Soft tip: suggest tracking
            if language == .arabic {
                return Tip(
                    id: "learn-\(key)",
                    title: "هنفتكر السعر ده",
                    message: "المرة الجاية لو لقيت نفس النوع أرخص في مكان تاني، هننبّهك.",
                    systemImage: "cart.fill"
                )
            }
            return Tip(
                id: "learn-\(key)",
                title: "We’ll remember this price",
                message: "Next time, if the same kind of shop is cheaper elsewhere, we’ll tip you.",
                systemImage: "cart.fill"
            )
        }

        let save = amount - cheaper.amount
        if language == .arabic {
            return Tip(
                id: "compare-\(key)-\(cheaper.merchantKey)",
                title: "نصيحة تسوّق ذكية",
                message: "المبلغ ده من «\(merchantName)» أعلى من زيّه في «\(cheaper.merchant)» (\(CurrencyFormat.egp(cheaper.amount, language: .arabic))). الفرق تقريبًا \(CurrencyFormat.egp(save, language: .arabic)) — فكّر في البديل الأوفر المرة الجاية.",
                systemImage: "tag.fill"
            )
        }
        return Tip(
            id: "compare-\(key)-\(cheaper.merchantKey)",
            title: "Smart shopping tip",
            message: "This \(CurrencyFormat.egp(amount, language: .english)) at “\(merchantName)” looks higher than “\(cheaper.merchant)” (\(CurrencyFormat.egp(cheaper.amount, language: .english))). You could save about \(CurrencyFormat.egp(save, language: .english)) next time.",
            systemImage: "tag.fill"
        )
    }

    static func recentTips(language: AppLanguage, limit: Int = 5) -> [Tip] {
        let byCategory = Dictionary(grouping: load(), by: \.categoryId)
        var tips: [Tip] = []
        for (_, group) in byCategory {
            let sorted = group.sorted { $0.amount < $1.amount }
            guard let cheap = sorted.first, let pricey = sorted.last, cheap.merchantKey != pricey.merchantKey else { continue }
            guard pricey.amount > cheap.amount * 1.08 else { continue }
            let save = pricey.amount - cheap.amount
            if language == .arabic {
                tips.append(
                    Tip(
                        id: "hist-\(cheap.merchantKey)-\(pricey.merchantKey)",
                        title: "بدائل أوفر اتعلمتها",
                        message: "«\(cheap.merchant)» أرخص من «\(pricey.merchant)» بحوالي \(CurrencyFormat.egp(save, language: .arabic)) لنفس نوع المصروف.",
                        systemImage: "arrow.left.arrow.right"
                    )
                )
            } else {
                tips.append(
                    Tip(
                        id: "hist-\(cheap.merchantKey)-\(pricey.merchantKey)",
                        title: "Cheaper alternative learned",
                        message: "“\(cheap.merchant)” tends to beat “\(pricey.merchant)” by about \(CurrencyFormat.egp(save, language: .english)) for similar spends.",
                        systemImage: "arrow.left.arrow.right"
                    )
                )
            }
        }
        return Array(tips.prefix(limit))
    }

    private static func isShopLike(categoryId: String, note: String, merchant: String) -> Bool {
        switch categoryId {
        case BuiltInCategory.shopping.rawValue,
             BuiltInCategory.food.rawValue,
             BuiltInCategory.health.rawValue:
            return true
        default:
            let blob = "\(note) \(merchant)".lowercased()
            return ["سوبر", "ماركت", "صيدل", "pharmacy", "carrefour", "spinneys", "bim", "كازيون"].contains(where: { blob.contains($0) })
        }
    }

    private static func normalize(_ merchant: String) -> String {
        merchant.lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func load() -> [Observation] {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([Observation].self, from: data) else { return [] }
        return decoded
    }

    private static func save(_ value: [Observation]) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: storeKey)
    }
}
