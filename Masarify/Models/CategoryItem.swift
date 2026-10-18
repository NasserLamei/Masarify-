import Foundation
import SwiftData
import SwiftUI
import UIKit

/// User-managed expense category (built-in defaults + custom).
@Model
final class CategoryItem {
    var id: String
    var nameAr: String
    var nameEn: String
    var systemImage: String
    /// Optional gallery photo (JPEG) — when set, shown instead of `systemImage`.
    var iconImageData: Data?
    /// Stored as Int for SwiftData (RGB hex).
    var tintHex: Int
    var isBuiltIn: Bool
    var sortOrder: Int
    /// Comma-separated keywords for voice / OCR matching.
    var keywordsCSV: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        nameAr: String,
        nameEn: String = "",
        systemImage: String = "tag.fill",
        iconImageData: Data? = nil,
        tintHex: Int = 0x0A5C5A,
        isBuiltIn: Bool = false,
        sortOrder: Int = 100,
        keywordsCSV: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.nameAr = nameAr
        self.nameEn = nameEn
        self.systemImage = systemImage
        self.iconImageData = iconImageData
        self.tintHex = tintHex
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
        self.keywordsCSV = keywordsCSV
        self.createdAt = createdAt
    }

    var hasCustomIcon: Bool { iconImageData != nil }

    var labelAr: String { nameAr }

    var tint: Color { Color(hex: UInt32(tintHex & 0xFFFFFF)) }

    var keywords: [String] {
        keywordsCSV
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static let fallbackId = "other"

    static func seedDefaults(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<CategoryItem>())) ?? []
        if existing.isEmpty {
            for seed in BuiltInCategory.allCases {
                context.insert(seed.makeItem())
            }
            try? context.save()
            return
        }
        // Keep built-in keyword lists fresh (voice / OCR auto-categorize).
        for seed in BuiltInCategory.allCases {
            guard let item = existing.first(where: { $0.id == seed.rawValue && $0.isBuiltIn }) else {
                continue
            }
            item.keywordsCSV = seed.keywordsCSV
            item.nameAr = seed.nameAr
            item.nameEn = seed.nameEn
            item.systemImage = seed.systemImage
            item.tintHex = seed.tintHex
            item.sortOrder = seed.sortOrder
        }
        try? context.save()
    }

    static func resolve(id: String?, in categories: [CategoryItem]) -> CategoryItem? {
        guard let id else { return nil }
        if let match = categories.first(where: { $0.id == id }) { return match }
        return categories.first(where: { $0.id == fallbackId })
    }
}

/// Built-in seeds (also used as stable ids for demo data / migration).
enum BuiltInCategory: String, CaseIterable {
    case food
    case transport
    case bills
    case entertainment
    case shopping
    case health
    case other

    var nameAr: String {
        switch self {
        case .food: return "أكل"
        case .transport: return "مواصلات"
        case .bills: return "فواتير"
        case .entertainment: return "ترفيه"
        case .shopping: return "تسوق"
        case .health: return "صحة"
        case .other: return "أخرى"
        }
    }

    var nameEn: String {
        switch self {
        case .food: return "Food"
        case .transport: return "Transport"
        case .bills: return "Bills"
        case .entertainment: return "Fun"
        case .shopping: return "Shopping"
        case .health: return "Health"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .bills: return "bolt.fill"
        case .entertainment: return "film.fill"
        case .shopping: return "bag.fill"
        case .health: return "cross.case.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var tintHex: Int {
        switch self {
        case .food: return 0x0F766E
        case .transport: return 0x0369A1
        case .bills: return 0xB45309
        case .entertainment: return 0xBE123C
        case .shopping: return 0x0E7490
        case .health: return 0x059669
        case .other: return 0x64748B
        }
    }

    var keywordsCSV: String {
        switch self {
        case .food:
            return "أكل وشرب,أكل,اكل,غدا,غداء,فطار,فطور,عشا,عشاء,قهوة,كافية,كافيه,مطعم,كشري,ماكدونالدز,food,lunch,dinner,breakfast,coffee,restaurant"
        case .transport:
            return "مواصلات,تاكسي,أوبر,اوبر,أوبير,اوبير,كريم,careem,indrive,بنزين,مترو,ميكروباص,أتوبيس,اتوبيس,uber,taxi,transport,fuel,bus,metro"
        case .bills:
            return "فاتورة نت,فاتورة,فواتير,كهربا,كهرباء,مياه,غاز,نت,إنترنت,انترنت,bill,electricity,internet,utilities"
        case .entertainment:
            return "ترفيه,سينما,فيلم,لعبة,نتفلكس,netflix,spotify,cinema,movie,fun,entertainment"
        case .shopping:
            return "تسوق,شراء,ملابس,سوق,مول,كارفور,سعودي,shopping,clothes,mall,grocery"
        case .health:
            return "صحة,دكتور,صيدلية,دواء,مستشفى,عيادة,pharmacy,doctor,medicine,health,clinic"
        case .other:
            return "أخرى,اخرى,other,misc"
        }
    }

    var sortOrder: Int {
        switch self {
        case .food: return 0
        case .transport: return 1
        case .bills: return 2
        case .entertainment: return 3
        case .shopping: return 4
        case .health: return 5
        case .other: return 6
        }
    }

    func makeItem() -> CategoryItem {
        CategoryItem(
            id: rawValue,
            nameAr: nameAr,
            nameEn: nameEn,
            systemImage: systemImage,
            tintHex: tintHex,
            isBuiltIn: true,
            sortOrder: sortOrder,
            keywordsCSV: keywordsCSV
        )
    }
}

/// Palette for new custom categories.
enum CategoryPalette {
    static let presets: [(hex: Int, image: String)] = [
        (0x0A5C5A, "tag.fill"),
        (0x7C3AED, "sparkles"),
        (0xDB2777, "heart.fill"),
        (0xEA580C, "flame.fill"),
        (0x2563EB, "airplane"),
        (0x16A34A, "leaf.fill"),
        (0xCA8A04, "gift.fill"),
        (0x475569, "folder.fill")
    ]
}

/// SF Symbol or gallery photo inside a tinted circle.
struct CategoryIconView: View {
    let systemImage: String
    var iconImageData: Data? = nil
    var tint: Color = BrandTheme.deepTeal
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.16))
                .frame(width: size, height: size)

            if let iconImageData,
               let uiImage = UIImage(data: iconImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
    }

    init(category: CategoryItem?, size: CGFloat = 48) {
        self.systemImage = category?.systemImage ?? "tag.fill"
        self.iconImageData = category?.iconImageData
        self.tint = category?.tint ?? BrandTheme.muted
        self.size = size
    }

    init(systemImage: String, iconImageData: Data? = nil, tint: Color, size: CGFloat = 48) {
        self.systemImage = systemImage
        self.iconImageData = iconImageData
        self.tint = tint
        self.size = size
    }
}
