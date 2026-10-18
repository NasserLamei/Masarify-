import Foundation
import SwiftData

@Model
final class SavingsGoal {
    var id: UUID
    var title: String
    var targetAmount: Double
    var savedAmount: Double
    var emojiSymbol: String
    var createdAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        title: String,
        targetAmount: Double,
        savedAmount: Double = 0,
        emojiSymbol: String = "laptopcomputer",
        createdAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.targetAmount = max(1, targetAmount)
        self.savedAmount = max(0, savedAmount)
        self.emojiSymbol = emojiSymbol
        self.createdAt = createdAt
        self.isArchived = isArchived
    }

    var progress: Double {
        min(1, savedAmount / targetAmount)
    }

    var remaining: Double {
        max(0, targetAmount - savedAmount)
    }

    func percentToward(amount: Double) -> Double {
        guard targetAmount > 0 else { return 0 }
        return (amount / targetAmount) * 100
    }
}
