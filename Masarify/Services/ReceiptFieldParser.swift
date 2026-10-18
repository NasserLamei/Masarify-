import Foundation

/// Parse amount / date / merchant from Vision OCR text (Arabic + English receipts).
enum ReceiptFieldParser {
    private static let arabicDigits: [Character: Character] = [
        "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
        "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
    ]

    private static let knownMerchants: [(keywords: [String], name: String, categoryId: String)] = [
        (["momken", "ممكن", "الأهلي ممكن", "الاهلي ممكن", "اهلي ممكن", "ekhales", "eKhales"], "الأهلي ممكن", BuiltInCategory.bills.rawValue),
        (["كهرباء", "شحن كارت", "كارت الكهرباء", "جنوب القاهرة", "شمال القاهرة"], "شحن كهرباء", BuiltInCategory.bills.rawValue),
        (["carrefour", "كارفور"], "كارفور", BuiltInCategory.shopping.rawValue),
        (["seoudi", "سعودي"], "سعودي ماركت", BuiltInCategory.shopping.rawValue),
        (["spinneys", "سبينيس"], "سبينيس", BuiltInCategory.shopping.rawValue),
        (["metro market", "مترو ماركت"], "مترو ماركت", BuiltInCategory.shopping.rawValue),
        (["hyperone", "هايبر وان"], "هايبر وان", BuiltInCategory.shopping.rawValue),
        (["uber", "أوبر", "اوبر", "أوبير", "اوبير"], "أوبر", BuiltInCategory.transport.rawValue),
        (["careem", "كريم"], "كريم", BuiltInCategory.transport.rawValue),
        (["pharmacy", "صيدلية", "el ezaby", "العزبي"], "صيدلية", BuiltInCategory.health.rawValue),
        (["koshary", "كشري"], "كشري", BuiltInCategory.food.rawValue),
        (["mcdonald", "ماكدونالدز", "ماكدونالد"], "ماكدونالدز", BuiltInCategory.food.rawValue)
    ]

    /// Currency tokens used on Egyptian receipts (incl. common typo جنية).
    private static let currencyToken = #"(?:جنيه|جنيها|جنيهات|جنية|جنيهًا|ج\.?م\.?|EGP|egp|EG£|LE|le)"#

    /// Standalone number — not glued inside serials like `860SKERDOV16099znZ`.
    private static let standaloneNumber = #"(?<![A-Za-z0-9])(\d+(?:[.,]\d+)?)(?![A-Za-z0-9])"#

    struct ParsedFields: Equatable {
        var amount: Double?
        var date: Date?
        var merchant: String?
        var categoryId: String?
        var hints: [String]
        var qualityScore: Int
    }

    static func parse(_ rawText: String) -> ParsedFields {
        let normalized = normalizeDigits(rawText)
            .replacingOccurrences(of: "\u{00A0}", with: " ")
        let cleaned = scrubSerialNoise(normalized)
        let quality = ocrQualityScore(normalized)

        let lines = cleaned
            .components(separatedBy: CharacterSet.newlines)
            .flatMap { $0.components(separatedBy: CharacterSet(charactersIn: "|")) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Garbage OCR → don't invent an amount from random digit scraps.
        let amount: Double?
        if quality < 12 {
            amount = currencyOnlyTotal(in: cleaned, lines: lines)
        } else {
            amount = extractTotal(from: cleaned, lines: lines)
        }

        let date = extractDate(from: cleaned) ?? extractDate(from: lines.joined(separator: " "))
        let merchantHit = matchMerchant(in: normalized) // use raw too — names may sit in noisy lines
        let merchant = merchantHit?.name ?? extractMerchantFallback(from: cleaned, lines: lines)

        var hints: [String] = []
        if amount != nil { hints.append("total") }
        if date != nil { hints.append("date") }
        if merchant != nil { hints.append("merchant") }
        if quality < 12 { hints.append("lowOCR") }

        return ParsedFields(
            amount: amount,
            date: date,
            merchant: merchant,
            categoryId: merchantHit?.categoryId,
            hints: hints,
            qualityScore: quality
        )
    }

    // MARK: - Noise scrub

    /// Drop mixed letter+digit tokens (barcodes / OCR garbage) so `16099` inside
    /// `860SKERDOV16099znZ` never becomes the expense amount.
    static func scrubSerialNoise(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"[A-Za-z]{1,}\d+[A-Za-z0-9]*|\d+[A-Za-z]{2,}[A-Za-z0-9]*"#
        ) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: " ")
    }

    /// Higher = more usable Arabic receipt text.
    static func ocrQualityScore(_ text: String) -> Int {
        var score = 0
        let lower = CategoryMatcher.normalize(text)
        let signals = ["جنيه", "جنية", "المبلغ", "كهرباء", "فاتورة", "اجمالي", "إجمالي", "ممكن", "total", "egp", "كارت"]
        for s in signals where lower.contains(CategoryMatcher.normalize(s)) {
            score += 20
        }
        let arabic = text.unicodeScalars.filter { (0x0600...0x06FF).contains($0.value) }.count
        score += min(arabic / 2, 60)
        let latinLetters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) && $0.value < 0x0600 }.count
        if latinLetters > arabic * 3 && arabic < 20 {
            score -= 30
        }
        return score
    }

    // MARK: - Amount

    private static func currencyOnlyTotal(in text: String, lines: [String]) -> Double? {
        let currencyPattern = standaloneNumber + #"\s*"# + currencyToken
        let hits = allDoubles(in: text, pattern: currencyPattern).filter(isPlausibleExpenseAmount)
        if let max = hits.max() { return max }
        for line in lines.reversed() {
            if let v = currencyAmount(in: line) { return v }
        }
        return nil
    }

    private static func extractTotal(from text: String, lines: [String]) -> Double? {
        let totalLabels = [
            "المبلغ الكلي", "المبلغ الاجمالي", "المبلغ الإجمالي", "اجمالي المبلغ", "إجمالي المبلغ",
            "الإجمالي", "اجمالي", "المجموع الكلي", "المجموع", "الصافي",
            "Grand Total", "TOTAL", "Total", "Amount"
        ]

        for (index, line) in lines.enumerated().reversed() {
            let normalizedLine = CategoryMatcher.normalize(line)
            let isTotalLine = totalLabels.contains { normalizedLine.contains(CategoryMatcher.normalize($0)) }
            guard isTotalLine else { continue }

            if let value = currencyAmount(in: line) ?? firstPlausibleStandalone(in: line) {
                return value
            }
            for neighbor in neighborLines(around: index, in: lines) {
                if let value = currencyAmount(in: neighbor) ?? firstPlausibleStandalone(in: neighbor) {
                    return value
                }
            }
        }

        let labeledPatterns = [
            #"(?:المبلغ\s*الكلي|المبلغ\s*الإجمالي|المبلغ\s*الاجمالي|الإجمالي|اجمالي|المجموع|TOTAL|Total|Grand\s*Total)\s*[:：\-]?\s*"# + standaloneNumber,
            standaloneNumber + #"\s*"# + currencyToken + #"\s*(?:المبلغ\s*الكلي|الإجمالي|اجمالي|TOTAL)"#
        ]
        for pattern in labeledPatterns {
            let hits = allDoubles(in: text, pattern: pattern).filter(isPlausibleExpenseAmount)
            if let best = hits.max() { return best }
        }

        let currencyPattern = standaloneNumber + #"\s*"# + currencyToken
        let currencyAmounts = allDoubles(in: text, pattern: currencyPattern)
            .filter(isPlausibleExpenseAmount)
        if let max = currencyAmounts.max() {
            return max
        }

        // Last resort only when OCR looks like a real receipt — still standalone + not IDs.
        let bare = allDoubles(in: text, pattern: standaloneNumber)
            .filter(isPlausibleExpenseAmount)
            .filter { !looksLikeHotlineOrID($0) }
        return bare.max()
    }

    private static func neighborLines(around index: Int, in lines: [String]) -> [String] {
        var result: [String] = []
        if index > 0 { result.append(lines[index - 1]) }
        if index + 1 < lines.count { result.append(lines[index + 1]) }
        if index > 1 { result.append(lines[index - 2]) }
        if index + 2 < lines.count { result.append(lines[index + 2]) }
        return result
    }

    private static func currencyAmount(in line: String) -> Double? {
        let pattern = standaloneNumber + #"\s*"# + currencyToken
        return allDoubles(in: line, pattern: pattern)
            .filter(isPlausibleExpenseAmount)
            .max()
    }

    private static func firstPlausibleStandalone(in line: String) -> Double? {
        allDoubles(in: line, pattern: standaloneNumber)
            .filter(isPlausibleExpenseAmount)
            .filter { !looksLikeHotlineOrID($0) }
            .max()
    }

    private static func isPlausibleExpenseAmount(_ value: Double) -> Bool {
        value >= 1 && value <= 50_000
    }

    private static func looksLikeHotlineOrID(_ value: Double) -> Bool {
        let isWhole = abs(value - value.rounded()) < 0.0001
        guard isWhole else { return false }
        let n = Int(value.rounded())
        let digits = String(n).count
        if (1900...2100).contains(n) { return true }
        if (16000...16999).contains(n) { return true }
        if digits >= 5 && digits <= 6 && n >= 10000 { return true }
        if digits >= 7 { return true }
        return false
    }

    // MARK: - Date

    private static func extractDate(from text: String) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        if let match = detector?.firstMatch(in: text, options: [], range: range),
           let date = match.date {
            return date
        }

        let patterns = [
            #"(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})"#,
            #"(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})"#
        ]
        let calendar = Calendar.current
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: range),
                  match.numberOfRanges >= 4,
                  let r1 = Range(match.range(at: 1), in: text),
                  let r2 = Range(match.range(at: 2), in: text),
                  let r3 = Range(match.range(at: 3), in: text),
                  let a = Int(text[r1]), let b = Int(text[r2]), let c = Int(text[r3])
            else { continue }

            var year: Int
            var month: Int
            var day: Int
            if pattern.hasPrefix(#"(\d{4}"#) {
                year = a; month = b; day = c
            } else {
                day = a; month = b
                year = c < 100 ? 2000 + c : c
            }
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            if let date = calendar.date(from: comps),
               date <= Date().addingTimeInterval(86_400),
               date > Date().addingTimeInterval(-365 * 86_400 * 3) {
                return date
            }
        }
        return nil
    }

    // MARK: - Merchant / category

    private static func matchMerchant(in text: String) -> (name: String, categoryId: String)? {
        let lower = CategoryMatcher.normalize(text)
        for entry in knownMerchants {
            if entry.keywords.contains(where: { lower.contains(CategoryMatcher.normalize($0)) }) {
                return (entry.name, entry.categoryId)
            }
        }
        return nil
    }

    private static func extractMerchantFallback(from text: String, lines: [String]) -> String? {
        if let hit = matchMerchant(in: text) { return hit.name }

        let skip = ["total", "amount", "فاتورة", "ايصال", "إيصال", "ضريبة", "tax", "vat", "tel", "phone", "خدمة"]
        for line in lines.prefix(8) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 3, trimmed.count <= 40 else { continue }
            let n = CategoryMatcher.normalize(trimmed)
            if skip.contains(where: { n.contains($0) }) { continue }
            if trimmed.rangeOfCharacter(from: .decimalDigits) != nil, trimmed.count < 8 { continue }
            let digitCount = trimmed.filter(\.isNumber).count
            if digitCount <= 2 {
                return trimmed
            }
        }
        return nil
    }

    // MARK: - Helpers

    private static func normalizeDigits(_ text: String) -> String {
        String(text.map { arabicDigits[$0] ?? $0 })
    }

    private static func allDoubles(in text: String, pattern: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match -> Double? in
            // Find the first capture group that looks like a number.
            for i in 1..<match.numberOfRanges {
                guard let r = Range(match.range(at: i), in: text) else { continue }
                let raw = text[r].replacingOccurrences(of: ",", with: ".")
                if let value = Double(raw) { return value }
            }
            return nil
        }
    }
}
