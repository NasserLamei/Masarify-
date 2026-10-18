import Foundation

struct VoicePlanAllocation: Equatable, Identifiable {
    var id: String { "\(categoryId ?? "x")-\(amount)-\(note)" }
    var amount: Double
    var categoryId: String?
    var note: String
    var isSavings: Bool
}

struct VoicePlanResult: Equatable {
    var income: Double?
    var allocations: [VoicePlanAllocation]
    var rawTranscript: String

    var allocatedTotal: Double {
        allocations.filter { !$0.isSavings }.reduce(0) { $0 + $1.amount }
    }

    var savingsAmount: Double {
        if let marked = allocations.first(where: \.isSavings)?.amount {
            return marked
        }
        guard let income else { return 0 }
        return max(0, income - allocatedTotal)
    }
}

enum VoicePlanParser {
    private static let arabicDigits: [Character: Character] = [
        "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
        "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
    ]

    static let mockTranscript =
        "أنا قبضت النهاردة ١٠ آلاف، هدفع ٣٠٠٠ إيجار، و٢٠٠٠ أكل، والباقي حوشه."

    static func parse(_ transcript: String, categories: [CategoryItem] = []) -> VoicePlanResult {
        let text = normalize(transcript)
        let income = extractIncome(from: text)
        var allocations = extractAllocations(from: text, categories: categories)

        let lower = text.lowercased()
        let wantsSavings = lower.contains("حوش") || lower.contains("وفّر") || lower.contains("وفر")
            || lower.contains("الباقي") || lower.contains("save") || lower.contains("saving")

        if wantsSavings {
            let spent = allocations.reduce(0) { $0 + $1.amount }
            if let income, income > spent {
                allocations.append(
                    VoicePlanAllocation(
                        amount: income - spent,
                        categoryId: nil,
                        note: "Savings",
                        isSavings: true
                    )
                )
            } else if !allocations.contains(where: \.isSavings) {
                allocations.append(
                    VoicePlanAllocation(amount: 0, categoryId: nil, note: "Savings", isSavings: true)
                )
            }
        }

        return VoicePlanResult(income: income, allocations: allocations, rawTranscript: transcript)
    }

    static func mock(categories: [CategoryItem] = []) -> VoicePlanResult {
        parse(mockTranscript, categories: categories)
    }

    private static func normalize(_ text: String) -> String {
        var t = String(text.map { arabicDigits[$0] ?? $0 })
        t = t.replacingOccurrences(of: "آلاف", with: "000")
        t = t.replacingOccurrences(of: "الف", with: "000")
        t = t.replacingOccurrences(of: "ألف", with: "000")
        t = t.replacingOccurrences(of: " آلاف", with: "000")
        // "10 آلاف" → already digit + 000 appended awkwardly; fix "10000" patterns:
        t = t.replacingOccurrences(of: #"(\d+)\s*000"#, with: "$1000", options: .regularExpression)
        // If user said "10 آلاف" became "10 000" then "10000" via $1000 on "10 000" → "10000" good if space removed
        t = t.replacingOccurrences(of: #"(\d+)\s+000"#, with: "$1000", options: .regularExpression)
        return t
    }

    private static func extractIncome(from text: String) -> Double? {
        let patterns = [
            #"(?:قبضت|استلمت|دخلي|مرتب|دخل|got|received|salary|income)\D{0,12}(\d+(?:[.,]\d+)?)"#,
            #"(\d+(?:[.,]\d+)?)\D{0,8}(?:جنيه|جنيهات|EGP).{0,12}(?:قبض|مرتب|دخل)"#
        ]
        for pattern in patterns {
            if let value = firstAmount(in: text, pattern: pattern) { return value }
        }
        return nil
    }

    private static func extractAllocations(from text: String, categories: [CategoryItem]) -> [VoicePlanAllocation] {
        var results: [VoicePlanAllocation] = []
        let pattern = #"(\d+(?:[.,]\d+)?)\s*(?:جنيه|جنيهات|ج\.?م|EGP|egp)?\s*([^\d،,]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return results
        }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        for match in matches {
            guard match.numberOfRanges >= 3,
                  let amountRange = Range(match.range(at: 1), in: text),
                  let noteRange = Range(match.range(at: 2), in: text),
                  let amount = Double(text[amountRange].replacingOccurrences(of: ",", with: ".")) else {
                continue
            }
            // Skip income mention amounts already captured near قبضت
            let prefix = String(text[..<amountRange.lowerBound]).suffix(24).lowercased()
            if prefix.contains("قبض") || prefix.contains("استلم") || prefix.contains("salary") || prefix.contains("income") {
                continue
            }
            var note = text[noteRange]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            note = note.replacingOccurrences(of: #"^(?:و|هدفع|ادفع|لـ|ل|for|on)\s*"#, with: "", options: .regularExpression)
            note = note.trimmingCharacters(in: CharacterSet(charactersIn: "،,."))
            if note.isEmpty || note.count > 40 { continue }
            if note.contains("حوش") || note.lowercased().contains("save") { continue }

            let category = detectCategory(in: note, categories: categories)
                ?? detectCategory(in: String(prefix) + note, categories: categories)
            results.append(
                VoicePlanAllocation(
                    amount: amount,
                    categoryId: category?.id ?? mapNoteToCategory(note),
                    note: note,
                    isSavings: false
                )
            )
        }
        return results
    }

    private static func mapNoteToCategory(_ note: String) -> String {
        let lower = note.lowercased()
        if lower.contains("إيجار") || lower.contains("ايجار") || lower.contains("rent") {
            return BuiltInCategory.bills.rawValue
        }
        if lower.contains("أكل") || lower.contains("اكل") || lower.contains("food") {
            return BuiltInCategory.food.rawValue
        }
        return BuiltInCategory.other.rawValue
    }

    private static func detectCategory(in text: String, categories: [CategoryItem]) -> CategoryItem? {
        CategoryMatcher.match(text: text, categories: categories)
    }

    private static func firstAmount(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return Double(text[range].replacingOccurrences(of: ",", with: "."))
    }
}
