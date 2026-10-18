import Foundation

/// Shared on-device category detection for voice, plan parse, and receipt OCR.
/// Prefers the longest keyword hit so "فاتورة نت" beats bare "فاتورة" when both exist.
enum CategoryMatcher {
    static func match(text: String, categories: [CategoryItem]) -> CategoryItem? {
        let haystack = normalize(text)
        guard !haystack.isEmpty else { return nil }

        let pool = categories.isEmpty
            ? BuiltInCategory.allCases.map { $0.makeItem() }
            : categories

        var best: (CategoryItem, Int)?
        for category in pool {
            let keys = category.keywords.isEmpty
                ? [category.nameAr, category.nameEn]
                : category.keywords
            for key in keys {
                let needle = normalize(key)
                guard needle.count >= 2, haystack.contains(needle) else { continue }
                let score = needle.count
                if best == nil || score > best!.1 {
                    best = (category, score)
                }
            }
        }
        return best?.0
    }

    /// Strip diacritics / tatweel and unify common Arabic letter variants for matching.
    static func normalize(_ text: String) -> String {
        var s = text.lowercased()
        let fold: [(String, String)] = [
            ("أ", "ا"), ("إ", "ا"), ("آ", "ا"), ("ة", "ه"), ("ى", "ي"),
            ("ؤ", "و"), ("ئ", "ي"), ("ٱ", "ا"), ("ـ", "")
        ]
        for (from, to) in fold {
            s = s.replacingOccurrences(of: from, with: to)
        }
        s = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "ar"))
        return s
    }
}
