import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var amount: Double
    var categoryRaw: String
    var note: String
    var merchant: String?
    var date: Date
    var createdAt: Date
    var sourceRaw: String

    init(
        id: UUID = UUID(),
        amount: Double,
        category: ExpenseCategory,
        note: String,
        merchant: String? = nil,
        date: Date = .now,
        createdAt: Date = .now,
        source: ExpenseSource = .manual
    ) {
        self.id = id
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.note = note
        self.merchant = merchant
        self.date = date
        self.createdAt = createdAt
        self.sourceRaw = source.rawValue
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var source: ExpenseSource {
        get { ExpenseSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}

struct ExpenseDraft: Equatable {
    var amount: Double?
    var category: ExpenseCategory?
    var note: String
    var merchant: String?
    var date: Date
    var source: ExpenseSource

    static func empty(source: ExpenseSource) -> ExpenseDraft {
        ExpenseDraft(
            amount: nil,
            category: nil,
            note: "",
            merchant: nil,
            date: .now,
            source: source
        )
    }
}
