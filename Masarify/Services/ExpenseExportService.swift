import Foundation
import UIKit

enum ExpenseExportFormat: String, CaseIterable, Identifiable {
    case csv
    case pdf

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .pdf: return "pdf"
        }
    }

    var uti: String {
        switch self {
        case .csv: return "public.comma-separated-values-text"
        case .pdf: return "com.adobe.pdf"
        }
    }
}

enum ExpenseExportService {
    static func makeFile(
        expenses: [Expense],
        categories: [CategoryItem],
        language: AppLanguage,
        format: ExpenseExportFormat
    ) throws -> URL {
        switch format {
        case .csv: return try writeCSV(expenses: expenses, categories: categories, language: language)
        case .pdf: return try writePDF(expenses: expenses, categories: categories, language: language)
        }
    }

    // MARK: - CSV

    private static func writeCSV(
        expenses: [Expense],
        categories: [CategoryItem],
        language: AppLanguage
    ) throws -> URL {
        let header = language == .arabic
            ? "التاريخ,المبلغ,الفئة,الملاحظة,المكان,المصدر"
            : "Date,Amount,Category,Note,Merchant,Source"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        var lines = [header]
        for expense in expenses.sorted(by: { $0.date > $1.date }) {
            let cat = CategoryItem.resolve(id: expense.categoryId, in: categories)
            let catLabel: String = {
                guard let cat else { return expense.categoryId }
                return language == .arabic ? cat.nameAr : (cat.nameEn.isEmpty ? cat.nameAr : cat.nameEn)
            }()
            let cols = [
                formatter.string(from: expense.date),
                String(format: "%.2f", expense.amount),
                csvEscape(catLabel),
                csvEscape(expense.note),
                csvEscape(expense.merchant ?? ""),
                csvEscape(expense.source.rawValue)
            ]
            lines.append(cols.joined(separator: ","))
        }

        // UTF-8 BOM helps Excel open Arabic correctly.
        let body = "\u{FEFF}" + lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("masarify-expenses-\(stamp()).csv")
        try body.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    // MARK: - PDF

    private static func writePDF(
        expenses: [Expense],
        categories: [CategoryItem],
        language: AppLanguage
    ) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let sorted = expenses.sorted(by: { $0.date > $1.date })
        let total = sorted.reduce(0) { $0 + $1.amount }

        let title = language == .arabic ? "تقرير مصاريفي" : "Masarify Expenses"
        let totalLabel = language == .arabic ? "الإجمالي" : "Total"
        let dateFmt = DateFormatter()
        dateFmt.locale = language.locale
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .short

        let data = renderer.pdfData { context in
            var y: CGFloat = 0
            let margin: CGFloat = 36
            let contentWidth = pageRect.width - margin * 2

            func newPage() {
                context.beginPage()
                y = margin
            }

            func ensureSpace(_ needed: CGFloat) {
                if y + needed > pageRect.height - margin {
                    newPage()
                }
            }

            newPage()

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor(red: 0.04, green: 0.36, blue: 0.35, alpha: 1)
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkText
            ]
            let metaAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]

            (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            y += 32
            let summary = "\(totalLabel): \(CurrencyFormat.egp(total, language: language))  ·  \(sorted.count)"
            (summary as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
            y += 28

            for expense in sorted {
                ensureSpace(48)
                let cat = CategoryItem.resolve(id: expense.categoryId, in: categories)
                let catLabel = cat.map {
                    language == .arabic ? $0.nameAr : ($0.nameEn.isEmpty ? $0.nameAr : $0.nameEn)
                } ?? expense.categoryId

                let line1 = "\(CurrencyFormat.egp(expense.amount, language: language))  ·  \(catLabel)"
                let line2 = "\(dateFmt.string(from: expense.date))  ·  \(expense.note)"
                (line1 as NSString).draw(
                    in: CGRect(x: margin, y: y, width: contentWidth, height: 16),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                        .foregroundColor: UIColor.darkText
                    ]
                )
                y += 16
                (line2 as NSString).draw(
                    in: CGRect(x: margin, y: y, width: contentWidth, height: 28),
                    withAttributes: bodyAttrs
                )
                y += 30
                // Divider
                context.cgContext.setStrokeColor(UIColor.systemGray4.cgColor)
                context.cgContext.setLineWidth(0.5)
                context.cgContext.move(to: CGPoint(x: margin, y: y))
                context.cgContext.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                context.cgContext.strokePath()
                y += 10
            }
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("masarify-expenses-\(stamp()).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: .now)
    }
}
