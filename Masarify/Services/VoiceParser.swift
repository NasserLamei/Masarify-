import Foundation

enum VoiceParser {
    private static let arabicDigits: [Character: Character] = [
        "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
        "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
    ]

    static let mockSamples = [
        "صرفت ٢٠٠ جنيه غدا",
        "دفعت 50 جنيه أوبير",
        "دفعت 85 جنيه أوبر",
        "spent 150 on coffee",
        "صرفت 320 جنيه فاتورة نت"
    ]

    static func parse(
        _ transcript: String,
        source: ExpenseSource = .voice,
        categories: [CategoryItem] = []
    ) -> ExpenseDraft {
        let amount = extractAmount(from: transcript)
        let category = CategoryMatcher.match(text: transcript, categories: categories)
        let note = extractNote(from: transcript, amount: amount, category: category)
        return ExpenseDraft(
            amount: amount,
            categoryId: category?.id,
            note: note,
            merchant: nil,
            date: .now,
            source: source
        )
    }

    static func mockParse(
        index: Int = 0,
        categories: [CategoryItem] = []
    ) -> (transcript: String, draft: ExpenseDraft) {
        let transcript = mockSamples[index % mockSamples.count]
        return (transcript, parse(transcript, categories: categories))
    }

    private static func normalizeDigits(_ text: String) -> String {
        String(text.map { arabicDigits[$0] ?? $0 })
    }

    static func extractAmount(from text: String) -> Double? {
        let normalized = normalizeDigits(text)
        let patterns = [
            #"(\d+(?:[.,]\d+)?)\s*(?:جنيه|جنيهات|جنيها|ج\.?م|EGP|egp|EG£|le|LE)"#,
            #"(?:صرفت|دفعت|spent|paid)\s+(\d+(?:[.,]\d+)?)"#,
            #"(\d+(?:[.,]\d+)?)\s*(?:على|في|عند|on|for)"#,
            #"(\d+(?:[.,]\d+)?)"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: normalized) {
                let raw = normalized[range].replacingOccurrences(of: ",", with: ".")
                if let value = Double(raw), value > 0 {
                    return value
                }
            }
        }
        return nil
    }

    private static func extractNote(from text: String, amount: Double?, category: CategoryItem?) -> String {
        var note = normalizeDigits(text)
        let scrubbers = [
            #"(?:صرفت|دفعت|spent|paid)"#,
            #"\d+(?:[.,]\d+)?"#,
            #"(?:جنيه|جنيهات|جنيها|ج\.?م|EGP|egp|EG£|le|LE)"#
        ]
        for pattern in scrubbers {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                note = regex.stringByReplacingMatches(
                    in: note,
                    range: NSRange(note.startIndex..., in: note),
                    withTemplate: " "
                )
            }
        }
        if let category {
            for key in category.keywords + [category.nameAr, category.nameEn] {
                guard !key.isEmpty else { continue }
                note = note.replacingOccurrences(of: key, with: " ", options: [.caseInsensitive, .diacriticInsensitive])
            }
        }
        note = note.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if note.isEmpty, let category {
            note = category.labelAr
        }
        if note.isEmpty, amount != nil {
            note = "مصروف"
        }
        return note
    }
}
