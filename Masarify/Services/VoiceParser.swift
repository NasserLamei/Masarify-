import Foundation

enum VoiceParser {
    private static let arabicDigits: [Character: Character] = [
        "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
        "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
    ]

    private static let categoryKeywords: [ExpenseCategory: [String]] = [
        .food: ["أكل", "اكل", "غدا", "غداء", "فطار", "فطور", "عشا", "عشاء", "قهوة", "كافية", "مطعم", "food", "lunch", "dinner", "coffee", "restaurant"],
        .transport: ["مواصلات", "تاكسي", "أوبر", "اوبر", "بنزين", "مترو", "ميكروباص", "uber", "taxi", "transport", "fuel"],
        .bills: ["فاتورة", "فواتير", "كهربا", "كهرباء", "مياه", "نت", "إنترنت", "انترنت", "bill", "electricity", "internet"],
        .entertainment: ["ترفيه", "سينما", "فيلم", "لعبة", "نتفلكس", "cinema", "movie", "fun", "entertainment"],
        .shopping: ["تسوق", "شراء", "ملابس", "سوق", "مول", "shopping", "clothes", "mall"],
        .health: ["صحة", "دكتور", "صيدلية", "دواء", "مستشفى", "pharmacy", "doctor", "medicine", "health"],
        .other: ["أخرى", "اخرى", "other", "misc"]
    ]

    static let mockSamples = [
        "صرفت ٢٠٠ جنيه غدا",
        "دفعت 85 جنيه أوبر",
        "spent 150 on coffee",
        "صرفت 320 جنيه فاتورة نت"
    ]

    static func parse(_ transcript: String, source: ExpenseSource = .voice) -> ExpenseDraft {
        let amount = extractAmount(from: transcript)
        let category = detectCategory(in: transcript)
        let note = extractNote(from: transcript, amount: amount, category: category)
        return ExpenseDraft(
            amount: amount,
            category: category,
            note: note,
            merchant: nil,
            date: .now,
            source: source
        )
    }

    static func mockParse(index: Int = 0) -> (transcript: String, draft: ExpenseDraft) {
        let transcript = mockSamples[index % mockSamples.count]
        return (transcript, parse(transcript))
    }

    private static func normalizeDigits(_ text: String) -> String {
        String(text.map { arabicDigits[$0] ?? $0 })
    }

    private static func detectCategory(in text: String) -> ExpenseCategory? {
        let lower = text.lowercased()
        for category in ExpenseCategory.allCases {
            if let keys = categoryKeywords[category],
               keys.contains(where: { lower.contains($0.lowercased()) }) {
                return category
            }
        }
        return nil
    }

    private static func extractAmount(from text: String) -> Double? {
        let normalized = normalizeDigits(text)
        let patterns = [
            #"(\d+(?:[.,]\d+)?)\s*(?:جنيه|جنيهات|ج\.?م|EGP|egp|le|LE)"#,
            #"(?:صرفت|دفعت|spent|paid)\s+(\d+(?:[.,]\d+)?)"#,
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

    private static func extractNote(from text: String, amount: Double?, category: ExpenseCategory?) -> String {
        var note = normalizeDigits(text)
        let scrubbers = [
            #"(?:صرفت|دفعت|spent|paid)"#,
            #"\d+(?:[.,]\d+)?"#,
            #"(?:جنيه|جنيهات|ج\.?م|EGP|egp|le|LE)"#
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
        if let category, let keys = categoryKeywords[category] {
            for key in keys {
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
