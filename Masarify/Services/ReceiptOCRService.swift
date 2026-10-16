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
    }
}

enum ReceiptOCRService {
    private static let merchantHints: [(keywords: [String], merchant: String, category: ExpenseCategory, amount: Double)] = [
        (["carrefour", "كارفور"], "كارفور", .shopping, 485),
        (["seoudi", "سعودي"], "سعودي ماركت", .food, 312.5),
        (["uber", "أوبر", "اوبر"], "أوبر", .transport, 95),
        (["pharmacy", "صيدلية", "el ezaby", "العزبي"], "صيدلية العزبي", .health, 180)
    ]

    static func extract(from image: UIImage, fileNameHint: String = "") async -> ReceiptExtractResult {
        let visionText = await recognizeText(in: image)
        let haystack = "\(fileNameHint) \(visionText)".lowercased()

        if let hint = merchantHints.first(where: { entry in
            entry.keywords.contains(where: { haystack.contains($0.lowercased()) })
        }) {
            return ReceiptExtractResult(
                draft: ExpenseDraft(
                    amount: hint.amount,
                    category: hint.category,
                    note: "فاتورة \(hint.merchant)",
                    merchant: hint.merchant,
                    date: .now,
                    source: .receipt
                ),
                confidence: visionText.isEmpty ? .heuristic : .vision,
                rawHints: [
                    visionText.isEmpty
                        ? "Matched filename / metadata hint: \(hint.merchant)"
                        : "Matched OCR / hint: \(hint.merchant)"
                ],
                recognizedText: visionText
            )
        }

        if !visionText.isEmpty {
            var draft = VoiceParser.parse(visionText, source: .receipt)
            if draft.amount == nil {
                draft.amount = firstAmount(in: visionText) ?? 245
            }
            if draft.category == nil {
                draft.category = .food
            }
            if draft.note.isEmpty {
                draft.note = "فاتورة من الكاميرا"
            }
            draft.source = .receipt
            return ReceiptExtractResult(
                draft: draft,
                confidence: .vision,
                rawHints: ["Vision OCR extracted text — review before saving."],
                recognizedText: visionText
            )
        }

        return ReceiptExtractResult(
            draft: ExpenseDraft(
                amount: 245,
                category: .food,
                note: "فاتورة مطعم (تجريبي)",
                merchant: "مطعم النيل",
                date: .now,
                source: .receipt
            ),
            confidence: .mock,
            rawHints: [
                "No OCR text found — using demo extract so you can review & save.",
                fileNameHint.isEmpty ? "Camera capture" : "File: \(fileNameHint)"
            ],
            recognizedText: ""
        )
    }

    private static func recognizeText(in image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ar", "en"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    private static func firstAmount(in text: String) -> Double? {
        VoiceParser.parse(text, source: .receipt).amount
    }
}
