import SwiftUI

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case food
    case transport
    case bills
    case entertainment
    case shopping
    case health
    case other

    var id: String { rawValue }

    var labelAr: String {
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

    var labelEn: String {
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

    var tint: Color {
        switch self {
        case .food: return Color(hex: 0x0F766E)
        case .transport: return Color(hex: 0x0369A1)
        case .bills: return Color(hex: 0xB45309)
        case .entertainment: return Color(hex: 0xBE123C)
        case .shopping: return Color(hex: 0x0E7490)
        case .health: return Color(hex: 0x059669)
        case .other: return Color(hex: 0x64748B)
        }
    }
}

enum ExpenseSource: String, Codable {
    case manual
    case voice
    case receipt

    var labelAr: String {
        switch self {
        case .manual: return "يدوي"
        case .voice: return "صوت"
        case .receipt: return "فاتورة"
        }
    }
}
