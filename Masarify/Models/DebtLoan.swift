import Foundation
import SwiftData

enum DebtLoanKind: String, CaseIterable, Identifiable {
    case lent
    case borrowed

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.lent, .arabic): return "سلّفت"
        case (.lent, .english): return "I lent"
        case (.borrowed, .arabic): return "استلفت"
        case (.borrowed, .english): return "I borrowed"
        }
    }

    func listTitle(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.lent, .arabic): return "ناس مدينة ليّا"
        case (.lent, .english): return "They owe me"
        case (.borrowed, .arabic): return "أنا مدين"
        case (.borrowed, .english): return "I owe them"
        }
    }
}

@Model
final class DebtLoan {
    var id: UUID
    var personName: String
    var amount: Double
    var kindRaw: String
    var dueDate: Date?
    var note: String
    var isSettled: Bool
    var reminderEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        personName: String,
        amount: Double,
        kind: DebtLoanKind,
        dueDate: Date? = nil,
        note: String = "",
        isSettled: Bool = false,
        reminderEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.personName = personName
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.dueDate = dueDate
        self.note = note
        self.isSettled = isSettled
        self.reminderEnabled = reminderEnabled
        self.createdAt = createdAt
    }

    var kind: DebtLoanKind {
        get { DebtLoanKind(rawValue: kindRaw) ?? .lent }
        set { kindRaw = newValue.rawValue }
    }

    var isOverdue: Bool {
        guard !isSettled, let dueDate else { return false }
        return Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: .now)
    }
}
