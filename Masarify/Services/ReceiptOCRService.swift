import Foundation
import UIKit
import Vision

struct ReceiptExtractResult: Equatable {
    var draft: ExpenseDraft
    var confidence: Confidence
    var rawHints: [String]
    var recognizedText: String

    enum Confidence: String {
        case vision
        case heuristic
        case mock
        case lowOCR
    }
}

enum ReceiptOCRService {
    static func extract(
        from image: UIImage,
        fileNameHint: String = "",
        categories: [CategoryItem] = []
    ) async -> ReceiptExtractResult {
        let visionText = await recognizeTextBestOrientation(in: image)
        let haystack = "\(fileNameHint) \(visionText)"

        if !visionText.isEmpty {
            let fields = ReceiptFieldParser.parse(visionText)
            let categoryId = resolveCategoryId(
                fields: fields,
                haystack: haystack,
                categories: categories
            )
            let merchant = fields.merchant
            let note: String = {
                if let merchant { return "فاتورة \(merchant)" }
                if let cat = CategoryItem.resolve(id: categoryId, in: categories.isEmpty
                    ? BuiltInCategory.allCases.map { $0.makeItem() }
                    : categories) {
                    return "فاتورة \(cat.labelAr)"
                }
                return "فاتورة من الكاميرا"
            }()

            // Never seed amount from VoiceParser — garbage OCR invents hotline/serial totals.
            let draft = ExpenseDraft(
                amount: fields.amount,
                categoryId: categoryId,
                note: note,
                merchant: merchant,
                date: fields.date ?? .now,
                source: .receipt
            )

            var hints: [String] = []
            if fields.qualityScore < 12 {
                hints.append("القراءة ضعيفة — راجع المبلغ يدوياً (الصورة ممكن محتاجة إضاءة أو زاوية أوضح).")
            } else {
                hints.append("تمت القراءة — راجع قبل الحفظ.")
            }
            if fields.amount == nil {
                hints.append("لم يُلتقط المبلغ الكلي بوضوح — اكتبه في المراجعة.")
            }
            if let merchant {
                hints.append("المكان: \(merchant)")
            }
            let pool = categories.isEmpty ? BuiltInCategory.allCases.map { $0.makeItem() } : categories
            if let cat = CategoryItem.resolve(id: categoryId, in: pool) {
                hints.append("الفئة: \(cat.labelAr)")
            }
            hints.append(contentsOf: fields.hints.map { "parsed:\($0)" })

            let confidence: ReceiptExtractResult.Confidence =
                fields.qualityScore < 12 ? .lowOCR : .vision

            return ReceiptExtractResult(
                draft: draft,
                confidence: confidence,
                rawHints: hints,
                recognizedText: visionText
            )
        }

        let fileHintCat = resolveCategoryId(
            fields: .init(amount: nil, date: nil, merchant: nil, categoryId: nil, hints: [], qualityScore: 0),
            haystack: fileNameHint,
            categories: categories
        )
        if fileHintCat != BuiltInCategory.other.rawValue {
            let pool = categories.isEmpty ? BuiltInCategory.allCases.map { $0.makeItem() } : categories
            let label = CategoryItem.resolve(id: fileHintCat, in: pool)?.labelAr ?? fileHintCat
            return ReceiptExtractResult(
                draft: ExpenseDraft(
                    amount: nil,
                    categoryId: fileHintCat,
                    note: "فاتورة \(label)",
                    merchant: nil,
                    date: .now,
                    source: .receipt
                ),
                confidence: .heuristic,
                rawHints: ["من اسم الملف — أدخل المبلغ يدوياً."],
                recognizedText: ""
            )
        }

        return ReceiptExtractResult(
            draft: ExpenseDraft(
                amount: nil,
                categoryId: BuiltInCategory.other.rawValue,
                note: "فاتورة من الكاميرا",
                merchant: nil,
                date: .now,
                source: .receipt
            ),
            confidence: .mock,
            rawHints: [
                "مفيش نص واضح من الصورة — اكتب المبلغ والفئة في المراجعة.",
                fileNameHint.isEmpty ? "Camera capture" : "File: \(fileNameHint)"
            ],
            recognizedText: ""
        )
    }

    /// Dynamic category: merchant table → CategoryMatcher keywords → bills heuristics → other.
    private static func resolveCategoryId(
        fields: ReceiptFieldParser.ParsedFields,
        haystack: String,
        categories: [CategoryItem]
    ) -> String {
        if let id = fields.categoryId { return id }

        let pool = categories.isEmpty
            ? BuiltInCategory.allCases.map { $0.makeItem() }
            : categories

        if let matched = CategoryMatcher.match(text: haystack, categories: pool),
           matched.id != BuiltInCategory.other.rawValue {
            return matched.id
        }

        let lower = CategoryMatcher.normalize(haystack)
        let billSignals = [
            "كهرباء", "مياه", "غاز", "فاتورة", "شحن كارت", "ممكن", "momken",
            "نت", "انترنت", "إنترنت", "bill", "utility", "recharge"
        ]
        if billSignals.contains(where: { lower.contains(CategoryMatcher.normalize($0)) }) {
            return BuiltInCategory.bills.rawValue
        }

        let foodSignals = ["مطعم", "كشري", "غدا", "طعام", "restaurant", "cafe", "قهوة"]
        if foodSignals.contains(where: { lower.contains(CategoryMatcher.normalize($0)) }) {
            return BuiltInCategory.food.rawValue
        }

        let transportSignals = ["اوبر", "أوبير", "uber", "كريم", "تاكسي", "بنزين"]
        if transportSignals.contains(where: { lower.contains(CategoryMatcher.normalize($0)) }) {
            return BuiltInCategory.transport.rawValue
        }

        return BuiltInCategory.other.rawValue
    }

    // MARK: - Vision (try orientations — thermal receipts often rotated)

    private static func recognizeTextBestOrientation(in image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        let orientations: [CGImagePropertyOrientation] = [.up, .right, .down, .left]
        var bestText = ""
        var bestScore = Int.min

        for orientation in orientations {
            let text = await recognizeOnce(cgImage: cgImage, orientation: orientation)
            let score = ReceiptFieldParser.ocrQualityScore(text)
            if score > bestScore {
                bestScore = score
                bestText = text
            }
            // Good enough — stop early.
            if score >= 50 { break }
        }
        return bestText
    }

    private static func recognizeOnce(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ar-EG", "ar", "en-US"]
            request.usesLanguageCorrection = true
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
}
