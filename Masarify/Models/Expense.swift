import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    /// Always stored in EGP (converted if trip currency ≠ EGP).
    var amount: Double
    /// Matches `CategoryItem.id` (built-in slug or custom UUID).
    var categoryRaw: String
    var note: String
    var merchant: String?
    var date: Date
    var createdAt: Date
    var sourceRaw: String
    /// When set, expense belongs to a trip and is excluded from monthly budgets.
    var tripIdRaw: String?
    /// Original currency code for trip spends (default EGP).
    var currencyCode: String
    /// Amount in original currency before conversion.
    var originalAmount: Double
    /// Rate used: 1 original → EGP.
    var exchangeRateToEGP: Double

    init(
        id: UUID = UUID(),
        amount: Double,
        categoryId: String,
        note: String,
        merchant: String? = nil,
        date: Date = .now,
        createdAt: Date = .now,
        source: ExpenseSource = .manual,
        tripId: UUID? = nil,
        currencyCode: String = "EGP",
        originalAmount: Double? = nil,
        exchangeRateToEGP: Double = 1
    ) {
        self.id = id
        self.amount = amount
        self.categoryRaw = categoryId
        self.note = note
        self.merchant = merchant
        self.date = date
        self.createdAt = createdAt
        self.sourceRaw = source.rawValue
        self.tripIdRaw = tripId?.uuidString
        self.currencyCode = currencyCode
        self.originalAmount = originalAmount ?? amount
        self.exchangeRateToEGP = exchangeRateToEGP
    }

    var categoryId: String {
        get { categoryRaw }
        set { categoryRaw = newValue }
    }

    var source: ExpenseSource {
        get { ExpenseSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    var isTripExpense: Bool { tripIdRaw != nil }

    var tripUUID: UUID? {
        guard let tripIdRaw else { return nil }
        return UUID(uuidString: tripIdRaw)
    }
}

struct ExpenseDraft: Equatable {
    var amount: Double?
    var categoryId: String?
    var note: String
    var merchant: String?
    var date: Date
    var source: ExpenseSource

    static func empty(source: ExpenseSource) -> ExpenseDraft {
        ExpenseDraft(
            amount: nil,
            categoryId: nil,
            note: "",
            merchant: nil,
            date: .now,
            source: source
        )
    }
}
