import Foundation
import SwiftData

/// Supported trip currencies with approximate EGP rates (user can override).
enum TripCurrency: String, CaseIterable, Identifiable {
    case egp = "EGP"
    case usd = "USD"
    case eur = "EUR"
    case sar = "SAR"
    case aed = "AED"
    case gbp = "GBP"

    var id: String { rawValue }

    var defaultRateToEGP: Double {
        switch self {
        case .egp: return 1
        case .usd: return 48.5
        case .eur: return 52.5
        case .sar: return 12.9
        case .aed: return 13.2
        case .gbp: return 61.0
        }
    }

    func label(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.egp, .arabic): return "جنيه مصري"
        case (.egp, .english): return "Egyptian pound"
        case (.usd, .arabic): return "دولار أمريكي"
        case (.usd, .english): return "US dollar"
        case (.eur, .arabic): return "يورو"
        case (.eur, .english): return "Euro"
        case (.sar, .arabic): return "ريال سعودي"
        case (.sar, .english): return "Saudi riyal"
        case (.aed, .arabic): return "درهم إماراتي"
        case (.aed, .english): return "UAE dirham"
        case (.gbp, .arabic): return "جنيه إسترليني"
        case (.gbp, .english): return "British pound"
        }
    }
}

@Model
final class Trip {
    var id: UUID
    var title: String
    /// Trip budget stored in EGP for consistent math.
    var budgetEGP: Double
    var currencyCode: String
    /// 1 unit of trip currency → EGP
    var exchangeRateToEGP: Double
    var startedAt: Date
    var endedAt: Date?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        title: String,
        budgetEGP: Double,
        currency: TripCurrency = .egp,
        exchangeRateToEGP: Double? = nil,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.budgetEGP = max(0, budgetEGP)
        self.currencyCode = currency.rawValue
        self.exchangeRateToEGP = exchangeRateToEGP ?? currency.defaultRateToEGP
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isActive = isActive
    }

    var currency: TripCurrency {
        get { TripCurrency(rawValue: currencyCode) ?? .egp }
        set {
            currencyCode = newValue.rawValue
            exchangeRateToEGP = newValue.defaultRateToEGP
        }
    }

    func toEGP(_ foreignAmount: Double) -> Double {
        foreignAmount * exchangeRateToEGP
    }

    func fromEGP(_ egpAmount: Double) -> Double {
        guard exchangeRateToEGP > 0 else { return egpAmount }
        return egpAmount / exchangeRateToEGP
    }
}
